import Foundation
import Security

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var authState: AuthState = .notAuthenticated
    @Published var currentUser: User?
    
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let userDataKey = "user_data"
    
    private init() {
        loadStoredSession()
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws {
        authState = .authenticating
        
        let loginRequest = LoginRequest(email: email, password: password)
        
        guard let url = URL(string: "\(BackendService.baseURL)/auth/login/") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        // Debug logging
        print("=== LOGIN REQUEST DEBUG ===")
        print("URL: \(url.absoluteString)")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        }
        print("=========================")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug logging for response
            print("=== LOGIN RESPONSE DEBUG ===")
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            }
            print("==========================")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 401 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("401 Unauthorized Details: \(responseString)")
                }
                throw AuthError.invalidCredentials
            } else if httpResponse.statusCode != 200 {
                throw AuthError.serverError
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store tokens and user data
            try storeTokens(accessToken: authResponse.access_token, refreshToken: authResponse.refresh_token)
            try storeUserData(authResponse.user)
            
            currentUser = authResponse.user
            authState = .authenticated(authResponse.user)
            
            // Sync premium status with subscription service
            await syncPremiumStatus()
            
        } catch {
            print("Login error: \(error)")
            authState = .error(error.localizedDescription)
            throw error
        }
    }
    
    func register(email: String, password: String, petName: String? = nil) async throws {
        authState = .authenticating
        
        let registerRequest = RegisterRequest(email: email, password: password, destination_name: petName)
        
        guard let url = URL(string: "\(BackendService.baseURL)/auth/register/") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(registerRequest)
        
        // Debug logging
        print("=== REGISTRATION REQUEST DEBUG ===")
        print("URL: \(url.absoluteString)")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        }
        print("================================")
        
        // Check if user has premium status locally before registration
        let subscriptionService = SubscriptionService.shared
        let hasLocalPremium = subscriptionService.isPremium
        let deviceID = DeviceIDService.shared.getOrCreateDeviceID()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Debug logging for response
            print("=== REGISTRATION RESPONSE DEBUG ===")
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Response Headers: \(httpResponse.allHeaderFields)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            }
            print("================================")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 400 {
                // Try to parse error message
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["error"] as? String {
                    print("400 Error Message: \(errorMessage)")
                    if errorMessage.contains("email") {
                        throw AuthError.emailAlreadyExists
                    } else if errorMessage.contains("password") {
                        throw AuthError.weakPassword
                    }
                }
                throw AuthError.serverError
            } else if httpResponse.statusCode != 201 {
                print("Unexpected status code: \(httpResponse.statusCode)")
                throw AuthError.serverError
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store tokens and user data
            try storeTokens(accessToken: authResponse.access_token, refreshToken: authResponse.refresh_token)
            try storeUserData(authResponse.user)
            
            currentUser = authResponse.user
            authState = .authenticated(authResponse.user)
            
            // Handle premium migration if user had local premium status
            if hasLocalPremium {
                await migratePremiumStatus(deviceID: deviceID)
            }
            
            // Sync premium status with subscription service
            await syncPremiumStatus()
            
        } catch {
            print("Registration error: \(error)")
            authState = .error(error.localizedDescription)
            throw error
        }
    }
    
    func logout() async {
        // Call logout endpoint if we have a refresh token
        if let refreshToken = getRefreshToken() {
            do {
                let logoutRequest = LogoutRequest(refresh_token: refreshToken)
                
                guard let url = URL(string: "\(BackendService.baseURL)/auth/logout/") else {
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(logoutRequest)
                
                // Don't wait for response, just clear local data
                _ = try await URLSession.shared.data(for: request)
            } catch {
                // Ignore logout errors, just clear local data
                print("Logout error: \(error)")
            }
        }
        
        // Clear local data
        clearStoredSession()
        currentUser = nil
        authState = .notAuthenticated
    }
    
    func refreshToken() async throws {
        guard let refreshToken = getRefreshToken() else {
            throw AuthError.tokenExpired
        }
        
        let refreshRequest = RefreshTokenRequest(refresh_token: refreshToken)
        
        guard let url = URL(string: "\(BackendService.baseURL)/auth/refresh/") else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(refreshRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }
            
            if httpResponse.statusCode == 401 {
                throw AuthError.tokenExpired
            } else if httpResponse.statusCode != 200 {
                throw AuthError.serverError
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store new tokens
            try storeTokens(accessToken: authResponse.access_token, refreshToken: authResponse.refresh_token)
            
        } catch {
            // If refresh fails, clear session
            clearStoredSession()
            currentUser = nil
            authState = .notAuthenticated
            throw error
        }
    }
    
    // MARK: - Premium Status Sync
    
    private func syncPremiumStatus() async {
        // Use the new premium status verification flow
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.checkExistingPremiumStatus()
        
        // Update user's premium status if it differs from subscription status
        if let user = currentUser, user.is_premium != subscriptionService.isPremium {
            do {
                try await BackendService.shared.updatePremiumStatus(isPremium: subscriptionService.isPremium)
                
                // Update local user data
                var updatedUser = user
                // Note: We need to update the user's premium status in the backend response
                // For now, we'll rely on the subscription service status
                currentUser = updatedUser
                print("Successfully synced premium status with backend")
            } catch {
                print("Failed to sync premium status with backend (endpoint may not exist yet): \(error)")
                // Don't fail the sync - premium status is still valid locally
            }
        }
        
        // Handle premium status conflicts
        await handlePremiumStatusConflict()
    }
    
    private func handlePremiumStatusConflict() async {
        guard let user = currentUser else { return }
        
        let subscriptionService = SubscriptionService.shared
        let localPremium = subscriptionService.isPremium
        let backendPremium = user.is_premium
        
        // If there's a conflict between local and backend premium status
        if localPremium != backendPremium {
            print("⚠️ Premium status conflict detected:")
            print("   Local premium: \(localPremium)")
            print("   Backend premium: \(backendPremium)")
            
            // For now, prioritize local status (from StoreKit)
            // This ensures users don't lose premium access due to sync issues
            if localPremium && !backendPremium {
                print("🔄 Updating backend to match local premium status")
                do {
                    try await BackendService.shared.updatePremiumStatus(isPremium: true)
                    print("✅ Backend premium status updated")
                } catch {
                    print("❌ Failed to update backend premium status: \(error)")
                }
            } else if !localPremium && backendPremium {
                print("🔄 Updating backend to match local non-premium status")
                do {
                    try await BackendService.shared.updatePremiumStatus(isPremium: false)
                    print("✅ Backend premium status updated")
                } catch {
                    print("❌ Failed to update backend premium status: \(error)")
                }
            }
        }
    }
    
    // MARK: - Premium Migration
    
    private func migratePremiumStatus(deviceID: String) async {
        print("🔄 Attempting premium migration for device: \(deviceID)")
        
        do {
            // Try to migrate premium status to new user account
            try await BackendService.shared.migratePremiumStatus(deviceID: deviceID)
            print("✅ Premium status migrated successfully")
        } catch {
            print("⚠️ Premium migration failed: \(error)")
            // Don't fail registration - premium status is still valid locally
            // User can manually restore purchases later if needed
        }
    }
    
    // MARK: - Token Management
    
    nonisolated func getAccessToken() -> String? {
        return getKeychainValue(forKey: accessTokenKey)
    }
    
    nonisolated func getRefreshToken() -> String? {
        return getKeychainValue(forKey: refreshTokenKey)
    }
    
    private func storeTokens(accessToken: String, refreshToken: String) throws {
        try setKeychainValue(accessToken, forKey: accessTokenKey)
        try setKeychainValue(refreshToken, forKey: refreshTokenKey)
    }
    
    private func storeUserData(_ user: User) throws {
        let userData = try JSONEncoder().encode(user)
        try setKeychainData(userData, forKey: userDataKey)
    }
    
    private func loadStoredSession() {
        print("🔐 Loading stored session...")
        
        // Load user data from keychain
        if let userData = getKeychainData(forKey: userDataKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            print("✅ Found stored user session for: \(user.email)")
            currentUser = user
            authState = .authenticated(user)
        } else {
            print("ℹ️ No stored user session found, user will be in guest mode")
            currentUser = nil
            authState = .notAuthenticated
        }
        
        // Check if we have tokens
        let hasAccessToken = getAccessToken() != nil
        let hasRefreshToken = getRefreshToken() != nil
        
        print("🔑 Token status - Access: \(hasAccessToken), Refresh: \(hasRefreshToken)")
        
        if hasAccessToken && hasRefreshToken {
            print("✅ Tokens found, session appears valid")
        } else if !hasAccessToken && !hasRefreshToken {
            print("ℹ️ No tokens found, user will be in guest mode")
        } else {
            print("⚠️ Inconsistent token state, clearing session")
            clearStoredSession()
            currentUser = nil
            authState = .notAuthenticated
        }
    }
    
    private func clearStoredSession() {
        deleteKeychainValue(forKey: accessTokenKey)
        deleteKeychainValue(forKey: refreshTokenKey)
        deleteKeychainValue(forKey: userDataKey)
    }
    
    // MARK: - Keychain Operations
    
    private nonisolated func setKeychainValue(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AuthError.unknown
        }
        try setKeychainData(data, forKey: key)
    }
    
    private nonisolated func setKeychainData(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw AuthError.unknown
            }
        } else if status != errSecSuccess {
            throw AuthError.unknown
        }
    }
    
    private nonisolated func getKeychainValue(forKey key: String) -> String? {
        guard let data = getKeychainData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private nonisolated func getKeychainData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private nonisolated func deleteKeychainValue(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Utility Methods
    
    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }
    
    var isPremium: Bool {
        // Use the centralized premium status logic
        let subscriptionService = SubscriptionService.shared
        return subscriptionService.premiumStatus.isPremium
    }
    
    var premiumStatus: PremiumStatus {
        // Get the centralized premium status
        let subscriptionService = SubscriptionService.shared
        return subscriptionService.premiumStatus
    }
    
    nonisolated func getAuthHeader() -> String? {
        guard let token = getAccessToken() else { return nil }
        return "Bearer \(token)"
    }
    
    // MARK: - Token Refresh on App Load
    
    func refreshTokenIfNeeded() async throws {
        print("🔄 Checking if token refresh is needed...")
        
        // Check if we have any tokens at all
        guard let refreshToken = getRefreshToken() else {
            print("ℹ️ No refresh token found, user is in guest mode")
            return
        }
        
        // Check if access token is expired or about to expire
        if isTokenExpired() {
            print("⏰ Access token expired or about to expire, refreshing...")
            do {
                try await refreshToken
                print("✅ Token refresh completed successfully")
            } catch {
                print("❌ Token refresh failed: \(error)")
                // Clear invalid tokens and continue in guest mode
                clearStoredSession()
                currentUser = nil
                authState = .notAuthenticated
                print("🔄 Switched to guest mode due to token refresh failure")
                // Don't throw the error - let the app continue in guest mode
            }
        } else {
            print("✅ Access token is still valid, no refresh needed")
        }
    }
    
    func isTokenExpired(leewaySeconds: Int = 60) -> Bool {
        guard let token = getAccessToken() else { 
            print("ℹ️ No access token found")
            return true 
        }
        
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { 
            print("⚠️ Invalid token format")
            return true 
        }
        
        // Decode the JWT payload
        let payloadString = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let padding = String(repeating: "=", count: (4 - payloadString.count % 4) % 4)
        let paddedPayload = payloadString + padding
        
        guard let payloadData = Data(base64Encoded: paddedPayload),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            print("⚠️ Could not decode token payload")
            return true
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        let now = Date().addingTimeInterval(TimeInterval(leewaySeconds))
        
        let isExpired = expirationDate < now
        print("⏰ Token expires at: \(expirationDate), Current time: \(Date()), Expired: \(isExpired)")
        
        return isExpired
    }
} 
