import Foundation
import UIKit

class BackendService {
    static let shared = BackendService()
    //static let baseURL = "https://breathworkweb-c32165d585f1.herokuapp.com"
    static let baseURL = "http://localhost:8000"
    
    private init() {}
    
    func uploadImageAndGetThought(_ image: UIImage, isIntrusiveMode: Bool = false) async throws -> (thought: String, imageUrl: String) {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            print("⚠️ Token refresh failed in uploadImageAndGetThought, continuing: \(error)")
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "BackendService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let base64Image = imageData.base64EncodedString()
        
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/analyze/") else {
            throw NSError(domain: "BackendService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Final Request Headers: \(request.allHTTPHeaderFields ?? [:])") // Debug print
        
        let requestBody: [String: Any] = [
            "image": "data:image/jpeg;base64,\(base64Image)",
            "is_intrusive_mode": isIntrusiveMode
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Handle non-travel destination image error and limit errors
        if httpResponse.statusCode == 400 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                
                // Handle generation limit errors specifically
                if errorMessage.contains("Generation limit reached") || errorMessage.contains("limit reached") {
                    // Sync local counters with server state
                    await MainActor.run {
                        // If intrusive limit reached, set intrusive counter to max
                        if errorMessage.contains("intrusive") {
                            let cardStore = CardStore() // This should be passed as parameter ideally
                            print("🔄 Syncing intrusive counter to max due to server limit")
                            // We can't directly access CardStore here, but we can throw a specific error
                        }
                        // If normal limit reached, set normal counter to max  
                        else if errorMessage.contains("normal") {
                            print("🔄 Syncing normal counter to max due to server limit")
                        }
                    }
                    
                    // Extract more user-friendly message
                    let limitReason = errorJson["limit_reason"] as? String ?? errorMessage
                    throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: limitReason])
                }
                
                // Check if this might be a premium feature issue for unauthenticated users
                if errorMessage.contains("premium") || errorMessage.contains("subscription") || errorMessage.contains("upgrade") {
                    // Check if user has local premium but isn't authenticated
                    let isPremiumUnauthenticated = await MainActor.run {
                        let subscriptionService = SubscriptionService.shared
                        let authService = AuthService.shared
                        return subscriptionService.isPremium && authService.currentUser == nil
                    }
                    if isPremiumUnauthenticated {
                        throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please sign in to use your premium features. Your premium subscription requires authentication to work properly."])
                    }
                }
                throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "This image doesn't appear to contain a travel destination. Please try again with a photo of a travel destination."])
        }
        
        // Handle authentication errors specifically
        if httpResponse.statusCode == 401 {
            // Check if user has local premium but isn't authenticated
            let isPremiumUnauthenticated = await MainActor.run {
                let subscriptionService = SubscriptionService.shared
                let authService = AuthService.shared
                return subscriptionService.isPremium && authService.currentUser == nil
            }
            if isPremiumUnauthenticated {
                throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please sign in to use your premium features. Your premium subscription requires authentication to work properly."])
            }
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required. Please sign in to continue."])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "BackendService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        // Try to decode the response as a dictionary first to see its structure
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Response as Dictionary: \(json)")
        }
        
        let result = try JSONDecoder().decode(ThoughtResponse.self, from: data)
        return (result.thought, result.image_url)
    }
    
    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/analyze/") else {
            throw NSError(domain: "BackendService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "GET")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Final Request Headers: \(request.allHTTPHeaderFields ?? [:])") // Debug print
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        return (200...299).contains(httpResponse.statusCode)
    }
    
    func fetchCards(isIntrusive: Bool? = nil) async throws -> [TravelCard] {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            print("⚠️ Token refresh failed in fetchCards, continuing with potential guest access: \(error)")
        }
        
        var urlComponents = URLComponents(string: "\(Self.baseURL)/travelgpt/cards/")
        
        if let isIntrusive = isIntrusive {
            urlComponents?.queryItems = [URLQueryItem(name: "is_intrusive_mode", value: String(isIntrusive))]
            print("🔧 Added is_intrusive_mode=\(isIntrusive) to query parameters")
        } else {
            print("⚠️ isIntrusive is nil, not adding to query parameters")
        }
        
        guard let url = urlComponents?.url else {
            throw NSError(domain: "BackendService", code: 20, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Final URL: \(url.absoluteString)")
        
        // Try authenticated request first, fallback to device ID if needed
        var request: URLRequest
        let useAuth = AuthService.shared.getAuthHeader() != nil
        
        if useAuth {
            request = NetworkManager.shared.createRequest(url: url, method: "GET")
        } else {
            request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Final Request Headers: \(request.allHTTPHeaderFields ?? [:])") // Debug print
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 21, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        // Handle authentication errors with retry logic
        if httpResponse.statusCode == 401 && useAuth {
            print("🔐 Authentication error (401) - attempting token refresh and retry")
            do {
                try await AuthService.shared.refreshTokenIfNeeded()
                // Retry the request with fresh token
                var retryRequest = NetworkManager.shared.createRequest(url: url, method: "GET")
                retryRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse, (200...299).contains(retryHttpResponse.statusCode) else {
                    throw NSError(domain: "BackendService", code: 21, userInfo: [NSLocalizedDescriptionKey: "Server error after token refresh"])
                }
                
                let decoder = JSONDecoder()
                let cards = try decoder.decode([TravelCard].self, from: retryData)
                print("📦 Decoded \(cards.count) cards from retry response")
                return cards
            } catch {
                print("❌ Token refresh and retry failed: \(error)")
                // If token refresh fails, try with device ID authentication
                print("🔄 Falling back to device ID authentication...")
                return try await fetchCardsWithDeviceID(isIntrusive: isIntrusive)
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 21, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let decoder = JSONDecoder()
        let cards = try decoder.decode([TravelCard].self, from: data)
        print("📦 Decoded \(cards.count) cards from fetchCards")
        return cards
    }
    
    private func fetchCardsWithDeviceID(isIntrusive: Bool? = nil) async throws -> [TravelCard] {
        var urlComponents = URLComponents(string: "\(Self.baseURL)/travelgpt/cards/")
        
        if let isIntrusive = isIntrusive {
            urlComponents?.queryItems = [URLQueryItem(name: "is_intrusive_mode", value: String(isIntrusive))]
        }
        
        guard let url = urlComponents?.url else {
            throw NSError(domain: "BackendService", code: 20, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 21, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let decoder = JSONDecoder()
        let cards = try decoder.decode([TravelCard].self, from: data)
        print("📦 Decoded \(cards.count) cards from device ID fetchCards")
        return cards
    }
    
    func fetchFeed(page: Int = 1, pageSize: Int = 10, isIntrusive: Bool? = nil) async throws -> [TravelCard] {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            print("⚠️ Token refresh failed in fetchFeed, continuing with potential guest access: \(error)")
        }
        
        var urlComponents = URLComponents(string: "\(BackendService.baseURL)/travelgpt/feed/")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]

        if let isIntrusive = isIntrusive {
            urlComponents?.queryItems?.append(URLQueryItem(name: "is_intrusive_mode", value: String(isIntrusive)))
            print("🔧 Added is_intrusive_mode=\(isIntrusive) to query parameters")
        } else {
            print("⚠️ isIntrusive is nil, not adding to query parameters")
        }

        guard let url = urlComponents?.url else {
            throw NSError(domain: "BackendService", code: 12, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Final URL: \(url.absoluteString)")
        
        // Try authenticated request first, fallback to device ID if needed
        var request: URLRequest
        let useAuth = AuthService.shared.getAuthHeader() != nil
        
        if useAuth {
            request = NetworkManager.shared.createRequest(url: url, method: "GET")
        } else {
            request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        // Handle authentication errors with retry logic
        if httpResponse.statusCode == 401 && useAuth {
            print("🔐 Authentication error (401) - attempting token refresh and retry")
            do {
                try await AuthService.shared.refreshTokenIfNeeded()
                // Retry the request with fresh token
                var retryRequest = NetworkManager.shared.createRequest(url: url, method: "GET")
                retryRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse, (200...299).contains(retryHttpResponse.statusCode) else {
                    throw NSError(domain: "BackendService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Server error after token refresh"])
                }
                
                print("📡 Retry response status: \(retryHttpResponse.statusCode)")
                
                // Process the retry response
                if let json = try? JSONSerialization.jsonObject(with: retryData) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: results)
                    let cards = try JSONDecoder().decode([TravelCard].self, from: jsonData)
                    print("📦 Decoded \(cards.count) cards from retry paginated response")
                    return cards
                } else {
                    let cards = try JSONDecoder().decode([TravelCard].self, from: retryData)
                    print("📦 Decoded \(cards.count) cards from retry direct array response")
                    return cards
                }
            } catch {
                print("❌ Token refresh and retry failed: \(error)")
                // If token refresh fails, try with device ID authentication
                print("🔄 Falling back to device ID authentication...")
                return try await fetchFeedWithDeviceID(page: page, pageSize: pageSize, isIntrusive: isIntrusive)
            }
        }
        
        // Handle other non-success status codes
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        // First try to decode as a dictionary to check the structure
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = json["results"] as? [[String: Any]] {
            // If we have a paginated response with "results" array
            print("📦 Raw API response structure: \(json.keys)")
            if let firstCard = results.first {
                print("📦 First card fields: \(firstCard.keys)")
                print("📦 First card rarity: \(firstCard["rarity"] ?? "nil")")
                print("📦 First card collection_tags: \(firstCard["collection_tags"] ?? "nil")")
            }
            let jsonData = try JSONSerialization.data(withJSONObject: results)
            let cards = try JSONDecoder().decode([TravelCard].self, from: jsonData)
            print("📦 Decoded \(cards.count) cards from paginated response")
            return cards
        } else {
            // Try to decode directly as an array
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstCard = jsonArray.first {
                print("📦 Raw API response (direct array) - First card fields: \(firstCard.keys)")
                print("📦 First card rarity: \(firstCard["rarity"] ?? "nil")")
                print("📦 First card collection_tags: \(firstCard["collection_tags"] ?? "nil")")
            }
            let cards = try JSONDecoder().decode([TravelCard].self, from: data)
            print("📦 Decoded \(cards.count) cards from direct array response")
            return cards
        }
    }
    
    private func fetchFeedWithDeviceID(page: Int = 1, pageSize: Int = 10, isIntrusive: Bool? = nil) async throws -> [TravelCard] {
        var urlComponents = URLComponents(string: "\(BackendService.baseURL)/travelgpt/feed/")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]

        if let isIntrusive = isIntrusive {
            urlComponents?.queryItems?.append(URLQueryItem(name: "is_intrusive_mode", value: String(isIntrusive)))
        }

        guard let url = urlComponents?.url else {
            throw NSError(domain: "BackendService", code: 12, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 13, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        // First try to decode as a dictionary to check the structure
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = json["results"] as? [[String: Any]] {
            // If we have a paginated response with "results" array
            let jsonData = try JSONSerialization.data(withJSONObject: results)
            let cards = try JSONDecoder().decode([TravelCard].self, from: jsonData)
            print("📦 Decoded \(cards.count) cards from device ID paginated response")
            return cards
        } else {
            // Try to decode directly as an array
            let cards = try JSONDecoder().decode([TravelCard].self, from: data)
            print("📦 Decoded \(cards.count) cards from device ID direct array response")
            return cards
        }
    }
    
    func deleteCard(_ cardId: Int) async throws {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/") else {
            throw NSError(domain: "BackendService", code: 14, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "DELETE")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 15, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 403 {
            throw NSError(domain: "BackendService", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only delete your own travel destination cards"])
        }
        
        guard httpResponse.statusCode == 204 else {
            throw NSError(domain: "BackendService", code: 15, userInfo: [NSLocalizedDescriptionKey: "Failed to delete card"])
        }
    }
    
    func likeCard(_ cardId: Int) async throws -> (liked: Bool, likeCount: Int) {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/like/") else {
            throw NSError(domain: "BackendService", code: 16, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 17, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let result = try JSONDecoder().decode(LikeResponse.self, from: data)
        return (result.liked, result.like_count)
    }
    
    func unlikeCard(_ cardId: Int) async throws -> (liked: Bool, likeCount: Int) {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/unlike/") else {
            throw NSError(domain: "BackendService", code: 18, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 19, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let result = try JSONDecoder().decode(LikeResponse.self, from: data)
        return (result.liked, result.like_count)
    }
    
    // MARK: - Profile Methods (Support both device ID and token auth)
    
    func fetchProfile() async throws -> Profile {
        // Try authenticated request first
        if let authHeader = AuthService.shared.getAuthHeader() {
            do {
                return try await fetchProfileWithToken()
            } catch {
                print("⚠️ Token-based profile fetch failed: \(error)")
                print("🔄 Falling back to device ID authentication...")
                // Fallback to device ID authentication if token auth fails
                return try await fetchProfileWithDeviceID()
            }
        } else {
            print("ℹ️ No auth token available, using device ID authentication")
            return try await fetchProfileWithDeviceID()
        }
    }
    
    private func fetchProfileWithToken() async throws -> Profile {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/") else {
            throw NSError(domain: "BackendService", code: 30, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        guard var request = NetworkManager.shared.createAuthenticatedRequest(url: url, method: "GET") else {
            throw NSError(domain: "BackendService", code: 31, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Profile Request URL: \(url.absoluteString)")
        print("Profile Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Profile Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response type")
            throw NSError(domain: "BackendService", code: 31, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        print("Profile Response Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            // Token might be expired, try to refresh
            try await AuthService.shared.refreshToken()
            return try await fetchProfileWithToken()
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error Response: \(responseString)")
            }
            throw NSError(domain: "BackendService", code: 31, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        do {
            let profile = try JSONDecoder().decode(Profile.self, from: data)
            print("Successfully decoded profile: \(profile)")
            print("Profile image URL from response: \(profile.profile_image_url ?? "nil")")
            
            if let imageUrlString = profile.profile_image_url, let imageUrl = URL(string: imageUrlString) {
                print("Profile image URL is valid: \(imageUrl.absoluteString)")
            } else {
                print("WARNING: Profile image URL is invalid: \(profile.profile_image_url ?? "nil")")
            }
            
            return profile
        } catch {
            print("Failed to decode profile: \(error)")
            throw error
        }
    }
    
    private func fetchProfileWithDeviceID() async throws -> Profile {
        let deviceID = DeviceIDService.shared.getOrCreateDeviceID()
        print("Fetching profile for device ID: \(deviceID)")
        
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/?device_id=\(deviceID)") else {
            throw NSError(domain: "BackendService", code: 30, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Profile Request URL: \(url.absoluteString)")
        print("Profile Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Profile Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response type")
            throw NSError(domain: "BackendService", code: 31, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        print("Profile Response Status Code: \(httpResponse.statusCode)")
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Error Response: \(responseString)")
            }
            throw NSError(domain: "BackendService", code: 31, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
        }
        
        do {
            let profile = try JSONDecoder().decode(Profile.self, from: data)
            print("Successfully decoded profile: \(profile)")
            print("Profile image URL from response: \(profile.profile_image_url ?? "nil")")
            
            if let imageUrlString = profile.profile_image_url, let imageUrl = URL(string: imageUrlString) {
                print("Profile image URL is valid: \(imageUrl.absoluteString)")
            } else {
                print("WARNING: Profile image URL is invalid: \(profile.profile_image_url ?? "nil")")
            }
            
            return profile
        } catch {
            print("Failed to decode profile: \(error)")
            throw error
        }
    }
    
    func updateProfile(petName: String?) async throws -> Profile {
        // Try authenticated request first
        if let authHeader = AuthService.shared.getAuthHeader() {
            return try await updateProfileWithToken(petName: petName)
        } else {
            return try await updateProfileWithDeviceID(petName: petName)
        }
    }
    
    private func updateProfileWithToken(petName: String?) async throws -> Profile {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/update/") else {
            throw NSError(domain: "BackendService", code: 32, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        guard var request = NetworkManager.shared.createAuthenticatedRequest(url: url, method: "POST") else {
            throw NSError(domain: "BackendService", code: 33, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["destination_name": petName ?? ""]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Profile Update Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 33, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(Profile.self, from: data)
    }
    
    private func updateProfileWithDeviceID(petName: String?) async throws -> Profile {
        let deviceID = DeviceIDService.shared.getOrCreateDeviceID()
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/update/") else {
            throw NSError(domain: "BackendService", code: 32, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createDeviceRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceID, forHTTPHeaderField: "Device-ID")
        let body = ["destination_name": petName ?? ""]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Profile Update Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 33, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(Profile.self, from: data)
    }

    func uploadProfileImage(imageData: Data, fileName: String) async throws -> String {
        // Try authenticated request first
        if let authHeader = AuthService.shared.getAuthHeader() {
            return try await uploadProfileImageWithToken(imageData: imageData, fileName: fileName)
        } else {
            return try await uploadProfileImageWithDeviceID(imageData: imageData, fileName: fileName)
        }
    }
    
    private func uploadProfileImageWithToken(imageData: Data, fileName: String) async throws -> String {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/upload_image/") else {
            throw NSError(domain: "BackendService", code: 34, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        guard var request = NetworkManager.shared.createAuthenticatedRequest(url: url, method: "POST") else {
            throw NSError(domain: "BackendService", code: 35, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Profile Image Upload Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 35, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let result = try JSONDecoder().decode([String: String].self, from: data)
        guard let urlString = result["profile_image_url"] else {
            throw NSError(domain: "BackendService", code: 36, userInfo: [NSLocalizedDescriptionKey: "No profile_image_url in response"])
        }
        return urlString
    }
    
    private func uploadProfileImageWithDeviceID(imageData: Data, fileName: String) async throws -> String {
        let deviceID = DeviceIDService.shared.getOrCreateDeviceID()
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/upload_image/") else {
            throw NSError(domain: "BackendService", code: 34, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createDeviceRequest(url: url, method: "POST")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceID, forHTTPHeaderField: "Device-ID")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Profile Image Upload Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 35, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let result = try JSONDecoder().decode([String: String].self, from: data)
        guard let urlString = result["profile_image_url"] else {
            throw NSError(domain: "BackendService", code: 36, userInfo: [NSLocalizedDescriptionKey: "No profile_image_url in response"])
    }
        return urlString
    }

    func updatePremiumStatus(isPremium: Bool) async throws {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/update_premium/") else {
            throw NSError(domain: "BackendService", code: 37, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        guard var request = NetworkManager.shared.createAuthenticatedRequest(url: url, method: "POST") else {
            throw NSError(domain: "BackendService", code: 38, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["is_premium": isPremium]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 38, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        print("Premium status updated successfully: \(isPremium)")
    }
    
    func migratePremiumStatus(deviceID: String) async throws {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/profile/migrate_premium/") else {
            throw NSError(domain: "BackendService", code: 39, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        guard var request = NetworkManager.shared.createAuthenticatedRequest(url: url, method: "POST") else {
            throw NSError(domain: "BackendService", code: 40, userInfo: [NSLocalizedDescriptionKey: "No authentication token available"])
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["device_id": deviceID]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 40, userInfo: [NSLocalizedDescriptionKey: "Premium migration failed"])
        }
        
        print("Premium status migrated successfully for device: \(deviceID)")
    }
    
    // MARK: - Report Card API
    
    func reportCard(cardId: Int, reason: ReportCard.ReportReason, description: String?) async throws -> ReportResponse {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/report/") else {
            throw NSError(domain: "BackendService", code: 41, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body without card_id since it's in the URL
        let requestBody: [String: Any] = [
            "reason": reason.rawValue,
            "description": description ?? ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 42, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 400 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid report data"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(ReportResponse.self, from: data)
    }
    
    // MARK: - Comments API
    
    func fetchComments(for cardId: Int, page: Int = 1, limit: Int = 20) async throws -> CommentsResponse {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            print("⚠️ Token refresh failed in fetchComments, continuing: \(error)")
        }
        
        var urlComponents = URLComponents(string: "\(Self.baseURL)/travelgpt/cards/\(cardId)/comments/")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents?.url else {
            throw NSError(domain: "BackendService", code: 50, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Fetching comments for card \(cardId) - URL: \(url.absoluteString)")
        
        // Try authenticated request first, fallback to device ID if needed
        var request: URLRequest
        let useAuth = AuthService.shared.getAuthHeader() != nil
        
        if useAuth {
            request = NetworkManager.shared.createRequest(url: url, method: "GET")
        } else {
            request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Final Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Comments API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 51, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BackendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card not found"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        do {
            return try JSONDecoder().decode(CommentsResponse.self, from: data)
        } catch {
            print("❌ JSON Decode Error: \(error)")
            print("❌ Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            
            // Try to decode as raw JSON to see the structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                print("❌ JSON Structure: \(jsonObject)")
            }
            
            // Try to decode individual comments to see which field is wrong
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let commentsArray = jsonObject["comments"] as? [[String: Any]] {
                print("🔍 Individual comment structure:")
                for (index, comment) in commentsArray.enumerated() {
                    print("   Comment \(index): \(comment)")
                }
            }
            
            throw NSError(domain: "BackendService", code: 60, userInfo: [NSLocalizedDescriptionKey: "Invalid response format from server"])
        }
    }
    
    func createComment(for cardId: Int, content: String, parentId: String? = nil) async throws -> CommentCreateResponse {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to create comments"])
        }
        
        guard let url = URL(string: "\(Self.baseURL)/travelgpt/cards/\(cardId)/comments/") else {
            throw NSError(domain: "BackendService", code: 52, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Creating comment for card \(cardId)")
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "content": content,
            "parentId": parentId
        ].compactMapValues { $0 } // Remove nil values
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Create Comment API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 53, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 400 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid comment data"])
        }
        
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to create comments"])
        }
        
        if httpResponse.statusCode == 429 {
            throw NSError(domain: "BackendService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too many comments. Please wait before posting another comment."])
        }
        
        if httpResponse.statusCode != 201 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        do {
            return try JSONDecoder().decode(CommentCreateResponse.self, from: data)
        } catch {
            print("❌ JSON Decode Error for comment creation: \(error)")
            print("❌ Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw NSError(domain: "BackendService", code: 60, userInfo: [NSLocalizedDescriptionKey: "Invalid response format from server"])
        }
    }
    
    func toggleCommentLike(commentId: String) async throws -> CommentLikeResponse {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to like comments"])
        }
        
        guard let url = URL(string: "\(Self.baseURL)/travelgpt/comments/\(commentId)/like/") else {
            throw NSError(domain: "BackendService", code: 54, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Toggling like for comment \(commentId)")
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [:]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Toggle Like API Response: \(responseString)")
            print("Response length: \(data.count) bytes")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 55, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to like comments"])
        }
        
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BackendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Comment not found"])
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error Response Body: \(responseString)")
            }
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error (Status: \(httpResponse.statusCode))"])
        }
        
        do {
            return try JSONDecoder().decode(CommentLikeResponse.self, from: data)
        } catch {
            print("❌ JSON Decode Error for comment like toggle: \(error)")
            print("❌ Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw NSError(domain: "BackendService", code: 61, userInfo: [NSLocalizedDescriptionKey: "Invalid response format from server"])
        }
    }
    
    func deleteComment(commentId: String) async throws -> CommentDeleteResponse {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to delete comments"])
        }
        
        guard let url = URL(string: "\(Self.baseURL)/travelgpt/comments/\(commentId)/") else {
            throw NSError(domain: "BackendService", code: 56, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Deleting comment \(commentId)")
        
        let request = NetworkManager.shared.createRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Delete Comment API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 57, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to delete comments"])
        }
        
        if httpResponse.statusCode == 403 {
            throw NSError(domain: "BackendService", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only delete your own comments"])
        }
        
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BackendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Comment not found"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(CommentDeleteResponse.self, from: data)
    }
    
    func reportComment(commentId: String, reason: String) async throws -> CommentReportResponse {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to report comments"])
        }
        
        guard let url = URL(string: "\(Self.baseURL)/travelgpt/comments/\(commentId)/report/") else {
            throw NSError(domain: "BackendService", code: 62, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Reporting comment \(commentId)")
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CommentReportRequest(commentId: commentId, reason: reason)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Debug: Print the exact request being sent
        if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("🔍 Sending comment report request:")
            print("   URL: \(url)")
            print("   Method: \(request.httpMethod ?? "Unknown")")
            print("   Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("   Body: \(requestBodyString)")
            print("   Comment ID: \(commentId)")
            print("   Reason: \(reason)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Report Comment API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 63, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "BackendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required to report comments"])
        }
        
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BackendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Comment not found"])
        }
        
        if httpResponse.statusCode == 429 {
            throw NSError(domain: "BackendService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too many reports submitted. Please try again later."])
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            print("❌ HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error Response Body: \(responseString)")
                print("❌ Response Length: \(data.count) bytes")
            }
            
            // Try to parse error message from backend
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else {
                throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error (Status: \(httpResponse.statusCode))"])
            }
        }
        
        do {
            return try JSONDecoder().decode(CommentReportResponse.self, from: data)
        } catch {
            print("❌ JSON Decode Error for comment report: \(error)")
            print("❌ Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            throw NSError(domain: "BackendService", code: 64, userInfo: [NSLocalizedDescriptionKey: "Invalid response format from server"])
        }
    }
    
    func getCommentCount(for cardId: Int) async throws -> CommentCountResponse {
        // Proactively refresh token if needed before making API calls
        do {
            try await AuthService.shared.refreshTokenIfNeeded()
        } catch {
            print("⚠️ Token refresh failed in getCommentCount, continuing: \(error)")
        }
        
        guard let url = URL(string: "\(Self.baseURL)/travelgpt/cards/\(cardId)/comments/count/") else {
            throw NSError(domain: "BackendService", code: 58, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 Getting comment count for card \(cardId)")
        
        // Try authenticated request first, fallback to device ID if needed
        var request: URLRequest
        let useAuth = AuthService.shared.getAuthHeader() != nil
        
        if useAuth {
            request = NetworkManager.shared.createRequest(url: url, method: "GET")
        } else {
            request = NetworkManager.shared.createDeviceRequest(url: url, method: "GET")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw Comment Count API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 59, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BackendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card not found"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(CommentCountResponse.self, from: data)
    }
    
    // MARK: - Block User API
    
    func blockUser(cardId: Int) async throws -> BlockResponse {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/block/") else {
            throw NSError(domain: "BackendService", code: 43, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 44, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 400 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid block request"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(BlockResponse.self, from: data)
    }
    
    // MARK: - Get Blocked Users API
    
    func getBlockedUsers() async throws -> BlockedUsersResponse {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/users/blocked/") else {
            throw NSError(domain: "BackendService", code: 45, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 46, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(BlockedUsersResponse.self, from: data)
    }
    
    // MARK: - Unblock User API
    
    func unblockUser(blockedUserId: String) async throws -> BlockResponse {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/users/\(blockedUserId)/unblock/") else {
            throw NSError(domain: "BackendService", code: 47, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 48, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 400 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid unblock request"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(BlockResponse.self, from: data)
    }
    
    // MARK: - Personality & Onboarding APIs
    
    func getOnboardingOptions() async throws -> OnboardingOptions {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/onboarding/") else {
            throw NSError(domain: "BackendService", code: 49, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 50, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(OnboardingOptions.self, from: data)
    }
    
    func saveOnboardingData(personalityCategories: [String], breed: String?) async throws -> OnboardingResponse {
        print("🚀 saveOnboardingData called")
        print("📋 Personality categories: \(personalityCategories)")
        print("🐕 Breed: \(breed ?? "nil")")
        
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/onboarding/") else {
            throw NSError(domain: "BackendService", code: 51, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        print("🌐 URL: \(url)")
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OnboardingRequest(
            personalityCategories: personalityCategories,
            breed: breed
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        print("📡 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📡 Request body: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NSError(domain: "BackendService", code: 52, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        print("📡 Response headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode == 400 {
            print("❌ 400 Bad Request")
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                print("❌ Error message: \(errorMessage)")
                throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            print("❌ Generic 400 error")
            throw NSError(domain: "BackendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid onboarding data"])
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Non-200 status code: \(httpResponse.statusCode)")
            throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        print("✅ Success! Decoding response...")
        let result = try JSONDecoder().decode(OnboardingResponse.self, from: data)
        print("✅ Decoded response: \(result)")
        return result
    }
    
    // MARK: - Collection API Methods
    
    func fetchUserCollections() async throws -> [Collection] {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/collections/user/") else {
            throw NSError(domain: "BackendService", code: 60, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 61, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let result = try JSONDecoder().decode([String: [Collection]].self, from: data)
        return result["collections"] ?? []
    }
    
    func fetchSystemCollections() async throws -> [SystemCollection] {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/collections/system/") else {
            throw NSError(domain: "BackendService", code: 62, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 63, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        let result = try JSONDecoder().decode([String: [SystemCollection]].self, from: data)
        return result["collections"] ?? []
    }
    
    func createUserCollection(_ collectionRequest: CreateCollectionRequest) async throws -> Collection {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/collections/user/") else {
            throw NSError(domain: "BackendService", code: 64, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(collectionRequest)
        
        // Debug logging
        print("📡 Creating collection - URL: \(url)")
        print("📡 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📡 Request body: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response status: \(httpResponse.statusCode)")
            print("📡 Response headers: \(httpResponse.allHeaderFields)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response body: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BackendService", code: 65, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Try to parse error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else {
                throw NSError(domain: "BackendService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error (Status: \(httpResponse.statusCode))"])
            }
        }
        
        return try JSONDecoder().decode(Collection.self, from: data)
    }
    
    func updateUserCollection(_ id: Int, _ collectionRequest: UpdateCollectionRequest) async throws -> Collection {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/collections/user/\(id)/") else {
            throw NSError(domain: "BackendService", code: 66, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(collectionRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 67, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(Collection.self, from: data)
    }
    
    func deleteUserCollection(_ id: Int) async throws {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/collections/user/\(id)/") else {
            throw NSError(domain: "BackendService", code: 68, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "DELETE")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
            throw NSError(domain: "BackendService", code: 69, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
    }
    
    func fetchUserCollectionDetail(_ id: Int, page: Int = 1, pageSize: Int = 20) async throws -> CollectionDetail {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/collections/user/\(id)/?page=\(page)&page_size=\(pageSize)") else {
            throw NSError(domain: "BackendService", code: 70, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 71, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(CollectionDetail.self, from: data)
    }
    
    func addCardToCollection(cardId: Int, collectionId: Int) async throws -> CollectionResponse {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/collections/\(collectionId)/") else {
            throw NSError(domain: "BackendService", code: 72, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 73, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(CollectionResponse.self, from: data)
    }
    
    func removeCardFromCollection(cardId: Int, collectionId: Int) async throws -> CollectionResponse {
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/cards/\(cardId)/collections/\(collectionId)/") else {
            throw NSError(domain: "BackendService", code: 74, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "DELETE")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BackendService", code: 75, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        return try JSONDecoder().decode(CollectionResponse.self, from: data)
    }
    
    // MARK: - Premium Status Verification
    
    func checkExistingPremiumStatus() async throws {
        print("🔍 Checking existing premium status...")
        // 1. Check if user has premium receipt stored locally
        if let receiptData = getStoredReceiptData() {
            print("📄 Found receipt data, verifying with backend...")
            // 2. Verify with backend
            try await verifyExistingReceipt(receiptData: receiptData)
        } else {
            print("📄 No receipt data found locally")
        }
    }
    
    func verifyExistingReceipt(receiptData: String) async throws {
        print("🔐 Verifying receipt with backend...")
        guard let url = URL(string: "\(BackendService.baseURL)/travelgpt/check_existing_premium/") else {
            throw NSError(domain: "BackendService", code: 76, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = NetworkManager.shared.createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIDService.shared.getOrCreateDeviceID(), forHTTPHeaderField: "Device-ID")
        
        let body = ["receipt_data": receiptData]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 Sending receipt verification request to: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("❌ Receipt verification failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw NSError(domain: "BackendService", code: 77, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        print("✅ Receipt verification successful")
        
        // Parse response to update premium status
        if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let isPremium = responseDict["is_premium"] as? Bool {
            print("💎 Backend confirmed premium status: \(isPremium)")
            // Update SubscriptionService with the verified premium status
            await SubscriptionService.shared.updatePremiumStatusFromBackend(isPremium: isPremium)
        } else {
            print("⚠️ Could not parse premium status from backend response")
        }
    }
    
    private func getStoredReceiptData() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("📄 No App Store receipt found")
            return nil
        }
        let base64Receipt = receiptData.base64EncodedString()
        print("📄 Found App Store receipt (base64 length: \(base64Receipt.count))")
        return base64Receipt
    }
}

// Updated to match the API response format
struct ThoughtResponse: Codable {
    let thought: String
    let image_url: String
    
    enum CodingKeys: String, CodingKey {
        case thought
        case image_url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        thought = try container.decode(String.self, forKey: .thought)
        image_url = try container.decode(String.self, forKey: .image_url)
    }
}

// Add this struct at the top of the file with other response structs
struct LikeResponse: Codable {
    let liked: Bool
    let like_count: Int
}

struct ReportResponse: Codable {
    let success: Bool
    let message: String
}

struct BlockResponse: Codable {
    let success: Bool
    let message: String
}

struct BlockedUser: Codable {
    let device_id: String
    let destination_name: String
}

struct BlockedUsersResponse: Codable {
    let blocked_users: [BlockedUser]
    let count: Int
} 
