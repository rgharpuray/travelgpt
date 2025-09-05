import SwiftUI

struct TravelCardView: View {
    let card: TravelCard
    @State private var showShareSheet = false
    @State private var cardImage: UIImage?
    
    var body: some View {
        // Debug prints for rarity fields
        let _ = {
            print("TravelCardView - card.id: \(card.id), rarity: \(String(describing: card.rarity)), rarityEnum: \(String(describing: card.rarityEnum)), collection_tags: \(String(describing: card.collection_tags))")
            return 0
        }()
                ZStack {
            // Card border and shadow based on rarity
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(
                    card.rarityEnum?.gradient ?? LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: card.rarityEnum?.sparkleEffect == true ? 3 : 2
                )
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            card.themeColor?.opacity(0.1) ?? card.rarityEnum?.color.opacity(0.05) ?? Color.gray.opacity(0.05)
                        )
                )
                .shadow(
                    color: card.themeColor?.opacity(0.3) ?? card.rarityEnum?.color.opacity(0.2) ?? Color.gray.opacity(0.1),
                    radius: card.rarityEnum?.sparkleEffect == true ? 8 : 4
                )
            
            // Main image with overlays
            ZStack(alignment: .top) {
                // Dog image fills most of the card
                AsyncImageView(url: URL(string: card.image))
                    .aspectRatio(3/4, contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(24)
                    .padding(12)
                
                // Rarity indicator at top right
                VStack {
                    HStack {
                        Spacer()
                        if let rarity = card.rarityEnum {
                            RarityBadge(rarity: rarity, size: .large)
                                .padding(.trailing, 24)
                                .padding(.top, 24)
                                .scaleEffect(rarity.sparkleEffect ? 1.05 : 1.0)
                                .animation(
                                    rarity.sparkleEffect ? 
                                        .easeInOut(duration: 2).repeatForever(autoreverses: true) : 
                                        .default,
                                    value: rarity.sparkleEffect
                                )
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Thought bubble and collection tags overlay at bottom
                VStack {
                    Spacer()
                    
                    // Mood tags (if any) - non-intrusive display
                    if !card.moods.isEmpty {
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(card.moods.prefix(3), id: \.self) { mood in
                                        Text(mood)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.black.opacity(0.6))
                                            )
                                    }
                                    
                                    if card.moods.count > 3 {
                                        Text("+\(card.moods.count - 3)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.black.opacity(0.6))
                                            )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Collection tags (if any)
                    if let collectionTags = card.collection_tags, !collectionTags.isEmpty {
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(collectionTags, id: \.self) { tag in
                                        CollectionTag(tag)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Thought bubble
                    HStack {
                        Text(card.thought ?? "No description")
                            .font(.body)
                            .italic()
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.92))
                                    .shadow(radius: 2)
                            )
                            .padding(.leading, 20)
                            .padding(.bottom, 24)
                        Spacer()
                    }
                }
                    }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .frame(width: 320, height: 440)
        .padding(.vertical, 12)
    }
}


/*
#Preview {
    TravelCardView(card: TravelCard(
        id: 1,
        destination_name: "Argos",
                    image: "https://images.dog.ceo/breeds/hound-afghan/n02088094_1003.jpg",
        is_valid_destination: true,
        thought: "I want a treat!",
        created_at: "2024-01-01T00:00:00Z",
        updated_at: nil,
        like_count: 5,
        is_liked: true,
        is_owner: true, is_intrusive_mode: false
    ))
} */
