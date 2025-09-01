import SwiftUI

struct PasswordResetRequestView: View {
    @StateObject private var viewModel = PasswordResetViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(CleanTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 24)
                    
                    // Reset Button
                    Button(action: {
                        Task {
                            await viewModel.requestPasswordReset()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(viewModel.isLoading ? "Sending..." : "Send Reset Link")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.email.isEmpty ? Color.gray : Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                    .padding(.horizontal, 24)
                    
                    // Back to Login
                    Button("Back to Login") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Password Reset", isPresented: $viewModel.showAlert) {
            Button("OK") {
                if viewModel.isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct PasswordResetConfirmView: View {
    let token: String
    @StateObject private var viewModel: PasswordResetConfirmViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(token: String) {
        self.token = token
        self._viewModel = StateObject(wrappedValue: PasswordResetConfirmViewModel(token: token))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Set New Password")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Please enter your new password below.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Password Inputs
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            SecureField("Enter new password", text: $viewModel.newPassword)
                                .textFieldStyle(CleanTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            SecureField("Confirm new password", text: $viewModel.confirmPassword)
                                .textFieldStyle(CleanTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Reset Button
                    Button(action: {
                        Task {
                            await viewModel.confirmPasswordReset()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(viewModel.isLoading ? "Resetting..." : "Reset Password")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty ? Color.gray : Color.green)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(viewModel.isLoading || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Password Reset", isPresented: $viewModel.showAlert) {
            Button("OK") {
                if viewModel.isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    PasswordResetRequestView()
}
