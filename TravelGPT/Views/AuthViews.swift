import SwiftUI

// MARK: - Validation Views

struct ValidationIndicatorView: View {
    let validation: ValidationResult
    let showMessage: Bool
    
    var body: some View {
        if showMessage, let message = validation.message {
            HStack(spacing: 4) {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(validation.color)
                    .font(.caption)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(validation.color)
                
                Spacer()
            }
        }
    }
}

struct PasswordRequirementsView: View {
    let password: String
    
    private var validation: (isValid: Bool, requirements: [PasswordRequirement: Bool]) {
        validatePassword(password)
    }
    
    private var strength: PasswordStrength {
        calculatePasswordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Password strength indicator
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(strength.description)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strength.color)
            }
            
            // Strength bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            // Requirements list
            VStack(alignment: .leading, spacing: 6) {
                Text("Requirements:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(PasswordRequirement.allCases, id: \.self) { requirement in
                    HStack(spacing: 8) {
                        Image(systemName: requirement.icon)
                            .font(.caption)
                            .foregroundColor(validation.requirements[requirement] == true ? .green : .red)
                            .frame(width: 16)
                        
                        Text(requirement.description)
                            .font(.caption)
                            .foregroundColor(validation.requirements[requirement] == true ? .green : .red)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Custom Text Field Style

struct CleanTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Auth Entry View

struct AuthEntryView: View {
    @State private var isLogin = true

    var body: some View {
        VStack {
            // Toggle
            Picker("", selection: $isLogin) {
                Text("Sign In").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top, 40)
            .padding(.horizontal, 32)

            // Show the appropriate form
            if isLogin {
                LoginView()
            } else {
                RegisterView()
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.98, blue: 0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Login View

struct LoginView: View {
    private let authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showPasswordReset = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
        .navigationBarHidden(true)
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

// MARK: - Registration View

struct RegisterView: View {
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
        .navigationBarHidden(true)

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

// MARK: - Account Management View

struct AccountManagementView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showPremiumUpgrade = false
    
    var body: some View {
        List {
            Section(header: Text("Account Information")) {
                if let user = authService.currentUser {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                    
                    if let petName = user.destination_name {
                        HStack {
                            Text("Pet Name")
                            Spacer()
                            Text(petName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Member Since")
                        Spacer()
                        Text(formatDate(user.date_joined))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Premium Status")
                        Spacer()
                        let status = authService.premiumStatus
                        let message = status.displayMessage
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(status.isPremium ? "Premium" : "Free")
                                .foregroundColor(status.isPremium ? .green : .secondary)
                                .fontWeight(status.isPremium ? .semibold : .regular)
                            
                            Text(message.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            
            Section(header: Text("Actions")) {
                Button(action: { showLogoutAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.orange)
                        Text("Sign Out")
                            .foregroundColor(.orange)
                    }
                }
                
                Button(action: { showDeleteAccountAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
            }
            
            if let user = authService.currentUser, !user.is_premium {
                Section(header: Text("Premium Features")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "infinity", text: "Unlimited generations")
                            FeatureRow(icon: "bolt", text: "Priority processing")
                            FeatureRow(icon: "star", text: "Premium themes")
                            FeatureRow(icon: "xmark.circle", text: "Ad-free experience")
                        }
                        
                        Button(action: {
                            showPremiumUpgrade = true
                        }) {
                            Text("Upgrade for $3/month")
                                .fontWeight(.semibold)
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
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Account")
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authService.logout()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Feature Row Component

#Preview {
    AuthEntryView()
} 
