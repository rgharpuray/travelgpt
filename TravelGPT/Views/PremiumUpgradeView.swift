import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreAlert = false
    @State private var showErrorAlert = false
    @State private var showLoginSheet = false
    @State private var showRegisterSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                        
                        let status = subscriptionService.premiumStatus
                        let message = status.displayMessage
                        
                        Text(status.isPremium ? "Premium Active" : "Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if status.isPremium, let expiration = subscriptionService.subscriptionExpirationDate {
                            Text("Expires: \(expiration, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Unlock unlimited dog thoughts and premium features")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    
                    // Authentication Notice (for non-authenticated users)
                    if !authService.isAuthenticated {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Recommended: Create an Account")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Creating an account ensures your premium subscription is securely linked to your profile and can be restored across devices.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                Button("Sign In") {
                                    showLoginSheet = true
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Create Account") {
                                    showRegisterSheet = true
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // Features
                    VStack(spacing: 20) {
                        Text("Premium Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 16) {
                            PremiumFeatureRow(
                                icon: "infinity",
                                title: "Unlimited Generations",
                                description: "Create as many dog thoughts as you want"
                            )
                            PremiumFeatureRow(
                                icon: "bolt",
                                title: "Priority Processing",
                                description: "Get your thoughts faster with priority queue"
                            )
                            PremiumFeatureRow(
                                icon: "star",
                                title: "Premium Themes",
                                description: "Access exclusive themes and styles"
                            )
                            PremiumFeatureRow(
                                icon: "xmark.circle",
                                title: "Ad-Free Experience",
                                description: "Enjoy the app without any interruptions"
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Pricing
                    if let premiumProduct = subscriptionService.getPremiumProduct() {
                        VStack(spacing: 4) {
                            Text("Monthly Subscription")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(premiumProduct.displayPrice)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("per month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if subscriptionService.premiumStatus.isPremium, let expiration = subscriptionService.subscriptionExpirationDate {
                                Text("You'll still have access until \(expiration, style: .date).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                            Text("Cancel anytime")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 24)
                    } else {
                        // Fallback pricing display when product isn't loaded
                        VStack(spacing: 4) {
                            Text(Config.isDevelopmentMode ? "Development Mode" : "Monthly Subscription")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(Config.isDevelopmentMode ? "Free Testing" : "$2.99/month")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Config.isDevelopmentMode ? .green : .blue)
                            
                            if !Config.isDevelopmentMode {
                                Text("per month")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if subscriptionService.premiumStatus.isPremium, let expiration = subscriptionService.subscriptionExpirationDate {
                                Text("You'll still have access until \(expiration, style: .date).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                            Text(Config.isDevelopmentMode ? "Testing premium features" : "Cancel anytime")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Main Action Button
                    VStack(spacing: 16) {
                        if subscriptionService.premiumStatus.isPremium {
                            Button(action: {
                                // Open App Store manage subscriptions
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .font(.title2)
                                    Text("Cancel Subscription")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.gray, .red]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        } else {
                        Button(action: {
                            Task {
                                if Config.isDevelopmentMode {
                                    do {
                                        try await subscriptionService.purchaseInDevelopmentMode()
                                        dismiss()
                                    } catch {
                                        showErrorAlert = true
                                    }
                                    return
                                }
                                    if let product = subscriptionService.getPremiumProduct() {
                                        do {
                                            try await subscriptionService.purchase(product)
                                            dismiss()
                                        } catch {
                                            showErrorAlert = true
                                        }
                                    } else {
                                        await subscriptionService.forceReloadProducts()
                                        if let product = subscriptionService.getPremiumProduct() {
                                            do {
                                                try await subscriptionService.purchase(product)
                                                dismiss()
                                            } catch {
                                                showErrorAlert = true
                                            }
                                        } else {
                                        subscriptionService.errorMessage = "Unable to load subscription options. Please try again later."
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }) {
                            HStack {
                                if subscriptionService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                }
                                Text(subscriptionService.isLoading ? "Processing..." : (Config.isDevelopmentMode ? "Upgrade (Dev Mode)" : "Upgrade Now"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        }
                        // Restore Purchases Button (only if not premium)
                        if !subscriptionService.premiumStatus.isPremium {
                        Button(action: {
                            Task {
                                await subscriptionService.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(subscriptionService.isLoading)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Subscription Terms (Required by Apple)
                    VStack(spacing: 8) {
                        Text("Subscription Terms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage your subscriptions in your App Store account settings. Any unused portion of a free trial period will be forfeited when you purchase a subscription.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                    
                    // Legal Links (Required by Apple for auto-renewable subscriptions)
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Button(action: {
                                if let url = URL(string: "https://argosventures.pro/barkrodeo/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Terms of Use")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                            Button(action: {
                                if let url = URL(string: "https://argosventures.pro/barkrodeo/privacypolicy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Privacy Policy")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Debug information section - only show in debug builds
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Debug Information:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Development Mode: \(Config.isDevelopmentMode ? "Enabled" : "Disabled")")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Products loaded: \(subscriptionService.products.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Premium status: \(subscriptionService.isPremium ? "Premium" : "Not Premium")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Loading: \(subscriptionService.isLoading ? "Yes" : "No")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let error = subscriptionService.errorMessage {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        if let product = subscriptionService.getPremiumProduct() {
                            Text("Product found: \(product.id)")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("No premium product found")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        Button("Refresh Products") {
                            Task {
                                await subscriptionService.forceReloadProducts()
                                await subscriptionService.updateCustomerProductStatus()
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    #endif
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK") { }
        } message: {
            Text("No active premium subscription found. If you believe this is an error, please contact support.")
        }
        .alert("Purchase Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(subscriptionService.errorMessage ?? "An error occurred during purchase. Please try again.")
        }
        .sheet(isPresented: $showLoginSheet) {
            ProfileLoginView()
        }
        .sheet(isPresented: $showRegisterSheet) {
            ProfileRegisterView()
        }
    }
    
    // MARK: - Helper Functions
    
    private var statusColor: Color {
        switch subscriptionService.subscriptionStatus {
        case "Active":
            return .green
        case "Expires Today":
            return .orange
        case "Expired":
            return .red
        default:
            return .secondary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PremiumUpgradeView()
} 