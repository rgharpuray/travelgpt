import Foundation
import SwiftUI

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let destination_name: String?
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let user: User
}

struct User: Codable, Equatable {
    let id: Int
    let email: String
    let destination_name: String?
    let profile_image_url: String?
    let is_premium: Bool
    let date_joined: String
}

struct RefreshTokenRequest: Codable {
    let refresh_token: String
}

struct LogoutRequest: Codable {
    let refresh_token: String
}

// MARK: - Authentication State

enum AuthState: Equatable {
    case notAuthenticated
    case authenticating
    case authenticated(User)
    case error(String)
}

// MARK: - Premium Status

enum PremiumStatus {
    case testFlight
    case active(expirationDate: Date?)
    case expired
    case notSubscribed
    
    var isPremium: Bool {
        switch self {
        case .testFlight, .active:
            return true
        case .expired, .notSubscribed:
            return false
        }
    }
    
    var displayMessage: (title: String, subtitle: String) {
        switch self {
        case .testFlight:
            return (
                title: "You have access to Premium during beta testing.",
                subtitle: "No charge will be applied."
            )
        case .active(let expirationDate):
            if let expiration = expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return (
                    title: "You're subscribed to Premium.",
                    subtitle: "Renews on \(formatter.string(from: expiration))."
                )
            } else {
                return (
                    title: "You're subscribed to Premium.",
                    subtitle: "Active subscription."
                )
            }
        case .expired:
            return (
                title: "Your Premium subscription has ended.",
                subtitle: "Renew to regain access to Premium features."
            )
        case .notSubscribed:
            return (
                title: "You're not subscribed to Premium.",
                subtitle: "Subscribe now to unlock unlimited features."
            )
        }
    }
}

// MARK: - Authentication Error

enum AuthError: LocalizedError {
    case networkError
    case invalidCredentials
    case serverError
    case tokenExpired
    case emailAlreadyExists
    case weakPassword
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .serverError:
            return "Server error. Please try again later."
        case .tokenExpired:
            return "Session expired. Please sign in again."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Please choose a stronger password."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}

// MARK: - Premium Status Helper

func isTestFlightBuild() -> Bool {
    guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
    return receiptURL.lastPathComponent == "sandboxReceipt"
} 

// MARK: - Validation Models

struct ValidationResult {
    let isValid: Bool
    let message: String?
    let color: Color
    
    static let valid = ValidationResult(isValid: true, message: nil, color: .green)
    static let invalid = ValidationResult(isValid: false, message: "Invalid input", color: .red)
    
    static func custom(isValid: Bool, message: String?, color: Color = .red) -> ValidationResult {
        ValidationResult(isValid: isValid, message: message, color: color)
    }
}

enum PasswordRequirement: CaseIterable {
    case length
    case uppercase
    case lowercase
    case number
    case special
    
    var description: String {
        switch self {
        case .length:
            return "At least 8 characters"
        case .uppercase:
            return "One uppercase letter"
        case .lowercase:
            return "One lowercase letter"
        case .number:
            return "One number"
        case .special:
            return "One special character"
        }
    }
    
    var icon: String {
        switch self {
        case .length:
            return "textformat.size"
        case .uppercase:
            return "textformat.abc"
        case .lowercase:
            return "textformat.abc.dottedunderline"
        case .number:
            return "number"
        case .special:
            return "exclamationmark"
        }
    }
}

// MARK: - Validation Helpers

func validateEmail(_ email: String) -> ValidationResult {
    if email.isEmpty {
        return .invalid
    }
    
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    let isValid = emailPredicate.evaluate(with: email)
    
    return ValidationResult.custom(
        isValid: isValid,
        message: isValid ? "Valid email" : "Please enter a valid email address",
        color: isValid ? .green : .red
    )
}

func validatePassword(_ password: String) -> (isValid: Bool, requirements: [PasswordRequirement: Bool]) {
    var requirements: [PasswordRequirement: Bool] = [:]
    
    // Check length
    requirements[.length] = password.count >= 8
    
    // Check uppercase
    requirements[.uppercase] = password.contains(where: { $0.isUppercase })
    
    // Check lowercase
    requirements[.lowercase] = password.contains(where: { $0.isLowercase })
    
    // Check number
    requirements[.number] = password.contains(where: { $0.isNumber })
    
    // Check special character
    let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
    requirements[.special] = password.unicodeScalars.contains(where: { specialCharacters.contains($0) })
    
    let isValid = requirements.values.allSatisfy { $0 }
    
    return (isValid: isValid, requirements: requirements)
}

func validatePasswordMatch(_ password: String, _ confirmPassword: String) -> ValidationResult {
    if confirmPassword.isEmpty {
        return ValidationResult.custom(isValid: false, message: nil, color: .clear)
    }
    
    let isValid = password == confirmPassword
    return ValidationResult.custom(
        isValid: isValid,
        message: isValid ? "Passwords match" : "Passwords don't match",
        color: isValid ? .green : .red
    )
}

// MARK: - Password Strength

enum PasswordStrength {
    case weak, fair, good, strong
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
    
    var progress: Double {
        switch self {
        case .weak: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .strong: return 1.0
        }
    }
}

func calculatePasswordStrength(_ password: String) -> PasswordStrength {
    let validation = validatePassword(password)
    let validCount = validation.requirements.values.filter { $0 }.count
    
    switch validCount {
    case 0...1: return .weak
    case 2: return .fair
    case 3: return .good
    default: return .strong
    }
} 

// MARK: - Password Reset Models

struct PasswordResetRequest: Codable {
    let email: String
    let method: String // "email" or "sms"
    
    init(email: String, method: String = "email") {
        self.email = email
        self.method = method
    }
}

struct PasswordResetResponse: Codable {
    let message: String
    let token: String? // Only in development - remove in production
}

struct PasswordResetConfirm: Codable {
    let token: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case token
        case newPassword = "new_password"
    }
}

struct PasswordResetErrorResponse: Codable {
    let error: String
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidResponse
    case serverError(String)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .invalidURL:
            return "Invalid URL"
        }
    }
} 