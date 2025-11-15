import SwiftUI
import PhotosUI
import Foundation

// MARK: - Profile-specific Login View
struct ProfileLoginView: View {
    private let authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showPasswordReset = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    VStack(spacing: 16) {
                        Image(systemName: "pawprint.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Welcome Back!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to continue with your account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                                                            TextField("Enter your email", text: $email)
                                    .textFieldStyle(CleanTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textFieldStyle(CleanTextFieldStyle())
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(CleanTextFieldStyle())
                                        .textContentType(.password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                        
                        // Error message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Forgot Password Button
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showPasswordReset = true
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                        .underline()
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    
                    // Sign in button
                    Button(action: signIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill((email.isEmpty || password.isEmpty) ? Color.gray : Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)
                    
                    // Legal Links
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
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetRequestView()
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.login(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Profile-specific Register View
struct ProfileRegisterView: View {
    private let authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var petName = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var hasAcceptedEULA = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)
                        VStack(spacing: 16) {
                            Image(systemName: "pawprint.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                                                    Text("Join the pack and start creating hilarious dog thoughts")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(CleanTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                ValidationIndicatorView(
                                    validation: validateEmail(email),
                                    showMessage: !email.isEmpty
                                )
                            }
                            
                            // Pet name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pet Name (Optional)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("Enter your pet's name", text: $petName)
                                    .textFieldStyle(CleanTextFieldStyle())
                                    .textContentType(.name)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .textFieldStyle(CleanTextFieldStyle())
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textFieldStyle(CleanTextFieldStyle())
                                            .textContentType(.newPassword)
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 8)
                                    }
                                }
                            }
                            
                            // Password requirements view
                            if !password.isEmpty {
                                PasswordRequirementsView(password: password)
                            }
                            
                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("Confirm your password", text: $confirmPassword)
                                            .textFieldStyle(CleanTextFieldStyle())
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Confirm your password", text: $confirmPassword)
                                            .textFieldStyle(CleanTextFieldStyle())
                                            .textContentType(.newPassword)
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 8)
                                    }
                                }
                                
                                ValidationIndicatorView(
                                    validation: validatePasswordMatch(password, confirmPassword),
                                    showMessage: !confirmPassword.isEmpty
                                )
                            }
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // EULA Acceptance
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    hasAcceptedEULA.toggle()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: hasAcceptedEULA ? "checkmark.square.fill" : "square")
                                            .foregroundColor(hasAcceptedEULA ? .green : .gray)
                                            .font(.system(size: 20))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("I agree to the Terms of Service")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Text("By checking this box, you agree to our community guidelines and content policies")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                Button("Read Terms of Service", action: {
                                    if let url = URL(string: "https://argosventures.pro/barkrodeo/terms") {
                                        UIApplication.shared.open(url)
                                    }
                                })
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                                
                                Button("Privacy Policy", action: {
                                    if let url = URL(string: "https://argosventures.pro/barkrodeo/privacypolicy") {
                                        UIApplication.shared.open(url)
                                    }
                                })
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            }
                            
                            if !hasAcceptedEULA && !email.isEmpty && !password.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 14))
                                    
                                    Text("You must accept the Terms of Service to continue")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 24)
                        
                        // Sign up button
                        Button(action: signUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isFormValid ? Color.green : Color.gray)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal, 24)
                        

                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)

    }
    
    private var isFormValid: Bool {
        let emailValidation = validateEmail(email)
        let passwordValidation = validatePassword(password)
        let passwordMatchValidation = validatePasswordMatch(password, confirmPassword)
        
        return !email.isEmpty && 
        emailValidation.isValid &&
        !password.isEmpty && 
        passwordValidation.isValid &&
        passwordMatchValidation.isValid &&
        hasAcceptedEULA
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.register(email: email, password: password, petName: petName.isEmpty ? nil : petName)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ProfileView: View {
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var collectionStore = CollectionStore()
    @State private var petName: String = ""
    @State private var isEditing = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var isUploadingImage = false
    @State private var showAccountManagement = false
    @State private var showPremiumUpgrade = false
    @State private var showLogin = false
    @State private var showRegister = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    enum AuthSheet: Identifiable {
        case login, register
        var id: Int { self == .login ? 0 : 1 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 1. Profile Header (compact)
                    profileHeaderSection
                    
                    // 2. Quick Traits/Breed Chips
                    traitsBreedSection
                    
                    // 3. Collections Section
                    collectionsSection
                    
                    // 4. Wishlist Section
                    wishlistSection
                    
                    // 5. Account Section
                    accountSection
                    
                    // 6. Premium Upsell Card (only for non-premium)
                    if !authService.isPremium {
                        premiumSection
                    }
                    
                    // 7. Privacy & Safety Section
                    privacySection
                    
                    // 8. Legal Section
                    legalSection
                    
                    // 9. Help & Tutorial Section
                    helpTutorialSection
                    
                    // Debug Section (for development)
                    #if DEBUG
                    debugSection
                    #endif
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert(item: Binding<AlertItem?>(
                get: { profileStore.error.map { AlertItem(message: $0) } },
                set: { _ in profileStore.error = nil }
            )) { alert in
                Alert(title: Text("Error"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
            .sheet(item: Binding<AuthSheet?>(
                get: {
                    if showLogin { return .login }
                    if showRegister { return .register }
                    return nil
                },
                set: { sheet in
                    showLogin = sheet == .login
                    showRegister = sheet == .register
                }
            )) { sheet in
                switch sheet {
                case .login:
                    ProfileLoginView()
                case .register:
                    ProfileRegisterView()
                }
            }
            .sheet(isPresented: $showPremiumUpgrade) {
                PremiumUpgradeView()
            }
            .onChange(of: selectedImage) { item in
                Task {
                    if let item = item {
                        await uploadProfileImage(item)
                    }
                }
            }
            .onAppear {
                Task {
                    await profileStore.fetchProfile()
                    await collectionStore.fetchUserCollections()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Profile Header Section (compact)
    @ViewBuilder
    private var profileHeaderSection: some View {
                        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile Picture
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    ZStack {
                        if let profile = profileStore.profile, let imageUrl = profile.profile_image_url {
                            AsyncImageView(url: URL(string: imageUrl))
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Upload indicator
                        if isUploadingImage {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        }
                    }
                }
                .disabled(isUploadingImage)
                
                // Pet Name and Edit (inline)
                VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                        HStack {
                            TextField("Pet Name", text: $petName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            Button("Save") {
                                Task {
                                    await profileStore.updateProfile(petName: petName)
                                    isEditing = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            }
                        } else {
                            HStack {
                            Text(profileStore.profile?.destination_name ?? "Not set")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                                Spacer()
                            
                                Button("Edit") {
                                petName = profileStore.profile?.destination_name ?? ""
                                    isEditing = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            // Stats Row
            if let profile = profileStore.profile {
                HStack(spacing: 20) {
                    StatItem(value: "\(profile.cardsGeneratedNormal)", label: "Normal", icon: "camera")
                    StatItem(value: "\(profile.cardsGeneratedIntrusive)", label: "Wild", icon: "brain.head.profile")
                    StatItem(value: "\(profile.totalLikes)", label: "Likes", icon: "heart.fill")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Traits/Breed Section
    @ViewBuilder
    private var traitsBreedSection: some View {
        if let profile = profileStore.profile, (!profile.personalityCategories.isEmpty || !profile.dogBreed.isEmpty) {
            VStack(alignment: .leading, spacing: 12) {
                        HStack {
                    Text("Traits & Breed")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    
                    NavigationLink(destination: EditPersonalityView(profileStore: profileStore)) {
                        Text("Edit")
                            .font(.footnote)
                                .foregroundColor(.blue)
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60, maximum: .infinity))
                ], spacing: 8) {
                    ForEach(profile.personalityCategories, id: \.self) { category in
                        TraitChip(text: category)
                    }
                }
                
                // Breed chip gets its own row to ensure full text visibility
                if !profile.dogBreed.isEmpty {
                        HStack {
                        TraitChip(text: profile.dogBreed, isBreed: true)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Collections Section
    @ViewBuilder
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Collections")
                                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                NavigationLink(destination: CollectionsView()) {
                    Text("View All")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            
            if collectionStore.isLoading {
                ProgressView("Loading collections...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if collectionStore.userCollections.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("No Collections Yet")
                                            .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Create collections to organize your cards")
                        .font(.caption)
                                            .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    NavigationLink(destination: CollectionsView()) {
                        Text("Create Collection")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                                } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(collectionStore.userCollections.prefix(5)) { collection in
                            NavigationLink(destination: CollectionDetailView(collection: collection)) {
                                CollectionPreviewCard(collection: collection)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Wishlist Section
    @ViewBuilder
    private var wishlistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("My Wishlist")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                NavigationLink(destination: WishlistProfileView()) {
                    Text("View All")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            
            // Quick wishlist preview
            WishlistPreviewView()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Account")
                    .font(.headline)
                    .foregroundColor(.primary)
                            Spacer()
            }
            
            if authService.isAuthenticated {
                if let user = authService.currentUser {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Email")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Premium Status")
                                .foregroundColor(.secondary)
                            Spacer()
                            let status = authService.premiumStatus
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(status.isPremium ? "Premium" : "Free")
                                    .foregroundColor(status.isPremium ? .green : .secondary)
                                    .fontWeight(status.isPremium ? .semibold : .regular)
                                
                                Text(status.displayMessage.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        NavigationLink(destination: AccountManagementView()) {
                        HStack {
                                Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                                Text("Account Settings")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                            VStack(alignment: .leading, spacing: 4) {
                            Text("Not signed in")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("Back up your cards")
                                .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Button("Sign In") {
                            showLogin = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Register") {
                            showRegister = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Premium Section (banner card)
    @ViewBuilder
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Premium")
                                .font(.headline)
                                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                                    
                    Text("Unlimited generations & priority processing")
                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
            }
            
            Button(action: { showPremiumUpgrade = true }) {
                Text("Upgrade")
                                    .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Privacy Section
    @ViewBuilder
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Privacy & Safety")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
                    NavigationLink(destination: BlockedUsersView()) {
                        HStack {
                            Image(systemName: "person.fill.xmark")
                                .foregroundColor(.red)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Blocked Users")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                                
                                if let profile = profileStore.profile {
                                    Text("\(profile.blockedUsersCount) user\(profile.blockedUsersCount == 1 ? "" : "s") blocked")
                                .font(.footnote)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Manage blocked users")
                                .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Legal Section
    @ViewBuilder
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Legal")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
                    HStack(spacing: 16) {
                        Button(action: {
                            if let url = URL(string: "https://argosventures.pro/barkrodeo/terms") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                Text("Terms of Use")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: "https://argosventures.pro/barkrodeo/privacypolicy") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundColor(.blue)
                                Text("Privacy Policy")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Help & Tutorial Section
    @ViewBuilder
    private var helpTutorialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Help & Tutorial")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button(action: { hasCompletedOnboarding = false }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Onboarding")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Replay the tutorial and setup guide")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 12)
                }
                
                NavigationLink(destination: EULAView(hasAcceptedEULA: .constant(false))) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Terms of Service")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Read our terms and conditions")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Debug Section
    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Debug Info")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Auth Status: \(authService.isAuthenticated ? "Authenticated" : "Not Authenticated")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("User Premium: \(authService.currentUser?.is_premium ?? false)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Subscription Premium: \(subscriptionService.isPremium)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Products Loaded: \(subscriptionService.products.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    #endif
    
    // MARK: - Helper Functions
    private func uploadProfileImage(_ item: PhotosPickerItem) async {
        isUploadingImage = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let fileName = "profile_\(UUID().uuidString).jpg"
                await profileStore.uploadProfileImage(imageData: data, fileName: fileName)
            }
        } catch {
            print("Failed to upload profile image: \(error)")
        }
        
        isUploadingImage = false
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct TraitChip: View {
    let text: String
    let isBreed: Bool
    
    init(text: String, isBreed: Bool = false) {
        self.text = text
        self.isBreed = isBreed
    }
    
    // Get icon and color for each personality type
    private var personalityIcon: String {
        switch text {
        case "cuddle_comfort":
            return "heart.fill"
        case "food_obsessed":
            return "fork.knife"
        case "socialites_extroverts":
            return "person.2.fill"
        case "drama_sass":
            return "theatermasks.fill"
        case "oddballs_daydreamers":
            return "sparkles"
        case "chaos_crew":
            return "tornado"
        case "planners_plotters":
            return "chart.line.uptrend.xyaxis"
        case "low_energy_legends":
            return "moon.zzz.fill"
        default:
            return "pawprint.fill"
        }
    }
    
    private var personalityColor: Color {
        switch text {
        case "cuddle_comfort":
            return Color(red: 0.95, green: 0.3, blue: 0.5) // Vibrant pink
        case "food_obsessed":
            return Color(red: 1.0, green: 0.6, blue: 0.2) // Bright orange
        case "socialites_extroverts":
            return Color(red: 0.2, green: 0.7, blue: 0.9) // Electric blue
        case "drama_sass":
            return Color(red: 0.8, green: 0.2, blue: 0.8) // Magenta
        case "oddballs_daydreamers":
            return Color(red: 0.4, green: 0.8, blue: 0.4) // Lime green
        case "chaos_crew":
            return Color(red: 0.9, green: 0.3, blue: 0.2) // Fire red
        case "planners_plotters":
            return Color(red: 0.3, green: 0.5, blue: 0.9) // Royal blue
        case "low_energy_legends":
            return Color(red: 0.6, green: 0.6, blue: 0.8) // Slate blue
        default:
            return Color.blue
        }
    }
    
    var body: some View {
        if isBreed {
            // Breed chip - keep text for breed names
            Text(text)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
        } else {
            // Personality trait chip - use icon
            Image(systemName: personalityIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(personalityColor)
                )
        }
    }
}

struct CollectionPreviewCard: View {
    let collection: Collection
    @StateObject private var collectionStore = CollectionStore()
    @State private var firstCard: TravelCard?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let card = firstCard, !card.image.isEmpty {
                    AsyncImageView(url: URL(string: card.image))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if isLoading {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        )
                }
            }
            
            VStack(spacing: 2) {
                Text(collection.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("\(collection.card_count) cards")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 70)
        .task {
            await loadFirstCard()
        }
    }
    
    private func loadFirstCard() async {
        guard collection.card_count > 0 else { return }
        
        isLoading = true
        do {
            let detail = try await collectionStore.fetchUserCollectionDetail(collection.id, page: 1, pageSize: 1)
            if let firstCard = detail.cards.results.first {
                await MainActor.run {
                    self.firstCard = firstCard
                }
            }
        } catch {
            print("Failed to load first card for collection \(collection.name): \(error)")
        }
        isLoading = false
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    ProfileView()
} 
