import Foundation
import UIKit

class WishlistAPIService: ObservableObject {
    static let shared = WishlistAPIService()
    
    private let session = URLSession.shared
    private let baseURL = Config.apiBaseURL
    
    private init() {}
    
    // MARK: - Authentication Headers
    
    private func getAuthHeaders() async -> [String: String] {
        var headers: [String: String] = [:]
        
        // Try JWT token first
        if let token = await AuthService.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // Add device ID as fallback
        headers["Device-ID"] = DeviceIDService.shared.deviceID
        
        return headers
    }
    
    // MARK: - Get User's Wishlist
    
    func getWishlist(priority: WishlistPriority? = nil) async throws -> [WishlistEntry] {
        var urlString = "\(baseURL)/wishlist/"
        
        if let priority = priority {
            urlString += "?priority=\(priority.rawValue)"
        }
        
        guard let url = URL(string: urlString) else {
            throw WishlistAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Wishlist API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishlistAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                let wishlist = try decoder.decode([WishlistEntry].self, from: data)
                return wishlist
            } catch {
                print("Failed to decode wishlist: \(error)")
                throw WishlistAPIError.decodingError
            }
        case 401:
            throw WishlistAPIError.unauthorized
        case 500...599:
            throw WishlistAPIError.serverError
        default:
            throw WishlistAPIError.unknownError
        }
    }
    
    // MARK: - Add Card to Wishlist
    
    func addToWishlist(cardId: Int, priority: WishlistPriority, notes: String? = nil) async throws -> WishlistEntry {
        guard let url = URL(string: "\(baseURL)/wishlist/") else {
            throw WishlistAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let requestBody = AddToWishlistRequest(
            card_id: cardId,
            priority: priority,
            notes: notes
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw WishlistAPIError.encodingError
        }
        
        let (data, response) = try await session.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Add to Wishlist API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishlistAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200, 201:
            do {
                let decoder = JSONDecoder()
                let wishlistEntry = try decoder.decode(WishlistEntry.self, from: data)
                return wishlistEntry
            } catch {
                print("Failed to decode wishlist entry: \(error)")
                throw WishlistAPIError.decodingError
            }
        case 400:
            throw WishlistAPIError.badRequest
        case 401:
            throw WishlistAPIError.unauthorized
        case 404:
            throw WishlistAPIError.notFound
        case 500...599:
            throw WishlistAPIError.serverError
        default:
            throw WishlistAPIError.unknownError
        }
    }
    
    // MARK: - Update Wishlist Entry
    
    func updateWishlistEntry(wishlistId: Int, priority: WishlistPriority? = nil, notes: String? = nil) async throws -> UpdateWishlistResponse {
        guard let url = URL(string: "\(baseURL)/wishlist/\(wishlistId)/") else {
            throw WishlistAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let requestBody = UpdateWishlistRequest(
            priority: priority,
            notes: notes
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw WishlistAPIError.encodingError
        }
        
        let (data, response) = try await session.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Update Wishlist API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishlistAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                let updateResponse = try decoder.decode(UpdateWishlistResponse.self, from: data)
                return updateResponse
            } catch {
                print("Failed to decode updated wishlist entry: \(error)")
                throw WishlistAPIError.decodingError
            }
        case 400:
            throw WishlistAPIError.badRequest
        case 401:
            throw WishlistAPIError.unauthorized
        case 404:
            throw WishlistAPIError.notFound
        case 500...599:
            throw WishlistAPIError.serverError
        default:
            throw WishlistAPIError.unknownError
        }
    }
    
    // MARK: - Remove Card from Wishlist
    
    func removeFromWishlist(cardId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/wishlist/") else {
            throw WishlistAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let requestBody = RemoveFromWishlistRequest(card_id: cardId)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw WishlistAPIError.encodingError
        }
        
        let (data, response) = try await session.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Remove from Wishlist API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishlistAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return // Success
        case 400:
            throw WishlistAPIError.badRequest
        case 401:
            throw WishlistAPIError.unauthorized
        case 404:
            throw WishlistAPIError.notFound
        case 500...599:
            throw WishlistAPIError.serverError
        default:
            throw WishlistAPIError.unknownError
        }
    }
    
    // MARK: - Delete Wishlist Entry by ID
    
    func deleteWishlistEntry(wishlistId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/wishlist/\(wishlistId)/") else {
            throw WishlistAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Delete Wishlist Entry API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WishlistAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return // Success
        case 401:
            throw WishlistAPIError.unauthorized
        case 404:
            throw WishlistAPIError.notFound
        case 500...599:
            throw WishlistAPIError.serverError
        default:
            throw WishlistAPIError.unknownError
        }
    }
}

// MARK: - Wishlist API Error

enum WishlistAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case encodingError
    case badRequest
    case unauthorized
    case notFound
    case serverError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized"
        case .notFound:
            return "Not found"
        case .serverError:
            return "Server error"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}
