import Foundation
import UIKit

// MARK: - API Error Types

enum TravelCardAPIError: Error, LocalizedError {
    case invalidImageData
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case decodingError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not found"
        case .serverError:
            return "Server error"
        case .decodingError:
            return "Failed to decode response"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

// MARK: - TravelCardAPIService

class TravelCardAPIService {
    static let shared = TravelCardAPIService()
    
    private let baseURL = Config.apiBaseURL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Authentication Headers
    
    private func getAuthHeaders() async -> [String: String] {
        var headers: [String: String] = [:]
        
        // Try to get JWT token first
        if let token = await AuthService.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        } else {
            // Fall back to device ID
            let deviceID = DeviceIDService.shared.deviceID
            headers["Device-ID"] = deviceID
        }
        
        return headers
    }
    
    // MARK: - Travel Cards (Real Implementation)
    
    func createCard(image: UIImage, destinationName: String? = nil, thought: String? = nil, location: String? = nil, coordinates: String? = nil, category: String? = nil) async throws -> CreateCardResponse {
        guard let imageData = image.jpegData(compressionQuality: Config.imageCompressionQuality) else {
            throw TravelCardAPIError.invalidImageData
        }
        
        let url = URL(string: "\(baseURL)/cards/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set up multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Build multipart form data
        var body = Data()
        
        // Add image (required)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add destination_name if provided
        if let destinationName = destinationName, !destinationName.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"destination_name\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(destinationName)\r\n".data(using: .utf8)!)
        }
        
        // Add thought if provided
        if let thought = thought, !thought.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"thought\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(thought)\r\n".data(using: .utf8)!)
        }
        
        // Add location if provided
        if let location = location, !location.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"location\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(location)\r\n".data(using: .utf8)!)
        }
        
        // Add category if provided
        if let category = category, !category.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(category)\r\n".data(using: .utf8)!)
        }
        
        // Add coordinates if provided
        if let coordinates = coordinates, !coordinates.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"coordinates\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(coordinates)\r\n".data(using: .utf8)!)
        }
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        // Debug: Log the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TravelCardAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                // Try to decode as CreateCardResponse first
                do {
                    let createCardResponse = try decoder.decode(CreateCardResponse.self, from: data)
                    return createCardResponse
                } catch {
                    print("Failed to decode as CreateCardResponse: \(error)")
                    
                    // Fallback: try to decode as generic JSON to see what we got
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Raw JSON response: \(json)")
                        
                        // Create a minimal response with what we can extract
                        return CreateCardResponse(
                            destination_name: json["destination_name"] as? String,
                            image: json["image"] as? String,
                            s3_url: json["s3_url"] as? String,
                            thought: json["thought"] as? String,
                            location: json["location"] as? String,
                            coordinates: json["coordinates"] as? String,
                            category: json["category"] as? String,
                            device_id: json["device_id"] as? String
                        )
                    }
                    
                    throw TravelCardAPIError.decodingError
                }
            } catch {
                print("Decoding error: \(error)")
                throw TravelCardAPIError.decodingError
            }
        case 400:
            throw TravelCardAPIError.badRequest
        case 401:
            throw TravelCardAPIError.unauthorized
        case 403:
            throw TravelCardAPIError.forbidden
        case 500...599:
            throw TravelCardAPIError.serverError
        default:
            throw TravelCardAPIError.unknownError
        }
    }
    
    func getCards(category: String? = nil, location: String? = nil, search: String? = nil, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResponse<TravelCard> {
        var urlComponents = URLComponents(string: "\(baseURL)/discovery/")!
        
        // Add query parameters based on backend documentation
        var queryItems: [URLQueryItem] = []
        if let category = category, category != "all" {
            queryItems.append(URLQueryItem(name: "ca", value: category))
        }
        if let location = location {
            queryItems.append(URLQueryItem(name: "lc", value: location))
        }
        if let search = search {
            queryItems.append(URLQueryItem(name: "se", value: search))
        }
        queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        queryItems.append(URLQueryItem(name: "page_size", value: "\(pageSize)"))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw TravelCardAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        // Debug: Log the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("GetCards API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TravelCardAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                // Don't use keyDecodingStrategy since API uses snake_case and our model matches
                print("🔍 Attempting to decode without keyDecodingStrategy (keeping snake_case)")
                
                // Try to decode the raw JSON first to see what we're working with
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("🔍 Raw JSON structure: \(json.keys)")
                    if let results = json["results"] as? [[String: Any]], let firstResult = results.first {
                        print("🔍 First result keys: \(firstResult.keys)")
                    }
                }
                
                let paginatedResponse = try decoder.decode(PaginatedResponse<TravelCard>.self, from: data)
                return paginatedResponse
            } catch {
                print("❌ Failed to decode PaginatedResponse: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                throw TravelCardAPIError.decodingError
            }
        case 400:
            throw TravelCardAPIError.badRequest
        case 401:
            throw TravelCardAPIError.unauthorized
        case 403:
            throw TravelCardAPIError.forbidden
        case 500...599:
            throw TravelCardAPIError.serverError
        default:
            throw TravelCardAPIError.unknownError
        }
    }
    
    func getMyCards() async throws -> [TravelCard] {
        let url = URL(string: "\(baseURL)/cards/my_cards/")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        let authHeaders = await getAuthHeaders()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        // Debug: Log the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("GetMyCards API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TravelCardAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let cards = try decoder.decode([TravelCard].self, from: data)
                return cards
            } catch {
                print("Failed to decode MyCards response: \(error)")
                throw TravelCardAPIError.decodingError
            }
        case 400:
            throw TravelCardAPIError.badRequest
        case 401:
            throw TravelCardAPIError.unauthorized
        case 403:
            throw TravelCardAPIError.forbidden
        case 500...599:
            throw TravelCardAPIError.serverError
        default:
            throw TravelCardAPIError.unknownError
        }
    }
    
    func getCard(id: Int) async throws -> TravelCard {
        // Mock implementation for now
        return TravelCard(
            id: id,
            destination_name: "Mock Destination",
            image: "mock_url",
            is_valid_destination: true,
            thought: "Mock thought",
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: nil,
            like_count: 0,
            is_liked: false,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: "Mock",
            owner_destination_name: "Mock",
            rarity: "common",
            collection_tags: [],
            category: "Activities",
            isVerified: false,
            s3_url: nil,
            location: nil,
            coordinates: nil,
            admin_review_status: nil,
            admin_reviewer_id: nil,
            admin_reviewed_at: nil,
            admin_notes: nil,
            check_in_count: nil,
            comment_count: nil,
            is_liked_by_user: nil,
            is_checked_in_by_user: nil,
            moods: nil,
            user: nil
        )
    }
    
    func updateCard(id: Int, destinationName: String, thought: String, location: String, coordinates: String?, category: String) async throws -> TravelCard {
        // Mock implementation for now
        return try await getCard(id: id)
    }
    
    func deleteCard(id: Int) async throws {
        // Mock implementation for now
        print("Mock delete card: \(id)")
    }
    
    // MARK: - Check-ins (Mock Implementation)
    
    func checkIn(cardId: Int, photo: UIImage?, caption: String?, coordinates: String?) async throws -> CheckInResponse {
        // Mock implementation for now
        return CheckInResponse(
            id: Int.random(in: 1000...9999),
            photo: nil,
            s3_url: nil,
            caption: caption,
            coordinates: coordinates,
            user: UserResponse(id: 1, username: "user", first_name: "John", last_name: "Doe", email: "john@example.com"),
            created_at: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    func getCheckIns(cardId: Int) async throws -> [CheckInResponse] {
        // Mock implementation for now
        return []
    }
    
    func deleteCheckIn(id: Int) async throws {
        // Mock implementation for now
        print("Mock delete check-in: \(id)")
    }
    
    // MARK: - Social Features (Mock Implementation)
    
    func toggleLike(cardId: Int) async throws -> (liked: Bool, likeCount: Int) {
        // Mock implementation for now
        return (false, 0)
    }
    
    func addComment(cardId: Int, content: String, parentId: Int? = nil) async throws -> CommentResponse {
        // Mock implementation for now
        return CommentResponse(
            id: Int.random(in: 1000...9999),
            content: content,
            user: UserResponse(id: 1, username: "user", first_name: "John", last_name: "Doe", email: "john@example.com"),
            parent: parentId,
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date()),
            like_count: 0,
            reply_count: 0,
            is_liked_by_user: false
        )
    }
    
    func getComments(cardId: Int) async throws -> [CommentResponse] {
        // Mock implementation for now
        return []
    }
    
    func deleteComment(cardId: Int, commentId: Int) async throws {
        // Mock implementation for now
        print("Mock delete comment: \(commentId)")
    }
    
    // MARK: - Collections (Mock Implementation)
    
    func createCollection(name: String, description: String?, isPublic: Bool, coverImage: UIImage? = nil) async throws -> CollectionResponse {
        // Mock implementation for now
        return CollectionResponse(
            id: Int.random(in: 1000...9999),
            name: name,
            description: description,
            is_public: isPublic,
            cover_image: nil,
            user: UserResponse(id: 1, username: "user", first_name: "John", last_name: "Doe", email: "john@example.com"),
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date()),
            card_count: 0
        )
    }
    
    func getCollections() async throws -> [CollectionResponse] {
        // Mock implementation for now
        return []
    }
    
    func getCollection(id: Int) async throws -> CollectionDetailResponse {
        // Mock implementation for now
        return CollectionDetailResponse(
            id: id,
            name: "Mock Collection",
            description: "Mock description",
            is_public: true,
            cover_image: nil,
            user: UserResponse(id: 1, username: "user", first_name: "John", last_name: "Doe", email: "john@example.com"),
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date()),
            card_count: 0,
            cards: []
        )
    }
    
    func addCardToCollection(collectionId: Int, cardId: Int) async throws {
        // Mock implementation for now
        print("Mock add card \(cardId) to collection \(collectionId)")
    }
    
    // MARK: - Travel Moods (Mock Implementation)
    
    func getTravelMoods() async throws -> [TravelMoodResponse] {
        // Mock implementation for now
        return []
    }
    
    // MARK: - Admin Review System (Mock Implementation)
    
    func getCardsForReview(status: String = "pending", page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResponse<TravelCard> {
        // Mock implementation for now
        return PaginatedResponse(
            results: [],
            count: 0,
            next: false,
            previous: false
        )
    }
    
    func reviewCard(cardId: Int, action: String, notes: String?) async throws {
        // Mock implementation for now
        print("Mock review card \(cardId): \(action)")
    }
    
    func getAdminStats() async throws -> AdminStatsResponse {
        // Mock implementation for now
        return AdminStatsResponse(
            total_cards: 0,
            pending_cards: 0,
            approved_cards: 0,
            rejected_cards: 0,
            cards_today: 0,
            average_review_time_hours: 0.0
        )
    }
}
