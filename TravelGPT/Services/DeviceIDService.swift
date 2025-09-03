import Foundation
import Security

class DeviceIDService {
    static let shared = DeviceIDService()
    
    private let deviceIDKey = "com.travelgpt.deviceID"
    
    var deviceID: String {
        getOrCreateDeviceID()
    }
    
    private init() {}
    
    func getOrCreateDeviceID() -> String {
        if let existingID = getDeviceID() {
            return existingID
        }
        
        let newID = UUID().uuidString
        saveDeviceID(newID)
        return newID
    }
    
    private func getDeviceID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: deviceIDKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let deviceID = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return deviceID
    }
    
    private func saveDeviceID(_ deviceID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: deviceIDKey,
            kSecValueData as String: deviceID.data(using: .utf8)!
        ]
        
        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Error saving device ID to Keychain: \(status)")
            return
        }
    }
} 
