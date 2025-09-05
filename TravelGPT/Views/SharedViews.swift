import SwiftUI

// MARK: - Rarity Badge Component
struct RarityBadge: View {
    let rarity: Rarity
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var backgroundSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 28
            case .large: return 36
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Enhanced background glow for rare/legendary
            if rarity.sparkleEffect {
                Circle()
                    .fill(rarity.gradient)
                    .frame(width: size.backgroundSize + 12, height: size.backgroundSize + 12)
                    .blur(radius: 6)
                    .opacity(0.6)
                    .scaleEffect(1.1)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: rarity.sparkleEffect
                    )
                
                // Additional sparkle rings for legendary
                if rarity == .legendary {
                    Circle()
                        .strokeBorder(rarity.gradient, lineWidth: 2)
                        .frame(width: size.backgroundSize + 16, height: size.backgroundSize + 16)
                        .blur(radius: 2)
                        .opacity(0.8)
                        .scaleEffect(1.2)
                        .animation(
                            .easeInOut(duration: 3).repeatForever(autoreverses: true),
                            value: rarity.sparkleEffect
                        )
                }
            }
            
            // Main badge background with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.backgroundSize, height: size.backgroundSize)
                .overlay(
                    Circle()
                        .strokeBorder(
                            rarity.gradient,
                            lineWidth: rarity.sparkleEffect ? 2 : 1.5
                        )
                )
                .shadow(
                    color: rarity.color.opacity(0.3),
                    radius: rarity.sparkleEffect ? 4 : 2,
                    x: 0,
                    y: 2
                )
            
            // Icon with enhanced styling
            Image(systemName: rarity.icon)
                .foregroundColor(rarity.color)
                .font(.system(size: size.iconSize, weight: .bold))
                .shadow(
                    color: rarity.color.opacity(0.3),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        }
    }
}

// MARK: - Collection Tag Component
struct CollectionTag: View {
    let tag: String
    let isCompact: Bool
    
    init(_ tag: String, isCompact: Bool = false) {
        self.tag = tag
        self.isCompact = isCompact
    }
    
    private var tagGradient: LinearGradient {
        // Create different gradients based on tag content for variety
        let tagLower = tag.lowercased()
        if tagLower.contains("beach") || tagLower.contains("ocean") || tagLower.contains("sea") {
            return LinearGradient(
                colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if tagLower.contains("mountain") || tagLower.contains("hiking") || tagLower.contains("nature") {
            return LinearGradient(
                colors: [Color.green.opacity(0.7), Color.mint.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if tagLower.contains("city") || tagLower.contains("urban") || tagLower.contains("downtown") {
            return LinearGradient(
                colors: [Color.purple.opacity(0.7), Color.indigo.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if tagLower.contains("food") || tagLower.contains("restaurant") || tagLower.contains("cuisine") {
            return LinearGradient(
                colors: [Color.orange.opacity(0.7), Color.red.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Travel-themed icon based on tag
            Image(systemName: tagIcon)
                .font(.system(size: isCompact ? 8 : 10, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text(tag)
                .font(isCompact ? .caption2 : .caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, isCompact ? 8 : 10)
        .padding(.vertical, isCompact ? 3 : 5)
        .background(
            Capsule()
                .fill(tagGradient)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
    }
    
    private var tagIcon: String {
        let tagLower = tag.lowercased()
        if tagLower.contains("beach") || tagLower.contains("ocean") || tagLower.contains("sea") {
            return "wave.3.right"
        } else if tagLower.contains("mountain") || tagLower.contains("hiking") || tagLower.contains("nature") {
            return "mountain.2"
        } else if tagLower.contains("city") || tagLower.contains("urban") || tagLower.contains("downtown") {
            return "building.2"
        } else if tagLower.contains("food") || tagLower.contains("restaurant") || tagLower.contains("cuisine") {
            return "fork.knife"
        } else if tagLower.contains("culture") || tagLower.contains("museum") || tagLower.contains("art") {
            return "paintbrush"
        } else if tagLower.contains("adventure") || tagLower.contains("extreme") || tagLower.contains("sport") {
            return "figure.hiking"
        } else {
            return "location"
        }
    }
}

// MARK: - Rarity Statistics View
struct RarityStatsView: View {
    let cards: [TravelCard]
    
    private var rarityCounts: [Rarity: Int] {
        var counts: [Rarity: Int] = [.common: 0, .rare: 0, .legendary: 0]
        for card in cards {
            let rarity = card.rarityEnum ?? .common
            counts[rarity, default: 0] += 1
        }
        return counts
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(Rarity.allCases, id: \.self) { rarity in
                VStack(spacing: 4) {
                    RarityBadge(rarity: rarity, size: .small)
                    Text("\(rarityCounts[rarity] ?? 0)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(rarity.color)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Collection Showcase View
struct CollectionShowcaseView: View {
    let cards: [TravelCard]
    
    private var allCollections: [String] {
        let collections = cards.compactMap { $0.collection_tags }.flatMap { $0 }
        return Array(Set(collections)).sorted()
    }
    
    private func cardsInCollection(_ collection: String) -> [TravelCard] {
        return cards.filter { $0.collection_tags?.contains(collection) == true }
    }
    
    var body: some View {
        if !allCollections.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Collections")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(allCollections, id: \.self) { collection in
                            VStack(spacing: 4) {
                                Text(collection)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("\(cardsInCollection(collection).count) cards")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Achievement System
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let rarity: Rarity?
    let requirement: Int
    let isUnlocked: Bool
    
    init(title: String, description: String, icon: String, rarity: Rarity? = nil, requirement: Int, currentCount: Int) {
        self.title = title
        self.description = description
        self.icon = icon
        self.rarity = rarity
        self.requirement = requirement
        self.isUnlocked = currentCount >= requirement
    }
}

struct AchievementsView: View {
    let cards: [TravelCard]
    
    private var achievements: [Achievement] {
        let totalCards = cards.count
        let legendaryCards = cards.filter { $0.rarityEnum == .legendary }.count
        let rareCards = cards.filter { $0.rarityEnum == .rare }.count
        let collections = Set(cards.compactMap { $0.collection_tags }.flatMap { $0 }).count
        
        return [
            Achievement(
                title: "First Steps",
                description: "Collect your first card",
                icon: "1.circle.fill",
                requirement: 1,
                currentCount: totalCards
            ),
            Achievement(
                title: "Card Collector",
                description: "Collect 10 cards",
                icon: "10.circle.fill",
                requirement: 10,
                currentCount: totalCards
            ),
            Achievement(
                title: "Rare Hunter",
                description: "Collect 3 rare cards",
                icon: "diamond.fill",
                rarity: .rare,
                requirement: 3,
                currentCount: rareCards
            ),
            Achievement(
                title: "Legendary Master",
                description: "Collect a legendary card",
                icon: "star.fill",
                rarity: .legendary,
                requirement: 1,
                currentCount: legendaryCards
            ),
            Achievement(
                title: "Collectionist",
                description: "Cards from 3 different collections",
                icon: "folder.fill",
                requirement: 3,
                currentCount: collections
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? (achievement.rarity?.color ?? .green) : .gray)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !achievement.isUnlocked {
                Text("\(achievement.requirement)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            achievement.isUnlocked ? Color.green.opacity(0.3) : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Rarity Celebration View
struct RarityCelebrationView: View {
    let rarity: Rarity
    @State private var isAnimating = false
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                // Rarity badge with animation
                RarityBadge(rarity: rarity, size: .large)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                
                // Celebration text
                VStack(spacing: 8) {
                    Text("🎉 Congratulations! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You got a \(rarity.displayName) card!")
                        .font(.headline)
                        .foregroundColor(rarity.color)
                    
                    Text("This is a special find!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Sparkle effects
                if rarity.sparkleEffect {
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "sparkles")
                                .foregroundColor(rarity.color)
                                .font(.title)
                                .offset(y: isAnimating ? -10 : 10)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
                
                // Close button
                Button("Continue") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(rarity.gradient)
                )
                .padding(.top, 20)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.9))
                    .shadow(radius: 20)
            )
            .padding(20)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Existing Shared Views
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct GlowingEffect: ViewModifier {
    var glow: Bool
    @State var animate = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: glow ? Color.purple.opacity(animate ? 0.8 : 0.3) : .clear,
                    radius: glow ? (animate ? 24 : 8) : 0)
            .onAppear {
                if glow {
                    withAnimation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                }
            }
            .onChange(of: glow) { _, newValue in
                if newValue {
                    withAnimation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                } else {
                    animate = false
                }
            }
    }
}

struct OnboardingStepView: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(color)
                .padding(.top, 16)
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
        }
    }
}

struct PersonalityCard: View {
    let category: PersonalityCategory
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    // Get icon and color for each personality type
    private var personalityIcon: String {
        switch category.id {
        case "cuddle_comfort":
            return "heart.fill"
        case "food_obsessed":
            return "fork.knife"
        case "socialites_extroverts":
            return "person.2.fill"
        case "drama_sass":
            return "theatermasks.fill"
        case "oddballs_daydreamers":
            return "sparkles"
        case "chaos_crew":
            return "tornado"
        case "planners_plotters":
            return "chart.line.uptrend.xyaxis"
        case "low_energy_legends":
            return "moon.zzz.fill"
        default:
            return "pawprint.fill"
        }
    }
    
    private var personalityColor: Color {
        switch category.id {
        case "cuddle_comfort":
            return Color(red: 0.95, green: 0.3, blue: 0.5) // Vibrant pink
        case "food_obsessed":
            return Color(red: 1.0, green: 0.6, blue: 0.2) // Bright orange
        case "socialites_extroverts":
            return Color(red: 0.2, green: 0.7, blue: 0.9) // Electric blue
        case "drama_sass":
            return Color(red: 0.8, green: 0.2, blue: 0.8) // Magenta
        case "oddballs_daydreamers":
            return Color(red: 0.4, green: 0.8, blue: 0.4) // Lime green
        case "chaos_crew":
            return Color(red: 0.9, green: 0.3, blue: 0.2) // Fire red
        case "planners_plotters":
            return Color(red: 0.3, green: 0.5, blue: 0.9) // Royal blue
        case "low_energy_legends":
            return Color(red: 0.6, green: 0.6, blue: 0.8) // Slate blue
        default:
            return Color.blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: personalityIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : personalityColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : personalityColor.opacity(0.1))
                    )
                
                // Title
                Text(category.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Description
                Text(category.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [personalityColor, personalityColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isDisabled ? 0.4 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? personalityColor : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? personalityColor.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .disabled(isDisabled)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - User Collections View
struct UserCollectionsView: View {
    let cards: [TravelCard]
    @StateObject private var collectionStore = CollectionStore()
    @State private var showCreateCollection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Collections")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("New") {
                    showCreateCollection = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if collectionStore.isLoading {
                ProgressView("Loading collections...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if collectionStore.userCollections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("No Collections Yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Create collections to organize your cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create Collection") {
                        showCreateCollection = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(collectionStore.userCollections) { collection in
                            UserCollectionCard(collection: collection)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showCreateCollection) {
            CreateCollectionView(
                collectionStore: collectionStore,
                onCollectionCreated: {
                    showCreateCollection = false
                }
            )
        }
        .task {
            await collectionStore.fetchUserCollections()
        }
    }
}

struct UserCollectionCard: View {
    let collection: Collection
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 2) {
                Text(collection.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(collection.card_count) cards")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
    }
}