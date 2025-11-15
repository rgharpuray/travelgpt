import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    func saveDeviceID(_ deviceID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "deviceID",
            kSecValueData as String: deviceID.data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getDeviceID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "deviceID",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let deviceID = String(data: data, encoding: .utf8) {
            return deviceID
        }
        return nil
    }
    
    // MARK: - OpenAI API Key Management
    
    private let openAIKeyKey = "com.travelgpt.openai.apiKey"
    
    func saveOpenAIKey(_ apiKey: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: openAIKeyKey,
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getOpenAIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: openAIKeyKey,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        }
        return nil
    }
    
    func deleteOpenAIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: openAIKeyKey
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Google Maps API Key Management
    
    private let googleMapsKeyKey = "com.travelgpt.googlemaps.apiKey"
    
    func saveGoogleMapsKey(_ apiKey: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: googleMapsKeyKey,
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getGoogleMapsKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: googleMapsKeyKey,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, let apiKey = String(data: data, encoding: .utf8) {
            return apiKey
        }
        return nil
    }
    
    func deleteGoogleMapsKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: googleMapsKeyKey
        ]
        SecItemDelete(query as CFDictionary)
    }
} 