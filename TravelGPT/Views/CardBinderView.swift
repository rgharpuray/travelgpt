import SwiftUI

struct CardBinderView: View {
    @ObservedObject var cardStore: CardStore
    @State private var selectedCard: TravelCard?
    @State private var currentPage = 0
    @State private var sortByRarity: Bool = false
    @State private var showAchievements: Bool = false
    @State private var showCollections: Bool = false
    private let cardsPerPage = 9
    
    var body: some View {
        NavigationView {
            ZStack {
                // Binder background
                Color(red: 0.9, green: 0.9, blue: 0.9)
                    .ignoresSafeArea()
                
                VStack {
                    // Page indicator and controls
                    HStack {
                        Text("Page \(currentPage + 1) of \(totalPages)")
                            .font(.headline)
                        Spacer()
                        
                        // Rarity sort toggle
                        Button(action: {
                            sortByRarity.toggle()
                            showAchievements = false
                            currentPage = 0
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: sortByRarity ? "star.fill" : "star")
                                Text(sortByRarity ? "Rarity" : "Sort")
                            }
                            .font(.caption)
                            .foregroundColor(sortByRarity ? .orange : .blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(sortByRarity ? Color.orange.opacity(0.2) : Color.blue.opacity(0.1))
                        )
                        
                        // Achievements toggle
                        Button(action: {
                            showAchievements.toggle()
                            sortByRarity = false
                            showCollections = false
                            currentPage = 0
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showAchievements ? "trophy.fill" : "trophy")
                                Text("Achievements")
                            }
                            .font(.caption)
                            .foregroundColor(showAchievements ? .yellow : .blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(showAchievements ? Color.yellow.opacity(0.2) : Color.blue.opacity(0.1))
                        )
                        
                        // Collections toggle
                        Button(action: {
                            showCollections.toggle()
                            sortByRarity = false
                            showAchievements = false
                            currentPage = 0
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showCollections ? "folder.fill" : "folder")
                                Text("Collections")
                            }
                            .font(.caption)
                            .foregroundColor(showCollections ? .blue : .blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(showCollections ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                        )
                        
                        Button(action: {
                            cardStore.clearAllCards()
                            currentPage = 0
                        }) {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                        .foregroundColor(.red)
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    // Content area
                    if showAchievements {
                        // Show achievements
                        ScrollView {
                            AchievementsView(cards: cardStore.cards)
                                .padding()
                        }
                    } else if showCollections {
                        // Show user collections
                        UserCollectionsView(cards: cardStore.cards)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    } else {
                        // Show rarity statistics or collection showcase
                        if sortByRarity {
                            RarityStatsView(cards: cardStore.cards)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        } else {
                            CollectionShowcaseView(cards: cardStore.cards)
                        }
                        
                        // Cards grid
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                                ForEach(currentPageCards) { card in
                                    CardThumbnail(card: card)
                                        .onTapGesture {
                                            selectedCard = card
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                cardStore.deleteCard(card)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // Page navigation (only show when not viewing achievements or collections)
                    if !showAchievements && !showCollections {
                        HStack {
                            Button(action: previousPage) {
                                Image(systemName: "chevron.left")
                                    .font(.title)
                                    .foregroundColor(currentPage > 0 ? .blue : .gray)
                            }
                            .disabled(currentPage == 0)
                            
                            Spacer()
                            
                            Button(action: nextPage) {
                                Image(systemName: "chevron.right")
                                    .font(.title)
                                    .foregroundColor(currentPage < totalPages - 1 ? .blue : .gray)
                            }
                            .disabled(currentPage >= totalPages - 1)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Dog Cards")
            .sheet(item: $selectedCard) { card in
                TravelCardView(card: card)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var totalPages: Int {
        return max(1, Int(ceil(Double(cardStore.cards.count) / Double(cardsPerPage))))
    }
    
    private var currentPageCards: [TravelCard] {
        let sortedCards = sortByRarity ? cardStore.cards.sorted { card1, card2 in
            let rarity1 = card1.rarityEnum ?? .common
            let rarity2 = card2.rarityEnum ?? .common
            
            // Sort by rarity (legendary > rare > common)
            if rarity1 != rarity2 {
                switch (rarity1, rarity2) {
                case (.legendary, _): return true
                case (.rare, .common): return true
                default: return false
                }
            }
            
            // If same rarity, sort by creation date (newest first)
            let date1 = card1.created_at ?? ""
            let date2 = card2.created_at ?? ""
            return date1 > date2
        } : cardStore.cards
        
        let startIndex = currentPage * cardsPerPage
        let endIndex = min(startIndex + cardsPerPage, sortedCards.count)
        return Array(sortedCards[startIndex..<endIndex])
    }
    
    private func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
}

struct CardThumbnail: View {
    let card: TravelCard
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    card.rarityEnum?.color.opacity(0.4) ?? Color.clear,
                    lineWidth: card.rarityEnum?.sparkleEffect == true ? 1.5 : 0
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .shadow(
                    color: card.rarityEnum?.color.opacity(0.15) ?? Color.clear,
                    radius: card.rarityEnum?.sparkleEffect == true ? 4 : 2
                )
            
            VStack {
                ZStack(alignment: .topTrailing) {
                    AsyncImageView(url: URL(string: card.image))
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(8)
                    
                    // Rarity indicator for thumbnail
                    if let rarity = card.rarityEnum {
                        RarityBadge(rarity: rarity, size: .small)
                            .padding(4)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(card.thought ?? "No description")
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                    
                    // Show first collection tag if available
                    if let firstTag = card.collection_tags?.first {
                        CollectionTag(firstTag, isCompact: true)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(8)
        }
        .frame(height: 160)
    }
}

#Preview {
    CardBinderView(cardStore: CardStore())
} 
