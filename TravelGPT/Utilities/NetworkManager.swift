import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = BackendService.baseURL
    
    private init() {}
    
    func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15.0 // 15 second timeout to prevent infinite loading
        
        // Try to use authentication token first
        if let authHeader = AuthService.shared.getAuthHeader() {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            print("Using token authentication")
        } else {
            // Fallback to device ID authentication
            let deviceID = DeviceIDService.shared.getOrCreateDeviceID()
            request.setValue(deviceID, forHTTPHeaderField: "DeviceID")
            print("Using device ID authentication")
        }
        
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])") // Debug print
        return request
    }
    
    func createAuthenticatedRequest(url: URL, method: String) -> URLRequest? {
        guard let authHeader = AuthService.shared.getAuthHeader() else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15.0 // 15 second timeout to prevent infinite loading
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        print("Authenticated Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        return request
    }
    
    func createDeviceRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15.0 // 15 second timeout to prevent infinite loading
        let deviceID = DeviceIDService.shared.getOrCreateDeviceID()
        request.setValue(deviceID, forHTTPHeaderField: "DeviceID")
        print("Device Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        return request
    }
} 
 