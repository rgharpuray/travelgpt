import Foundation

class PasswordResetService {
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = BackendService.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Request Password Reset
    func requestPasswordReset(email: String, method: String = "email") async throws -> PasswordResetResponse {
        let url = URL(string: "\(baseURL)/accounts/api/password-reset/")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = PasswordResetRequest(email: email, method: method)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📡 Password reset request to: \(url)")
        print("📡 Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(PasswordResetResponse.self, from: data)
        } else {
            let errorResponse = try JSONDecoder().decode(PasswordResetErrorResponse.self, from: data)
            throw NetworkError.serverError(errorResponse.error)
        }
    }
    
    // MARK: - Confirm Password Reset
    func confirmPasswordReset(token: String, newPassword: String) async throws -> PasswordResetResponse {
        let url = URL(string: "\(baseURL)/accounts/api/password-reset-confirm/")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = PasswordResetConfirm(token: token, newPassword: newPassword)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📡 Password reset confirm to: \(url)")
        print("📡 Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(PasswordResetResponse.self, from: data)
        } else {
            let errorResponse = try JSONDecoder().decode(PasswordResetErrorResponse.self, from: data)
            throw NetworkError.serverError(errorResponse.error)
        }
    }
}
