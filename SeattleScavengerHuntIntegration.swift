import SwiftUI

// MARK: - Integration with Existing TravelGPT App

// This file shows how to integrate the Seattle Scavenger Hunt with the existing TravelGPT app

extension ContentView {
    
    // Add this to your main ContentView to include the Seattle Scavenger Hunt
    var seattleScavengerHuntTab: some View {
        SeattleScavengerHuntView()
            .tabItem {
                Image(systemName: "map.fill")
                Text("Seattle Hunt")
            }
    }
}

// MARK: - Travel Card Integration

extension TravelCard {
    
    // Convert Seattle Scavenger Hunt activities to TravelCard format
    static func fromSeattleActivity(_ activity: SeattleScavengerHunt.ScavengerHuntActivity) -> TravelCard {
        return TravelCard(
            id: activity.id,
            destination_name: activity.name,
            image: "seattle_activity_\(activity.id)", // You would have actual images
            is_valid_destination: true,
            thought: activity.challenge,
            created_at: Date().ISO8601Format(),
            updated_at: Date().ISO8601Format(),
            like_count: 0,
            is_liked: false,
            is_owner: false,
            is_intrusive_mode: false,
            device_destination_name: nil,
            owner_destination_name: nil,
            rarity: nil,
            collection_tags: [activity.category.rawValue],
            category: activity.category.rawValue,
            isVerified: true,
            checkInPhotos: [],
            s3_url: nil,
            location: activity.location,
            coordinates: activity.coordinates,
            admin_review_status: "approved",
            admin_reviewer_id: nil,
            admin_reviewed_at: nil,
            admin_notes: nil,
            check_in_count: 0,
            comment_count: 0,
            is_liked_by_user: false,
            is_checked_in_by_user: false,
            moods: ["adventure", "exploration"],
            user: nil,
            device_id: nil,
            theme_color: activity.category.color.toHex(),
            is_in_wishlist: false,
            wishlist_priority: nil,
            ai_insights: "Seattle Scavenger Hunt Activity - \(activity.points) points",
            color_theme: activity.category.color.toHex(),
            is_verified: true
        )
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}

// MARK: - Scavenger Hunt Service

class SeattleScavengerHuntService {
    static let shared = SeattleScavengerHuntService()
    
    private init() {}
    
    // Get all Seattle activities as TravelCards
    func getSeattleActivitiesAsTravelCards() -> [TravelCard] {
        return SeattleScavengerHunt.seattleActivities.map { activity in
            TravelCard.fromSeattleActivity(activity)
        }
    }
    
    // Get activities by category as TravelCards
    func getSeattleActivitiesByCategory(_ category: SeattleScavengerHunt.ScavengerHuntCategory) -> [TravelCard] {
        return SeattleScavengerHunt.getActivitiesByCategory(category).map { activity in
            TravelCard.fromSeattleActivity(activity)
        }
    }
    
    // Get random Seattle activity as TravelCard
    func getRandomSeattleActivity() -> TravelCard? {
        guard let activity = SeattleScavengerHunt.getRandomActivity() else { return nil }
        return TravelCard.fromSeattleActivity(activity)
    }
    
    // Get nearby activities (simplified - would use actual location services)
    func getNearbySeattleActivities(latitude: Double, longitude: Double, radius: Double = 1.0) -> [TravelCard] {
        return getSeattleActivitiesAsTravelCards() // Simplified for demo
    }
}

// MARK: - Card Store Extension

extension CardStore {
    
    // Add Seattle scavenger hunt activities to the card store
    func loadSeattleScavengerHuntActivities() {
        let seattleCards = SeattleScavengerHuntService.shared.getSeattleActivitiesAsTravelCards()
        
        // Add to existing cards (you might want to filter or replace)
        self.cards.append(contentsOf: seattleCards)
    }
    
    // Filter cards to show only Seattle scavenger hunt activities
    var seattleScavengerHuntCards: [TravelCard] {
        return cards.filter { card in
            card.location?.contains("Seattle") == true && 
            card.category?.contains("scavenger") == true
        }
    }
}

// MARK: - Usage Example

/*
 
 To integrate this into your existing TravelGPT app:
 
 1. Add the SeattleScavengerHuntView to your main tab view:
 
 TabView {
     // Your existing tabs...
     
     SeattleScavengerHuntView()
         .tabItem {
             Image(systemName: "map.fill")
             Text("Seattle Hunt")
         }
 }
 
 2. Load Seattle activities into your CardStore:
 
 // In your CardStore or wherever you load cards
 cardStore.loadSeattleScavengerHuntActivities()
 
 3. Filter your main feed to include Seattle activities:
 
 // In your ContentView or wherever you display cards
 var filteredCards: [TravelCard] {
     // Your existing filtering logic...
     // Add: .union(cardStore.seattleScavengerHuntCards)
 }
 
 4. Add location-based filtering:
 
 // When user is in Seattle area
 if isInSeattleArea {
     let nearbyActivities = SeattleScavengerHuntService.shared.getNearbySeattleActivities(
         latitude: userLatitude,
         longitude: userLongitude
     )
     // Show these activities
 }
 
 */

// MARK: - Sample Integration Code

struct SeattleIntegrationExample: View {
    @StateObject private var cardStore = CardStore()
    @State private var showingSeattleHunt = false
    
    var body: some View {
        VStack {
            Text("TravelGPT with Seattle Scavenger Hunt")
                .font(.title)
                .padding()
            
            Button("Load Seattle Activities") {
                cardStore.loadSeattleScavengerHuntActivities()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Open Seattle Scavenger Hunt") {
                showingSeattleHunt = true
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            // Show some Seattle cards
            List(cardStore.seattleScavengerHuntCards.prefix(5)) { card in
                VStack(alignment: .leading) {
                    Text(card.destination_name ?? "Unknown")
                        .font(.headline)
                    Text(card.thought ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingSeattleHunt) {
            SeattleScavengerHuntView()
        }
    }
}


