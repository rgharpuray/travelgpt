import Foundation
import UIKit
import SwiftUI

struct TravelCard: Identifiable, Codable {
    let id: Int
    let destination_name: String
    let image_url: String
    let is_valid_destination: Bool
    let thought: String
    let created_at: String
    let updated_at: String?
    var like_count: Int
    var is_liked: Bool
    let is_owner: Bool?
    let is_intrusive_mode: Bool?
    let device_destination_name: String?
    let owner_destination_name: String?
    let rarity: String?
    let collection_tags: [String]?
    let category: String?
    var checkInPhotos: [CheckInPhoto] = []
    
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
    
    var filteredCards: [TravelCard] {
        cards.filter { ($0.is_intrusive_mode ?? false) == isIntrusiveMode }
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
    private let pageSize = 10
    
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
                switch self.feedType {
                case .all:
                    print("📡 Fetching public feed with isIntrusive: \(isIntrusiveMode)")
                    let cards = try await BackendService.shared.fetchFeed(page: 1, pageSize: self.pageSize, isIntrusive: self.isIntrusiveMode)
                    print("📦 Received \(cards.count) cards from API (pageSize: \(self.pageSize))")
                    await MainActor.run {
                        self.cards = cards
                        self.hasMoreContent = cards.count >= self.pageSize
                        print("📊 Initial load - cards: \(cards.count), hasMoreContent: \(self.hasMoreContent)")
                    }
                case .myCards:
                    print("📡 Fetching my cards with isIntrusive: \(isIntrusiveMode)")
                    let cards = try await BackendService.shared.fetchCards(isIntrusive: self.isIntrusiveMode)
                    print("📦 Received \(cards.count) cards from API")
                    await MainActor.run {
                        self.cards = cards
                        self.hasMoreContent = false // "My Cards" is not paginated
                    }
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
            let newCards = try await BackendService.shared.fetchFeed(page: nextPage, pageSize: pageSize, isIntrusive: self.isIntrusiveMode)
            print("📦 Received \(newCards.count) new cards from page \(nextPage)")
            
            if newCards.count < pageSize {
                print("📉 Received fewer cards than pageSize, setting hasMoreContent to false")
                hasMoreContent = false
            }
            
            if !newCards.isEmpty {
                print("✅ Adding \(newCards.count) new cards to existing \(self.cards.count) cards")
                self.cards.append(contentsOf: newCards)
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
                try await BackendService.shared.deleteCard(card.id)
                cards.removeAll { $0.id == card.id }
            } catch {
                print("Error deleting card: \(error)")
            }
        }
    }
    
    func toggleLike(_ card: TravelCard) {
        Task {
            do {
                let (liked, likeCount) = card.is_liked ?
                    try await BackendService.shared.unlikeCard(card.id) :
                    try await BackendService.shared.likeCard(card.id)
                
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
