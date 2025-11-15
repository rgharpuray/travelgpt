import SwiftUI

@main
struct TravelGPTApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var commentStore = CommentStore()
    
    init() {
        // Ensure device ID is created on first launch
        if KeychainManager.shared.getDeviceID() == nil {
            let deviceID = UUID().uuidString
            KeychainManager.shared.saveDeviceID(deviceID)
        }
        
        // Initialize services
        print("🚀 TravelGPT App initializing...")
    }
    
    var body: some Scene {
        WindowGroup {
            // Toki 2.0 - Lightweight Travel Logger
            TokiHomeView()
                .onAppear {
                    // Request location permissions
                    TokiLocationService.shared.requestAuthorization()
                }
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }
    
    private func initializeApp() async {
        print("🔧 Initializing app services...")
        
        // 1. Ensure device ID exists
        if KeychainManager.shared.getDeviceID() == nil {
            let deviceID = UUID().uuidString
            KeychainManager.shared.saveDeviceID(deviceID)
            print("📱 Created new device ID: \(deviceID)")
        }
        
        // 2. Load stored authentication session first
        print("🔐 Loading stored authentication session...")
        // AuthService.shared.loadStoredSession() is called in init, but let's ensure it's loaded
        
        // 3. Load profile FIRST (this works for both authenticated and guest users)
        // This should happen before token refresh to ensure we have a working state
        print("👤 Loading user profile...")
        await profileStore.fetchProfile()
        
        // 4. Refresh token if needed (but don't fail if it doesn't work)
        do {
            print("🔄 Checking token status...")
            try await AuthService.shared.refreshTokenIfNeeded()
            print("✅ Token refresh completed")
        } catch {
            print("⚠️ Token refresh failed, but continuing with guest mode: \(error)")
            // Don't fail the app initialization if token refresh fails
            // The app should work in guest mode
        }
        
        // 5. Initialize subscription service with premium status verification
        print("💎 Initializing subscription service...")
        await subscriptionService.forceReloadProducts()
        
        // 6. Start periodic premium status verification
        startPeriodicPremiumVerification()
        
        print("✅ App initialization completed")
    }
    
    private func startPeriodicPremiumVerification() {
        // Check premium status every 6 hours (21600 seconds)
        Timer.scheduledTimer(withTimeInterval: 21600, repeats: true) { _ in
            Task {
                print("🔄 Periodic premium status verification...")
                await subscriptionService.checkExistingPremiumStatus()
            }
        }
        print("⏰ Periodic premium status verification started (every 6 hours)")
    }
    
    private func handleDeepLink(url: URL) {
        print("🔗 Handling deep link: \(url)")
        
        // Handle password reset deep links
        if url.host == "password-reset" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            if let token = components?.queryItems?.first(where: { $0.name == "token" })?.value {
                print("🔑 Password reset token received: \(token)")
                // Navigate to password reset confirm
                NotificationCenter.default.post(
                    name: .passwordResetTokenReceived,
                    object: nil,
                    userInfo: ["token": token]
                )
            }
        }
    }
}

extension Notification.Name {
    static let passwordResetTokenReceived = Notification.Name("passwordResetTokenReceived")
} 