import Foundation
import SwiftUI

@MainActor
class PasswordResetViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isSuccess = false
    
    private let service = PasswordResetService()
    
    func requestPasswordReset() async {
        guard !email.isEmpty else {
            showAlert(message: "Please enter your email address")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(message: "Please enter a valid email address")
            return
        }
        
        isLoading = true
        
        do {
            let response = try await service.requestPasswordReset(email: email)
            isSuccess = true
            showAlert(message: "Password reset email sent successfully! Check your inbox for instructions.")
        } catch {
            showAlert(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

@MainActor
class PasswordResetConfirmViewModel: ObservableObject {
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isSuccess = false
    
    private let service = PasswordResetService()
    private let token: String
    
    init(token: String) {
        self.token = token
    }
    
    func confirmPasswordReset() async {
        guard !newPassword.isEmpty else {
            showAlert(message: "Please enter a new password")
            return
        }
        
        guard newPassword == confirmPassword else {
            showAlert(message: "Passwords do not match")
            return
        }
        
        guard isValidPassword(newPassword) else {
            showAlert(message: "Password must be at least 8 characters long")
            return
        }
        
        isLoading = true
        
        do {
            let response = try await service.confirmPasswordReset(token: token, newPassword: newPassword)
            isSuccess = true
            showAlert(message: "Password reset successfully! You can now sign in with your new password.")
        } catch {
            showAlert(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
}
