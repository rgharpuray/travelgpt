import Foundation
import StoreKit

@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    // Product identifiers - add both monthly and yearly
    private let premiumMonthlyProductID = Config.premiumMonthlyProductID
    private let premiumYearlyProductID = "com.barkgpt.premium.yearly" // Add this if you have yearly
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isPremium = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Subscription status details
    @Published var subscriptionExpirationDate: Date?
    @Published var nextBillingDate: Date?
    @Published var subscriptionStatus: String = "Unknown"
    @Published var daysUntilExpiration: Int?
    
    // New premium status tracking
    @Published var premiumStatus: PremiumStatus = .notSubscribed
    
    private var productsLoaded = false
    private var updates: Task<Void, Error>? = nil
    
    override init() {
        super.init()
        print("SubscriptionService initialized")
        updates = observeTransactionUpdates()
        Task {
            print("Starting SubscriptionService initialization tasks")
            await loadProducts()
            await checkExistingPremiumStatus()
            print("SubscriptionService initialization tasks completed")
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Premium Status Logic
    
    func getPremiumStatus() -> PremiumStatus {
        // Check if this is a TestFlight build
        if isTestFlightBuild() {
            return .testFlight
        }
        
        // Check for active subscription
        if let expiration = subscriptionExpirationDate {
            if expiration > Date() {
                return .active(expirationDate: expiration)
            } else {
                return .expired
            }
        }
        
        // Check if user has purchased products (for device-based users)
        if !purchasedProductIDs.isEmpty {
            return .active(expirationDate: subscriptionExpirationDate)
        }
        
        return .notSubscribed
    }
    
    func updatePremiumStatus() {
        let newStatus = getPremiumStatus()
        premiumStatus = newStatus
        isPremium = newStatus.isPremium
        
        print("Premium status updated: \(newStatus)")
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        guard !productsLoaded else { 
            print("Products already loaded, skipping...")
            return 
        }
        
        // Development mode - simulate product loading
        if Config.isDevelopmentMode {
            print("Running in development mode - simulating product loading")
            productsLoaded = true
            errorMessage = nil
            print("Development mode: Premium features available for testing")
            updatePremiumStatus()
            return
        }
        
        // Create set of product identifiers
        var productIdentifiers = Set([premiumMonthlyProductID])
        // Add yearly if you have it configured
        // productIdentifiers.insert(premiumYearlyProductID)
        
        print("Loading products with IDs: \(productIdentifiers)")
        
        do {
            print("Requesting products from App Store...")
            let storeProducts = try await Product.products(for: productIdentifiers)
            
            print("Received \(storeProducts.count) products from App Store")
            for product in storeProducts {
                print("Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
            
            if storeProducts.isEmpty {
                print("WARNING: No products returned from App Store Connect")
                print("This usually means the product IDs are not configured in App Store Connect")
                print("The premium upgrade will not work until the products are properly configured")
                errorMessage = "Premium subscription not available yet. Please try again later."
            
                // Set a flag to retry later
                productsLoaded = false
            } else {
            products = storeProducts.sorted { $0.price < $1.price }
            productsLoaded = true
                errorMessage = nil
            print("Successfully loaded \(products.count) products")
            }
        } catch {
            print("Failed to load products: \(error)")
            print("Error details: \(error.localizedDescription)")
            errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
            
            // Don't mark as loaded so we can retry
            productsLoaded = false
        }
    }
    
    // Force reload products (for debugging and retry scenarios)
    func forceReloadProducts() async {
        print("Force reloading products...")
        productsLoaded = false
        products = []
        errorMessage = nil
        await loadProducts()
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil
        
        // Development mode - simulate successful purchase
        if Config.isDevelopmentMode {
            print("Development mode: Simulating successful purchase")
            await Task.sleep(1_000_000_000) // 1 second delay to simulate processing
            self.isPremium = true
            self.purchasedProductIDs.insert(premiumMonthlyProductID)
            updatePremiumStatus()
            isLoading = false
            print("Development mode: Purchase completed successfully")
            return
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check whether the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Deliver content to the user
                    await updateCustomerProductStatus()
                    await transaction.finish()
                    
                    // Update backend with premium status (with retry logic)
                    await updateBackendPremiumStatusWithRetry(isPremium: true)
                    
                case .unverified(_, let error):
                    // Transaction failed verification
                    throw error
                }
                
            case .userCancelled:
                errorMessage = "Purchase was cancelled"
                
            case .pending:
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    // Development mode purchase (no product required)
    func purchaseInDevelopmentMode() async throws {
        guard Config.isDevelopmentMode else {
            throw SubscriptionError.failedVerification
        }
        
        isLoading = true
        errorMessage = nil
        
        print("Development mode: Simulating successful purchase")
        await Task.sleep(1_000_000_000) // 1 second delay to simulate processing
        self.isPremium = true
        self.purchasedProductIDs.insert(premiumMonthlyProductID)
        
        // Simulate subscription details for testing
        let calendar = Calendar.current
        let now = Date()
        
        // For testing: set expiration to 5 days from now to trigger warning
        self.subscriptionExpirationDate = calendar.date(byAdding: .day, value: 5, to: now)
        self.nextBillingDate = self.subscriptionExpirationDate
        self.subscriptionStatus = "Active"
        self.daysUntilExpiration = 5
        
        updatePremiumStatus()
        isLoading = false
        print("Development mode: Purchase completed successfully with 5-day expiration for testing")
    }
    
    // MARK: - Subscription Status
    
    func updateCustomerProductStatus() async {
        var purchasedProductIDs = Set<String>()
        var expirationDate: Date?
        var billingDate: Date?
        var status = "Unknown"
        
        // Iterate through all of the user's purchased products
        for await result in Transaction.currentEntitlements {
            do {
                // Check whether the transaction is verified
                let transaction = try checkVerified(result)
                
                // If the transaction is verified, add the product ID to the set of purchased product IDs
                purchasedProductIDs.insert(transaction.productID)
                
                // Extract subscription details
                if transaction.productID == premiumMonthlyProductID {
                    // Get expiration date from transaction
                    if let expirationDateMs = transaction.expirationDate {
                        expirationDate = expirationDateMs
                        
                        // Calculate days until expiration
                        let calendar = Calendar.current
                        let now = Date()
                        let days = calendar.dateComponents([.day], from: now, to: expirationDateMs).day ?? 0
                        self.daysUntilExpiration = days
                        
                        // Set next billing date (same as expiration for auto-renewable subscriptions)
                        billingDate = expirationDateMs
                        
                        // Determine status
                        if days > 0 {
                            status = "Active"
                        } else if days == 0 {
                            status = "Expires Today"
                        } else {
                            status = "Expired"
                        }
                    }
                }
                
            } catch {
                // Transaction failed verification, so don't deliver content to the user
                print("Transaction failed verification: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProductIDs
        self.subscriptionExpirationDate = expirationDate
        self.nextBillingDate = billingDate
        self.subscriptionStatus = status
        
        // Update premium status based on new information
        updatePremiumStatus()
        
        print("Premium status updated: \(isPremium)")
        print("Subscription status: \(status)")
        if let expiration = expirationDate {
            print("Expiration date: \(expiration)")
        }
    }
    
    // MARK: - Transaction Updates
    
    private func observeTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't have a revocation date,
            // and are for the current user
            for await verificationResult in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(verificationResult)
                    
                    // Deliver content to the user
                    await self.updateCustomerProductStatus()
                    
                    // Always finish a transaction
                    await transaction.finish()
                    
                } catch {
                    // Transaction failed verification, so don't deliver content to the user
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Backend Integration
    
    private func updateBackendPremiumStatus(isPremium: Bool) async {
        do {
            // Update the user's premium status in the backend
            if let authHeader = AuthService.shared.getAuthHeader() {
                // For authenticated users, update via API
                do {
                    try await BackendService.shared.updatePremiumStatus(isPremium: isPremium)
                    print("Successfully updated backend premium status for authenticated user")
                } catch {
                    print("Backend premium status update failed (endpoint may not exist yet): \(error)")
                    // Don't throw error - this is expected if backend endpoint isn't implemented yet
                }
            } else {
                // For device-based users, the backend should check Apple's receipt
                // This will be handled by the backend when the user makes API calls
                print("Device-based user premium status will be verified by backend")
            }
        } catch {
            print("Failed to update backend premium status: \(error)")
            // Don't throw error - premium status is still valid locally
        }
    }
    
    // MARK: - Backend Integration with Retry Logic
    
    private func updateBackendPremiumStatusWithRetry(isPremium: Bool) async {
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                await updateBackendPremiumStatus(isPremium: isPremium)
                print("✅ Backend premium status updated successfully")
                return
            } catch {
                retryCount += 1
                print("❌ Backend update attempt \(retryCount) failed: \(error)")
                
                if retryCount < maxRetries {
                    print("🔄 Retrying in 2 seconds...")
                    await Task.sleep(2_000_000_000) // 2 second delay
                } else {
                    print("⚠️ All retry attempts failed. Premium status is still valid locally.")
                    // Don't throw error - premium status is still valid locally
                    // User can manually sync later if needed
                }
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            updatePremiumStatus()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Utility
    
    func getPremiumProduct() -> Product? {
        // Development mode - return mock product
        if Config.isDevelopmentMode {
            print("Development mode: Returning mock premium product")
            // Note: In a real implementation, you'd create a mock Product
            // For now, we'll return nil and handle it in the UI
            return nil
        }
        
        return products.first { $0.id == premiumMonthlyProductID }
    }
    
    // Development mode helper
    func createMockProduct() -> Product? {
        guard Config.isDevelopmentMode else { return nil }
        
        // Create a mock product for development testing
        // Note: This is a simplified mock - in production, you'd use real StoreKit products
        return nil // We'll handle this differently in the UI
    }
    
    // MARK: - Backend Premium Status Integration
    
    func updatePremiumStatusFromBackend(isPremium: Bool) {
        print("🔄 Updating premium status from backend: \(isPremium)")
        // Update local premium status based on backend verification
        self.isPremium = isPremium
        
        if isPremium {
            // If backend confirms premium, ensure we have a valid status
            if subscriptionExpirationDate == nil {
                // Set a default expiration date if none exists
                subscriptionExpirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                print("📅 Set default expiration date for backend-verified premium")
            }
            premiumStatus = .active(expirationDate: subscriptionExpirationDate)
        } else {
            // If backend says not premium, update accordingly
            premiumStatus = .notSubscribed
        }
        
        print("✅ Premium status updated from backend: \(isPremium)")
    }
    
    // MARK: - Premium Status Verification Flow
    
    func checkExistingPremiumStatus() async {
        print("🔍 SubscriptionService: Checking existing premium status...")
        // 1. Check if user has premium receipt stored locally
        if let receiptData = getStoredReceiptData() {
            print("📄 Found receipt data, verifying with backend...")
            // 2. Verify with backend
            do {
                try await BackendService.shared.verifyExistingReceipt(receiptData: receiptData)
            } catch {
                print("❌ Failed to verify existing receipt with backend: \(error)")
                // Fall back to local verification
                print("🔄 Falling back to local verification...")
                await updateCustomerProductStatus()
            }
        } else {
            print("📄 No receipt data found, checking local status...")
            // No receipt data, check local status
            await updateCustomerProductStatus()
        }
    }
    
    private func getStoredReceiptData() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            print("📄 No App Store receipt found in SubscriptionService")
            return nil
        }
        let base64Receipt = receiptData.base64EncodedString()
        print("📄 Found App Store receipt in SubscriptionService (base64 length: \(base64Receipt.count))")
        return base64Receipt
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
} 