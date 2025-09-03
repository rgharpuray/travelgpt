import Foundation

// MARK: - Collection Models

struct Collection: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let created_at: String
    let updated_at: String
    let card_count: Int
    let is_system: Bool
    
    // Mock-specific properties
    var isMock: Bool = false
    var mockId: String = UUID().uuidString
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if let date = ISO8601DateFormatter().date(from: created_at) {
            return formatter.string(from: date)
        }
        return created_at
    }
}

struct SystemCollection: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let created_at: String
    let updated_at: String
    let card_count: Int
}

struct CollectionDetail: Codable {
    let collection: Collection
    let cards: PaginatedCards
}

struct PaginatedCards: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [TravelCard]
}

struct CreateCollectionRequest: Codable {
    let name: String
    let description: String
}

struct UpdateCollectionRequest: Codable {
    let name: String
    let description: String
}

// MARK: - Mock Collection Store
@MainActor
class CollectionStore: ObservableObject {
    @Published var userCollections: [Collection] = []
    @Published var systemCollections: [SystemCollection] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let userDefaults = UserDefaults.standard
    private let userCollectionsKey = "mock_user_collections"
    private let collectionCardsKey = "mock_collection_cards"
    
    init() {
        loadMockCollections()
    }
    
    // MARK: - Mock Data Management
    
    private func loadMockCollections() {
        if let data = userDefaults.data(forKey: userCollectionsKey),
           let collections = try? JSONDecoder().decode([Collection].self, from: data) {
            self.userCollections = collections
        }
    }
    
    private func saveMockCollections() {
        if let data = try? JSONEncoder().encode(userCollections) {
            userDefaults.set(data, forKey: userCollectionsKey)
        }
    }
    
    private func getCollectionCards(_ collectionId: String) -> [Int] {
        let key = "\(collectionCardsKey)_\(collectionId)"
        return userDefaults.array(forKey: key) as? [Int] ?? []
    }
    
    private func saveCollectionCards(_ collectionId: String, cardIds: [Int]) {
        let key = "\(collectionCardsKey)_\(collectionId)"
        userDefaults.set(cardIds, forKey: key)
    }
    
    // MARK: - API Methods (with fallback to mock)
    
    func fetchUserCollections() async {
        isLoading = true
        error = nil
        
        do {
            // Try real API first
            let collections = try await BackendService.shared.fetchUserCollections()
            await MainActor.run {
                self.userCollections = collections
                self.isLoading = false
            }
        } catch {
            print("⚠️ Real API failed, using mock data: \(error)")
            // Fall back to mock data
            await MainActor.run {
                self.loadMockCollections()
                self.isLoading = false
            }
        }
    }
    
    func fetchSystemCollections() async {
        isLoading = true
        error = nil
        
        do {
            // Try real API first
            let collections = try await BackendService.shared.fetchSystemCollections()
            await MainActor.run {
                self.systemCollections = collections
                self.isLoading = false
            }
        } catch {
            print("⚠️ Real API failed, using mock data: \(error)")
            // Fall back to mock data
            await MainActor.run {
                self.systemCollections = [
                    SystemCollection(id: 1, name: "Puppies", description: "Adorable puppy moments", created_at: "2024-01-01", updated_at: "2024-01-01", card_count: 0),
                    SystemCollection(id: 2, name: "Sleepy Dogs", description: "Dogs in their most peaceful state", created_at: "2024-01-01", updated_at: "2024-01-01", card_count: 0),
                    SystemCollection(id: 3, name: "Playful Pups", description: "Dogs having fun", created_at: "2024-01-01", updated_at: "2024-01-01", card_count: 0)
                ]
                self.isLoading = false
            }
        }
    }
    
    func createUserCollection(_ collectionRequest: CreateCollectionRequest) async throws -> Collection {
        do {
            // Try real API first
            return try await BackendService.shared.createUserCollection(collectionRequest)
        } catch {
            print("⚠️ Real API failed, creating mock collection: \(error)")
            // Create mock collection
            let mockCollection = Collection(
                id: userCollections.count + 1,
                name: collectionRequest.name,
                description: collectionRequest.description,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date()),
                card_count: 0,
                is_system: false,
                isMock: true,
                mockId: UUID().uuidString
            )
            
            await MainActor.run {
                self.userCollections.append(mockCollection)
                self.saveMockCollections()
            }
            
            return mockCollection
        }
    }
    
    func updateUserCollection(_ id: Int, _ collectionRequest: UpdateCollectionRequest) async throws -> Collection {
        do {
            // Try real API first
            return try await BackendService.shared.updateUserCollection(id, collectionRequest)
        } catch {
            print("⚠️ Real API failed, updating mock collection: \(error)")
            // Update mock collection
            guard let index = userCollections.firstIndex(where: { $0.id == id }) else {
                throw NSError(domain: "CollectionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
            }
            
            let updatedCollection = Collection(
                id: userCollections[index].id,
                name: collectionRequest.name,
                description: collectionRequest.description,
                created_at: userCollections[index].created_at,
                updated_at: ISO8601DateFormatter().string(from: Date()),
                card_count: userCollections[index].card_count,
                is_system: false,
                isMock: true,
                mockId: userCollections[index].mockId
            )
            
            await MainActor.run {
                self.userCollections[index] = updatedCollection
                self.saveMockCollections()
            }
            
            return updatedCollection
        }
    }
    
    func deleteUserCollection(_ id: Int) async throws {
        do {
            // Try real API first
            try await BackendService.shared.deleteUserCollection(id)
        } catch {
            print("⚠️ Real API failed, deleting mock collection: \(error)")
            // Delete mock collection
            guard let index = userCollections.firstIndex(where: { $0.id == id }) else {
                throw NSError(domain: "CollectionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
            }
            
            let collection = userCollections[index]
            await MainActor.run {
                self.userCollections.remove(at: index)
                self.saveMockCollections()
                // Also remove associated cards
                self.saveCollectionCards(collection.mockId, cardIds: [])
            }
        }
    }
    
    func fetchUserCollectionDetail(_ id: Int, page: Int = 1, pageSize: Int = 20) async throws -> CollectionDetail {
        do {
            // Try real API first
            return try await BackendService.shared.fetchUserCollectionDetail(id, page: page, pageSize: pageSize)
        } catch {
            print("⚠️ Real API failed, fetching mock collection detail: \(error)")
            // Get mock collection detail
            guard let collection = userCollections.first(where: { $0.id == id }) else {
                throw NSError(domain: "CollectionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
            }
            
            let cardIds = getCollectionCards(collection.mockId)
            print("🔍 Collection \(collection.name) has card IDs: \(cardIds)")
            
            // Get cards from UserDefaults first
            let savedCardsData = UserDefaults.standard.data(forKey: "savedCards")
            var allCards: [TravelCard] = []
            
            if let data = savedCardsData,
               let cards = try? JSONDecoder().decode([TravelCard].self, from: data) {
                allCards = cards
                print("📦 Loaded \(cards.count) cards from UserDefaults")
            } else {
                print("⚠️ No cards found in UserDefaults")
            }
            
            // If we don't have enough cards, try to get more from the feed
            if allCards.count < cardIds.count {
                print("🔄 Need more cards, fetching from feed...")
                do {
                    let feedCards = try await BackendService.shared.fetchFeed(page: 1, pageSize: 100, isIntrusive: false)
                    // Merge cards, avoiding duplicates
                    let existingIds = Set(allCards.map { $0.id })
                    let newCards = feedCards.filter { !existingIds.contains($0.id) }
                    allCards.append(contentsOf: newCards)
                    print("📦 Added \(newCards.count) new cards from feed, total: \(allCards.count)")
                } catch {
                    print("⚠️ Failed to load cards from feed: \(error)")
                }
            }
            
            let collectionCards = allCards.filter { cardIds.contains($0.id) }
            print("🎯 Found \(collectionCards.count) cards in collection")
            
            // Debug: Check which card IDs we have vs what we're looking for
            if !cardIds.isEmpty {
                print("🔍 Looking for card IDs: \(cardIds)")
                print("📦 Available card IDs: \(allCards.map { $0.id })")
                let missingCards = cardIds.filter { !allCards.map { $0.id }.contains($0) }
                if !missingCards.isEmpty {
                    print("❌ Missing card IDs: \(missingCards)")
                }
            }
            
            let paginatedCards = PaginatedCards(count: collectionCards.count, next: nil, previous: nil, results: collectionCards)
            
            return CollectionDetail(collection: collection, cards: paginatedCards)
        }
    }
    
    func addCardToCollection(_ cardId: Int, _ collectionId: Int) async throws {
        do {
            // Try real API first
            try await BackendService.shared.addCardToCollection(cardId: cardId, collectionId: collectionId)
        } catch {
            print("⚠️ Real API failed, adding card to mock collection: \(error)")
            // Add card to mock collection
            guard let index = userCollections.firstIndex(where: { $0.id == collectionId }) else {
                throw NSError(domain: "CollectionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
            }
            
            let collection = userCollections[index]
            var cardIds = getCollectionCards(collection.mockId)
            
            if !cardIds.contains(cardId) {
                print("➕ Adding card \(cardId) to collection \(collection.name)")
                cardIds.append(cardId)
                saveCollectionCards(collection.mockId, cardIds: cardIds)
                print("💾 Saved collection cards: \(cardIds)")
                
                // Also ensure the card is saved to UserDefaults for retrieval
                await ensureCardIsSaved(cardId: cardId)
                
                // Update collection card count
                let updatedCollection = Collection(
                    id: collection.id,
                    name: collection.name,
                    description: collection.description,
                    created_at: collection.created_at,
                    updated_at: ISO8601DateFormatter().string(from: Date()),
                    card_count: cardIds.count,
                    is_system: false,
                    isMock: true,
                    mockId: collection.mockId
                )
                
                await MainActor.run {
                    self.userCollections[index] = updatedCollection
                    self.saveMockCollections()
                }
            }
        }
    }
    
    func removeCardFromCollection(_ cardId: Int, _ collectionId: Int) async throws {
        do {
            // Try real API first
            try await BackendService.shared.removeCardFromCollection(cardId: cardId, collectionId: collectionId)
        } catch {
            print("⚠️ Real API failed, removing card from mock collection: \(error)")
            // Remove card from mock collection
            guard let index = userCollections.firstIndex(where: { $0.id == collectionId }) else {
                throw NSError(domain: "CollectionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Collection not found"])
            }
            
            let collection = userCollections[index]
            var cardIds = getCollectionCards(collection.mockId)
            
            if let cardIndex = cardIds.firstIndex(of: cardId) {
                cardIds.remove(at: cardIndex)
                saveCollectionCards(collection.mockId, cardIds: cardIds)
                
                // Update collection card count
                let updatedCollection = Collection(
                    id: collection.id,
                    name: collection.name,
                    description: collection.description,
                    created_at: collection.created_at,
                    updated_at: ISO8601DateFormatter().string(from: Date()),
                    card_count: cardIds.count,
                    is_system: false,
                    isMock: true,
                    mockId: collection.mockId
                )
                
                await MainActor.run {
                    self.userCollections[index] = updatedCollection
                    self.saveMockCollections()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func isCardInCollection(_ cardId: Int, _ collectionId: Int) -> Bool {
        guard let collection = userCollections.first(where: { $0.id == collectionId }) else {
            return false
        }
        let cardIds = getCollectionCards(collection.mockId)
        return cardIds.contains(cardId)
    }
    
    func getCollectionCardIds(_ collectionId: Int) -> [Int] {
        guard let collection = userCollections.first(where: { $0.id == collectionId }) else {
            return []
        }
        return getCollectionCards(collection.mockId)
    }
    
    // MARK: - Helper Methods
    
    private func ensureCardIsSaved(cardId: Int) async {
        // Check if card already exists in UserDefaults
        let savedCardsData = UserDefaults.standard.data(forKey: "savedCards")
        let existingCards: [TravelCard] = {
            if let data = savedCardsData,
               let cards = try? JSONDecoder().decode([TravelCard].self, from: data) {
                return cards
            }
            return []
        }()
        
        // If card doesn't exist, try to fetch it from the API
        if !existingCards.contains(where: { $0.id == cardId }) {
            print("🔄 Card \(cardId) not found in UserDefaults, trying to fetch from API...")
            do {
                // Try to get the card from the feed or a specific card endpoint
                let feedCards = try await BackendService.shared.fetchFeed(page: 1, pageSize: 100, isIntrusive: false)
                if let card = feedCards.first(where: { $0.id == cardId }) {
                    print("✅ Found card \(cardId) in feed, saving to UserDefaults")
                    var updatedCards = existingCards
                    updatedCards.append(card)
                    if let encoded = try? JSONEncoder().encode(updatedCards) {
                        UserDefaults.standard.set(encoded, forKey: "savedCards")
                    }
                } else {
                    print("⚠️ Card \(cardId) not found in feed")
                }
            } catch {
                print("❌ Failed to fetch card \(cardId) from API: \(error)")
            }
        } else {
            print("✅ Card \(cardId) already exists in UserDefaults")
        }
    }
}



