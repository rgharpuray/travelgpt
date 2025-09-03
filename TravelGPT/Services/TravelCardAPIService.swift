import Foundation
import UIKit

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
            headers["X-Device-ID"] = deviceID
        }
        
        return headers
    }
    
    // MARK: - Travel Cards (Mock Implementation)
    
    func createCard(image: UIImage, destinationName: String, thought: String, location: String, coordinates: String?, category: String) async throws -> CreateCardResponse {
        // Mock implementation for now
        return CreateCardResponse(
            id: Int.random(in: 1000...9999),
            destination_name: destinationName,
            image: "mock_image",
            s3_url: "mock_s3_url",
            thought: thought,
            location: location,
            coordinates: coordinates,
            category: category,
            is_verified: false,
            admin_review_status: "pending",
            user: UserResponse(id: 1, username: "user", first_name: "John", last_name: "Doe", email: "john@example.com"),
            created_at: ISO8601DateFormatter().string(from: Date()),
            updated_at: ISO8601DateFormatter().string(from: Date()),
            like_count: 0,
            check_in_count: 0,
            comment_count: 0,
            is_liked_by_user: false,
            is_checked_in_by_user: false,
            moods: []
        )
    }
    
    func getCards(category: String? = nil, location: String? = nil, search: String? = nil, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResponse<TravelCard> {
        // Mock implementation for now
        return PaginatedResponse(
            results: [],
            count: 0,
            next: false,
            previous: false,
            total_pages: 0
        )
    }
    
    func getMyCards() async throws -> [TravelCard] {
        // Mock implementation for now
        return []
    }
    
    func getCard(id: Int) async throws -> TravelCard {
        // Mock implementation for now
        return TravelCard(
            id: id,
            destination_name: "Mock Destination",
            image_url: "mock_url",
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
            previous: false,
            total_pages: 0
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
