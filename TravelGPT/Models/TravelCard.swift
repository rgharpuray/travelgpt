import Foundation
import UIKit
import SwiftUI

struct TravelCard: Identifiable, Codable {
    let id: Int
    let destination_name: String?
    let image: String
    let thought: String?
    let created_at: String
    let updated_at: String?
    var like_count: Int
    var check_in_count: Int
    var comment_count: Int
    var is_liked_by_user: Bool
    var is_checked_in_by_user: Bool
    let category: String?
    let s3_url: String?
    let location: String?
    let coordinates: String?
    let admin_review_status: String?
    let user: UserResponse?
    let device_id: String?
    let moods: [String]
    let theme_color: String?
    
    
    // Computed properties for backward compatibility
    var is_valid_destination: Bool { true }
    var is_liked: Bool { 
        get { is_liked_by_user }
        set { is_liked_by_user = newValue }
    }
    var is_owner: Bool { false } // TODO: Implement when user system is ready
    var is_intrusive_mode: Bool { false } // TODO: Implement when intrusive mode is ready
    var device_destination_name: String? { nil }
    var owner_destination_name: String? { nil }
    var rarity: String? { nil }
    var collection_tags: [String]? { nil }
    var isVerified: Bool { admin_review_status == "approved" }
    var checkInPhotos: [CheckInPhoto] { [] }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: created_at) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return created_at
    }
    
    var rarityEnum: Rarity? {
        guard let rarityString = rarity else { return nil }
        return Rarity(rawValue: rarityString)
    }
    
    // Computed property for admin review status
    var reviewStatus: AdminReviewStatus {
        guard let status = admin_review_status else { return .unknown }
        return AdminReviewStatus(rawValue: status) ?? .unknown
    }
    
    // Computed property for theme color
    var themeColor: Color? {
        guard let colorString = theme_color else { return nil }
        return Color(hex: colorString)
    }
    
    // Custom initializer for backward compatibility with existing code
    init(id: Int, destination_name: String?, image: String, is_valid_destination: Bool, thought: String?, 
         created_at: String, updated_at: String?, like_count: Int, is_liked: Bool, is_owner: Bool?, 
         is_intrusive_mode: Bool?, device_destination_name: String?, owner_destination_name: String?, 
         rarity: String?, collection_tags: [String]?, category: String?, isVerified: Bool, 
         checkInPhotos: [CheckInPhoto] = [], s3_url: String? = nil, location: String? = nil, 
         coordinates: String? = nil, admin_review_status: String? = nil, admin_reviewer_id: Int? = nil, 
         admin_reviewed_at: String? = nil, admin_notes: String? = nil, check_in_count: Int? = nil, 
         comment_count: Int? = nil, is_liked_by_user: Bool? = nil, is_checked_in_by_user: Bool? = nil, 
         moods: [String]? = nil, user: UserResponse? = nil, device_id: String? = nil, theme_color: String? = nil) {
        self.id = id
        self.destination_name = destination_name
        self.image = image
        self.thought = thought
        self.created_at = created_at
        self.updated_at = updated_at
        self.like_count = like_count
        self.check_in_count = check_in_count ?? 0
        self.comment_count = comment_count ?? 0
        self.is_liked_by_user = is_liked_by_user ?? is_liked
        self.is_checked_in_by_user = is_checked_in_by_user ?? false
        self.category = category
        self.s3_url = s3_url
        self.location = location
        self.coordinates = coordinates
        self.admin_review_status = admin_review_status
        self.user = user
        self.device_id = device_id
        self.moods = moods ?? []
        self.theme_color = theme_color
    }
}

// MARK: - Admin Review Status

enum AdminReviewStatus: String, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .unknown: return .gray
        }
    }
}

extension CardStore {
enum FeedType {
        case all
        case myCards
    }
}

@MainActor
class CardStore: ObservableObject {
    @Published var cards: [TravelCard] = []
    @Published var dailyNormalCount: Int = 0
    @Published var dailyIntrusiveCount: Int = 0
    @Published var feedType: FeedType = .all
    @Published var isIntrusiveMode: Bool = false
    @Published var selectedMoods: [String] = []
    @Published var selectedLocation: String = "Barcelona, Spain"
    
    var filteredCards: [TravelCard] {
        cards.filter { $0.is_intrusive_mode == isIntrusiveMode }
    }
    
    // Pagination state
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreContent = true
    @Published var currentPage = 1
    @Published var error: String?
    @Published var retryCount: Int = 0
    @Published var lastRetryTime: Date?
    
    let maxDailyNormal = 3
    let maxDailyIntrusive = 1
    private let pageSize = 20
    
    private let cardsKey = "savedCards"
    private let dailyNormalKey = "dailyNormalCount"
    private let dailyIntrusiveKey = "dailyIntrusiveCount"
    private let lastResetKey = "lastResetDate"
    
    // --- Seen card tracking ---
    private let seenCardsKey = "seenCardIDs"
    @Published var seenCardIDs: Set<Int> = []
    // ---
    
    // --- FEED TASK MANAGEMENT ---
    private var currentFeedTask: Task<Void, Never>? = nil
    // ---
    
    init() {
        loadDailyCounts()
        checkAndResetDailyCount()
        loadSeenCardIDs()
    }
    
    func toggleIntrusiveMode() async {
        print("🔧 Toggling intrusive mode from \(isIntrusiveMode) to \(!isIntrusiveMode)")
        isIntrusiveMode.toggle()
        print("🔄 Starting feed refresh for intrusive mode: \(isIntrusiveMode)")
        // Clear any previous errors when switching modes
        clearError()
        await refreshFeed()
        print("✅ Feed refresh completed for intrusive mode: \(isIntrusiveMode)")
    }
    
    func refreshFeed() async {
        // Check if we should wait before retrying
        if let lastRetry = lastRetryTime, retryCount >= 5 {
            let timeSinceLastRetry = Date().timeIntervalSince(lastRetry)
            let cooldownPeriod: TimeInterval = 120.0 // 2 minutes cooldown after 5+ retries
            
            if timeSinceLastRetry < cooldownPeriod {
                print("⏳ Cooldown period active, skipping retry")
                return
            }
        }
        
        // Cancel any previous feed load
        currentFeedTask?.cancel()
        let task = Task { [weak self] in
            guard let self = self else { return }
            print("🔄 refreshFeed() called - feedType: \(feedType), isIntrusiveMode: \(isIntrusiveMode)")
            await MainActor.run {
                self.isLoading = true
                self.error = nil
                self.currentPage = 1
                self.hasMoreContent = true
            }
            
            do {
                // Use the /discovery/ endpoint for the main feed since it's working
                print("📡 Fetching cards from /discovery/ endpoint")
                let response = try await TravelCardAPIService.shared.getCards(
                    location: self.selectedLocation,
                    moods: self.selectedMoods.isEmpty ? nil : self.selectedMoods,
                    page: 1, 
                    pageSize: self.pageSize
                )
                print("📦 Received \(response.results.count) cards from API (pageSize: \(self.pageSize))")
                
                await MainActor.run {
                    self.cards = response.results
                    self.hasMoreContent = response.next ?? false
                    print("📊 Loaded - cards: \(response.results.count), hasMoreContent: \(self.hasMoreContent)")
                }
            } catch {
                if let error = error as? CancellationError {
                    print("⚠️ Feed load cancelled, not showing error to user.")
                    // Do not set error
                } else {
                    print("❌ Error in refreshFeed: \(error)")
                    
                    // Increment retry count for any error
                    await MainActor.run {
                        self.retryCount += 1
                        self.lastRetryTime = Date()
                    }
                    
                    // Provide more specific error messages based on error type
                    let errorMessage = self.getSpecificErrorMessage(for: error)
                    
                    // Only show error after multiple failed attempts and only for persistent issues
                    if self.retryCount >= 3 {
                        await MainActor.run {
                            self.error = errorMessage
                        }
                    } else {
                        print("🔄 Retry \(self.retryCount)/3 - not showing error yet")
                        // Don't show error, just let it retry silently
                    }
                }
            }
            await MainActor.run {
                self.isLoading = false
                print("✅ refreshFeed() completed")
            }
        }
        currentFeedTask = task
        await task.value
    }
    
    private func getSpecificErrorMessage(for error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        // Check for authentication errors
        if errorDescription.contains("401") || errorDescription.contains("unauthorized") || errorDescription.contains("authentication") {
            return "Authentication issue. Please try logging out and back in."
        }
        
        // Check for network errors
        if errorDescription.contains("could not connect") || 
           errorDescription.contains("timeout") ||
           errorDescription.contains("connection refused") ||
           errorDescription.contains("host unreachable") ||
           errorDescription.contains("no route to host") ||
           errorDescription.contains("network is unreachable") {
            return "Unable to connect to TravelGPT. Please check your internet connection and try again."
        }
        
        // Check for server errors
        if errorDescription.contains("500") || errorDescription.contains("server error") {
            return "Server error. Please try again later."
        }
        
        // Default error message
        return "Error could not load feed. Please try again."
    }
    
    func loadMoreContent() async {
        guard !isLoadingMore && hasMoreContent && feedType == .all else { 
            print("🔒 loadMoreContent blocked - isLoadingMore: \(isLoadingMore), hasMoreContent: \(hasMoreContent), feedType: \(feedType)")
            return 
        }
        print("📥 loadMoreContent() called - currentPage: \(currentPage), pageSize: \(pageSize)")
        isLoadingMore = true
        do {
            let nextPage = currentPage + 1
            print("📡 Fetching page \(nextPage) with pageSize \(pageSize)")
            let response = try await TravelCardAPIService.shared.getCards(
                location: selectedLocation,
                moods: selectedMoods.isEmpty ? nil : selectedMoods,
                page: nextPage, 
                pageSize: pageSize
            )
            print("📦 Received \(response.results.count) new cards from page \(nextPage)")
            
            if response.results.count < pageSize {
                print("📉 Received fewer cards than pageSize, setting hasMoreContent to false")
                hasMoreContent = false
            }
            
            if !response.results.isEmpty {
                print("✅ Adding \(response.results.count) new cards to existing \(self.cards.count) cards")
                self.cards.append(contentsOf: response.results)
                currentPage = nextPage
                print("📊 Total cards now: \(self.cards.count), currentPage: \(currentPage)")
            } else {
                print("⚠️ No new cards received, keeping current page")
            }
        } catch {
            print("❌ Error in loadMoreContent: \(error)")
            // For loadMoreContent, we just silently fail to prevent infinite loops
            // The main feed error handling will take care of showing appropriate messages
            // This prevents the "load more" from causing cascading failures
        }
        isLoadingMore = false
        print("🏁 loadMoreContent() completed")
    }
    
    func switchFeedType(to newType: FeedType) async {
        feedType = newType
        // Reset feed state
        await MainActor.run {
            self.cards = []
            self.currentPage = 1
            self.hasMoreContent = true
            self.error = nil
            self.retryCount = 0
            self.lastRetryTime = nil
        }
        await refreshFeed()
    }
    
    func clearError() {
        error = nil
        retryCount = 0
        lastRetryTime = nil
    }
    
    func addCard(_ card: TravelCard) {
        cards.insert(card, at: 0) // Add to top for user feed
        if card.is_intrusive_mode == true {
            dailyIntrusiveCount += 1
            saveDailyIntrusiveCount()
        } else {
            dailyNormalCount += 1
            saveDailyNormalCount()
        }
        saveCards()
    }
    
    func updateCard(_ card: TravelCard) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
            saveCards()
        }
    }
    
    func canAddCard(isIntrusive: Bool) -> Bool {
        if isIntrusive {
            return dailyIntrusiveCount < maxDailyIntrusive
        } else {
            return dailyNormalCount < maxDailyNormal
        }
    }
    
    private func checkAndResetDailyCount() {
        let calendar = Calendar.current
        if let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date {
            if !calendar.isDateInToday(lastReset) {
                dailyNormalCount = 0
                dailyIntrusiveCount = 0
                saveDailyNormalCount()
                saveDailyIntrusiveCount()
                UserDefaults.standard.set(Date(), forKey: lastResetKey)
            }
        } else {
            UserDefaults.standard.set(Date(), forKey: lastResetKey)
        }
    }
    
    private func saveCards() {
        if let encoded = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(encoded, forKey: cardsKey)
        }
    }
    
    private func loadCards() {
        if let data = UserDefaults.standard.data(forKey: cardsKey),
           let decoded = try? JSONDecoder().decode([TravelCard].self, from: data) {
            cards = decoded
        }
    }
    
    func saveDailyNormalCount() {
        UserDefaults.standard.set(dailyNormalCount, forKey: dailyNormalKey)
    }
    
    func saveDailyIntrusiveCount() {
        UserDefaults.standard.set(dailyIntrusiveCount, forKey: dailyIntrusiveKey)
    }
    
    func deleteCard(_ card: TravelCard) {
        Task {
            do {
                try await TravelCardAPIService.shared.deleteCard(id: card.id)
                cards.removeAll { $0.id == card.id }
            } catch {
                print("Error deleting card: \(error)")
            }
        }
    }
    
    func toggleLike(_ card: TravelCard) {
        Task {
            do {
                let (liked, likeCount) = try await TravelCardAPIService.shared.toggleLike(cardId: card.id)
                
                if let index = cards.firstIndex(where: { $0.id == card.id }) {
                    var updatedCard = card
                    updatedCard.is_liked = liked
                    updatedCard.like_count = likeCount
                    cards[index] = updatedCard
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
    
    func clearAllCards() {
        cards.removeAll()
        saveCards()
        dailyNormalCount = 0
        dailyIntrusiveCount = 0
        saveDailyNormalCount()
        saveDailyIntrusiveCount()
    }
    
    private func loadDailyCounts() {
        dailyNormalCount = UserDefaults.standard.integer(forKey: dailyNormalKey)
        dailyIntrusiveCount = UserDefaults.standard.integer(forKey: dailyIntrusiveKey)
    }
    
    // --- Seen card logic ---
    func markCardSeen(_ cardID: Int) {
        if !seenCardIDs.contains(cardID) {
            seenCardIDs.insert(cardID)
            saveSeenCardIDs()
        }
    }
    
    private func saveSeenCardIDs() {
        let array = Array(seenCardIDs)
        UserDefaults.standard.set(array, forKey: seenCardsKey)
    }
    
    private func loadSeenCardIDs() {
        if let array = UserDefaults.standard.array(forKey: seenCardsKey) as? [Int] {
            seenCardIDs = Set(array)
        }
    }
    // ---
} 

// MARK: - API Models

struct CreateCardResponse: Codable {
    let destination_name: String?
    let image: String?
    let s3_url: String?
    let thought: String?
    let location: String?
    let coordinates: String?
    let category: String?
    let device_id: String?
    
    // Custom decoder to handle missing fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode each field, use nil if missing
        destination_name = try container.decodeIfPresent(String.self, forKey: .destination_name)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        s3_url = try container.decodeIfPresent(String.self, forKey: .s3_url)
        thought = try container.decodeIfPresent(String.self, forKey: .thought)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        coordinates = try container.decodeIfPresent(String.self, forKey: .coordinates)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        device_id = try container.decodeIfPresent(String.self, forKey: .device_id)
    }
    
    // Manual initializer for testing
    init(destination_name: String? = nil, image: String? = nil, s3_url: String? = nil, 
         thought: String? = nil, location: String? = nil, coordinates: String? = nil, 
         category: String? = nil, device_id: String? = nil) {
        self.destination_name = destination_name
        self.image = image
        self.s3_url = s3_url
        self.thought = thought
        self.location = location
        self.coordinates = coordinates
        self.category = category
        self.device_id = device_id
    }
}

struct UserResponse: Codable {
    let id: Int
    let username: String
    let first_name: String?
    let last_name: String?
    let email: String?
}

struct CheckInResponse: Codable {
    let id: Int
    let photo: String?
    let s3_url: String?
    let caption: String?
    let coordinates: String?
    let user: UserResponse
    let created_at: String
}

struct CommentResponse: Codable {
    let id: Int
    let content: String
    let user: UserResponse
    let parent: Int?
    let created_at: String
    let updated_at: String
    let like_count: Int
    let reply_count: Int
    let is_liked_by_user: Bool
}

struct CollectionResponse: Codable {
    let id: Int
    let name: String
    let description: String?
    let is_public: Bool
    let cover_image: String?
    let user: UserResponse
    let created_at: String
    let updated_at: String
    let card_count: Int
}

struct CollectionDetailResponse: Codable {
    let id: Int
    let name: String
    let description: String?
    let is_public: Bool
    let cover_image: String?
    let user: UserResponse
    let created_at: String
    let updated_at: String
    let card_count: Int
    let cards: [TravelCard]
}

struct TravelMoodResponse: Codable {
    let id: Int
    let name: String
    let icon: String
    let color: String
    let description: String
}

struct PaginatedResponse<T: Codable>: Codable {
    let results: [T]
    let count: Int
    let next: Bool?
    let previous: Bool?
    // total_pages is not returned by the API, so making it optional
}

struct AdminReviewRequest: Codable {
    let action: String // "approve" or "reject"
    let notes: String?
}

struct AdminStatsResponse: Codable {
    let total_cards: Int
    let pending_cards: Int
    let approved_cards: Int
    let rejected_cards: Int
    let cards_today: Int
    let average_review_time_hours: Double
} 
