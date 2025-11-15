import Foundation
import SwiftUI

// MARK: - Seattle Scavenger Hunt Data

struct SeattleScavengerHunt {
    
    // MARK: - Scavenger Hunt Categories
    
    enum ScavengerHuntCategory: String, CaseIterable {
        case iconicLandmarks = "iconic_landmarks"
        case artCulture = "art_culture"
        case neighborhoods = "neighborhoods"
        case historical = "historical"
        case nature = "nature"
        case food = "food"
        case spooky = "spooky"
        case outdoor = "outdoor"
        case hiddenGems = "hidden_gems"
        case waterfront = "waterfront"
        
        var displayName: String {
            switch self {
            case .iconicLandmarks: return "Iconic Landmarks"
            case .artCulture: return "Art & Culture"
            case .neighborhoods: return "Unique Neighborhoods"
            case .historical: return "Historical Sites"
            case .nature: return "Natural Attractions"
            case .food: return "Culinary Delights"
            case .spooky: return "Spooky Spots"
            case .outdoor: return "Outdoor Adventures"
            case .hiddenGems: return "Hidden Gems"
            case .waterfront: return "Waterfront Wonders"
            }
        }
        
        var icon: String {
            switch self {
            case .iconicLandmarks: return "building.2"
            case .artCulture: return "paintbrush"
            case .neighborhoods: return "house"
            case .historical: return "book"
            case .nature: return "leaf"
            case .food: return "fork.knife"
            case .spooky: return "moon.stars"
            case .outdoor: return "figure.hiking"
            case .hiddenGems: return "diamond"
            case .waterfront: return "water.waves"
            }
        }
        
        var color: Color {
            switch self {
            case .iconicLandmarks: return .blue
            case .artCulture: return .purple
            case .neighborhoods: return .green
            case .historical: return .brown
            case .nature: return .green
            case .food: return .orange
            case .spooky: return .black
            case .outdoor: return .mint
            case .hiddenGems: return .yellow
            case .waterfront: return .cyan
            }
        }
    }
    
    // MARK: - Scavenger Hunt Activity
    
    struct ScavengerHuntActivity: Identifiable, Codable {
        let id: Int
        let name: String
        let description: String
        let category: ScavengerHuntCategory
        let location: String
        let coordinates: String
        let challenge: String
        let points: Int
        let difficulty: Difficulty
        let timeEstimate: String
        let tips: [String]
        let photoChallenge: String
        let isCompleted: Bool
        let completedAt: Date?
        
        enum Difficulty: String, CaseIterable {
            case easy = "easy"
            case medium = "medium"
            case hard = "hard"
            
            var displayName: String {
                switch self {
                case .easy: return "Easy"
                case .medium: return "Medium"
                case .hard: return "Hard"
                }
            }
            
            var color: Color {
                switch self {
                case .easy: return .green
                case .medium: return .orange
                case .hard: return .red
                }
            }
        }
    }
    
    // MARK: - Seattle Activities Data
    
    static let seattleActivities: [ScavengerHuntActivity] = [
        
        // MARK: - Iconic Landmarks
        ScavengerHuntActivity(
            id: 1,
            name: "Space Needle Summit",
            description: "Seattle's most iconic landmark offering 360-degree views of the city",
            category: .iconicLandmarks,
            location: "400 Broad St, Seattle, WA 98109",
            coordinates: "47.6205,-122.3493",
            challenge: "Take a selfie with the Space Needle in the background from Kerry Park",
            points: 50,
            difficulty: .easy,
            timeEstimate: "1-2 hours",
            tips: ["Best views at sunset", "Book tickets in advance", "Visit the gift shop"],
            photoChallenge: "Capture the Space Needle with Mount Rainier in the background",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 2,
            name: "Pike Place Market Adventure",
            description: "The world's oldest continuously operating public market",
            category: .iconicLandmarks,
            location: "85 Pike St, Seattle, WA 98101",
            coordinates: "47.6097,-122.3331",
            challenge: "Find the original Starbucks and watch the fish throwing at Pike Place Fish",
            points: 40,
            difficulty: .easy,
            timeEstimate: "2-3 hours",
            tips: ["Visit early to avoid crowds", "Try the famous clam chowder", "Look for the gum wall"],
            photoChallenge: "Get a photo with the famous fish-throwing vendors",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 3,
            name: "Seattle Great Wheel",
            description: "Waterfront Ferris wheel with stunning city and water views",
            category: .iconicLandmarks,
            location: "1301 Alaskan Way, Seattle, WA 98101",
            coordinates: "47.6080,-122.3375",
            challenge: "Ride the Great Wheel and spot 3 different Seattle landmarks",
            points: 30,
            difficulty: .easy,
            timeEstimate: "30-45 minutes",
            tips: ["Best views on clear days", "Ride at sunset for amazing photos", "Check for special events"],
            photoChallenge: "Take a photo from the top of the wheel showing the city skyline",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Art & Culture
        ScavengerHuntActivity(
            id: 4,
            name: "Olympic Sculpture Park",
            description: "Outdoor sculpture park with works by renowned artists",
            category: .artCulture,
            location: "2901 Western Ave, Seattle, WA 98121",
            coordinates: "47.6163,-122.3556",
            challenge: "Find the 'Eagle' sculpture by Alexander Calder and take a creative photo",
            points: 35,
            difficulty: .medium,
            timeEstimate: "1-2 hours",
            tips: ["Free admission", "Great for walking", "Beautiful waterfront views", "Bring a camera"],
            photoChallenge: "Create an artistic photo with one of the sculptures and the water",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 5,
            name: "Chihuly Garden and Glass",
            description: "Stunning glass art installations by Dale Chihuly",
            category: .artCulture,
            location: "305 Harrison St, Seattle, WA 98109",
            coordinates: "47.6201,-122.3511",
            challenge: "Find the 'Glasshouse' installation and count how many glass pieces you can see",
            points: 45,
            difficulty: .medium,
            timeEstimate: "1-2 hours",
            tips: ["Book tickets online", "Visit during golden hour", "Don't miss the garden"],
            photoChallenge: "Capture the colorful glass art with natural lighting",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 6,
            name: "Seattle Art Museum",
            description: "Premier art museum featuring diverse collections",
            category: .artCulture,
            location: "1300 1st Ave, Seattle, WA 98101",
            coordinates: "47.6075,-122.3369",
            challenge: "Find the 'Hammering Man' sculpture and learn about its significance",
            points: 40,
            difficulty: .medium,
            timeEstimate: "2-3 hours",
            tips: ["Free first Thursday", "Check current exhibitions", "Visit the gift shop"],
            photoChallenge: "Take a photo with the Hammering Man sculpture",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Unique Neighborhoods
        ScavengerHuntActivity(
            id: 7,
            name: "Fremont Troll Hunt",
            description: "Find the famous troll sculpture under the Aurora Bridge",
            category: .neighborhoods,
            location: "N 36th St, Seattle, WA 98103",
            coordinates: "47.6509,-122.3473",
            challenge: "Take a photo with the troll and find the real Volkswagen Beetle it's holding",
            points: 35,
            difficulty: .easy,
            timeEstimate: "30 minutes",
            tips: ["Park nearby and walk", "Great for kids", "Visit nearby shops", "Check out the Sunday market"],
            photoChallenge: "Get a creative photo with the troll from an unusual angle",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 8,
            name: "Capitol Hill Arts Walk",
            description: "Explore Seattle's most vibrant arts district",
            category: .neighborhoods,
            location: "Capitol Hill, Seattle, WA",
            coordinates: "47.6205,-122.3212",
            challenge: "Find 3 different murals or street art pieces and photograph them",
            points: 40,
            difficulty: .medium,
            timeEstimate: "2-3 hours",
            tips: ["Best on weekends", "Visit local cafes", "Check out vintage shops", "Look for hidden art"],
            photoChallenge: "Create a collage of 3 different street art pieces",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Historical Sites
        ScavengerHuntActivity(
            id: 9,
            name: "Pioneer Square Underground Tour",
            description: "Explore Seattle's hidden underground tunnels",
            category: .historical,
            location: "614 1st Ave, Seattle, WA 98104",
            coordinates: "47.6021,-122.3337",
            challenge: "Take the underground tour and find the original street level markers",
            points: 60,
            difficulty: .hard,
            timeEstimate: "1.5 hours",
            tips: ["Book in advance", "Wear comfortable shoes", "Great for history buffs", "Check tour times"],
            photoChallenge: "Capture the contrast between old and new Seattle",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 10,
            name: "Klondike Gold Rush Museum",
            description: "Learn about Seattle's role in the gold rush",
            category: .historical,
            location: "319 2nd Ave S, Seattle, WA 98104",
            coordinates: "47.6006,-122.3331",
            challenge: "Find the gold panning demonstration and try your hand at it",
            points: 30,
            difficulty: .easy,
            timeEstimate: "1 hour",
            tips: ["Free admission", "Interactive exhibits", "Great for families", "Check hours"],
            photoChallenge: "Take a photo with the gold rush artifacts",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Natural Attractions
        ScavengerHuntActivity(
            id: 11,
            name: "Kerry Park Skyline View",
            description: "The best viewpoint for Seattle's skyline",
            category: .nature,
            location: "211 W Highland Dr, Seattle, WA 98119",
            coordinates: "47.6304,-122.3583",
            challenge: "Capture the perfect Seattle skyline photo with Mount Rainier visible",
            points: 50,
            difficulty: .medium,
            timeEstimate: "1 hour",
            tips: ["Best at sunset", "Limited parking", "Popular spot", "Bring a tripod"],
            photoChallenge: "Get the iconic Seattle skyline shot with Space Needle and Mount Rainier",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 12,
            name: "Ballard Locks Engineering Marvel",
            description: "Watch boats navigate between Puget Sound and Lake Union",
            category: .nature,
            location: "3015 NW 54th St, Seattle, WA 98107",
            coordinates: "47.6681,-122.3962",
            challenge: "Watch a boat go through the locks and spot the salmon ladder",
            points: 35,
            difficulty: .easy,
            timeEstimate: "1-2 hours",
            tips: ["Free to visit", "Best during salmon season", "Great for kids", "Check the fish ladder"],
            photoChallenge: "Capture a boat going through the locks",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 13,
            name: "Seattle Japanese Garden",
            description: "Serene traditional Japanese garden in the heart of the city",
            category: .nature,
            location: "1075 Lake Washington Blvd E, Seattle, WA 98112",
            coordinates: "47.5847,-122.3019",
            challenge: "Find the koi pond and count the different colored fish",
            points: 30,
            difficulty: .easy,
            timeEstimate: "1-2 hours",
            tips: ["Small admission fee", "Best in spring/fall", "Peaceful setting", "Photography allowed"],
            photoChallenge: "Capture the reflection of the garden in the koi pond",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Culinary Delights
        ScavengerHuntActivity(
            id: 14,
            name: "Pike Place Chowder Quest",
            description: "Find and taste Seattle's famous clam chowder",
            category: .food,
            location: "1530 Post Alley, Seattle, WA 98101",
            coordinates: "47.6097,-122.3331",
            challenge: "Try the award-winning clam chowder and find the secret ingredient",
            points: 40,
            difficulty: .easy,
            timeEstimate: "1 hour",
            tips: ["Long lines but worth it", "Try the bread bowl", "Check their awards", "Take photos"],
            photoChallenge: "Get a photo with your chowder and the market in the background",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 15,
            name: "Uwajimaya Market Adventure",
            description: "Explore Seattle's premier Asian supermarket",
            category: .food,
            location: "600 5th Ave S, Seattle, WA 98104",
            coordinates: "47.5981,-122.3281",
            challenge: "Find 3 unique items you've never seen before and try one",
            points: 35,
            difficulty: .medium,
            timeEstimate: "1-2 hours",
            tips: ["Great for unique snacks", "Try the food court", "Check out the bookstore", "Look for seasonal items"],
            photoChallenge: "Take a photo with the most interesting item you found",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 16,
            name: "Seattle Coffee Culture",
            description: "Visit the original Starbucks and discover local roasters",
            category: .food,
            location: "1912 Pike Pl, Seattle, WA 98101",
            coordinates: "47.6097,-122.3331",
            challenge: "Compare the original Starbucks with a local Seattle roastery",
            points: 45,
            difficulty: .medium,
            timeEstimate: "2-3 hours",
            tips: ["Original Starbucks is small", "Try local roasters", "Check out the coffee museum", "Take the coffee tour"],
            photoChallenge: "Get a photo with your coffee at both locations",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Spooky Spots
        ScavengerHuntActivity(
            id: 17,
            name: "Kells Irish Pub Ghost Hunt",
            description: "Visit the former mortuary turned pub with ghostly history",
            category: .spooky,
            location: "1916 Post Alley, Seattle, WA 98101",
            coordinates: "47.6097,-122.3331",
            challenge: "Order a drink and listen for ghost stories from the staff",
            points: 50,
            difficulty: .medium,
            timeEstimate: "1-2 hours",
            tips: ["Great atmosphere", "Ask about the history", "Try the Irish food", "Check for ghost tours"],
            photoChallenge: "Take a photo in the most atmospheric corner of the pub",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 18,
            name: "Hotel Sorrento Investigation",
            description: "Explore the haunted reputation of this historic hotel",
            category: .spooky,
            location: "900 Madison St, Seattle, WA 98104",
            coordinates: "47.6101,-122.3297",
            challenge: "Take a photo in the lobby and see if you can spot anything unusual",
            points: 40,
            difficulty: .medium,
            timeEstimate: "1 hour",
            tips: ["Beautiful historic hotel", "Ask about ghost stories", "Check out the bar", "Look for paranormal activity"],
            photoChallenge: "Capture the historic elegance of the hotel lobby",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Outdoor Adventures
        ScavengerHuntActivity(
            id: 19,
            name: "Discovery Park Lighthouse Hike",
            description: "Hike to Seattle's only lighthouse with stunning views",
            category: .outdoor,
            location: "3801 Discovery Park Blvd, Seattle, WA 98199",
            coordinates: "47.6624,-122.4060",
            challenge: "Hike to the lighthouse and spot 5 different types of birds",
            points: 60,
            difficulty: .hard,
            timeEstimate: "2-3 hours",
            tips: ["Wear good walking shoes", "Bring water", "Check tide times", "Great for photography"],
            photoChallenge: "Capture the lighthouse with the Olympic Mountains in the background",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 20,
            name: "Gas Works Park Sunset",
            description: "Watch the sunset from this unique park with industrial history",
            category: .outdoor,
            location: "2101 N Northlake Way, Seattle, WA 98103",
            coordinates: "47.6458,-122.3360",
            challenge: "Find the best spot to watch the sunset and capture the city skyline",
            points: 45,
            difficulty: .medium,
            timeEstimate: "1-2 hours",
            tips: ["Popular sunset spot", "Great for picnics", "Check the weather", "Bring a blanket"],
            photoChallenge: "Get the perfect sunset shot with the city skyline",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Hidden Gems
        ScavengerHuntActivity(
            id: 21,
            name: "Gum Wall Discovery",
            description: "Find Seattle's famous (and sticky) gum wall",
            category: .hiddenGems,
            location: "Post Alley, Seattle, WA 98101",
            coordinates: "47.6097,-122.3331",
            challenge: "Find the gum wall and add your own piece (safely!)",
            points: 25,
            difficulty: .easy,
            timeEstimate: "30 minutes",
            tips: ["It's sticky!", "Great for photos", "Check nearby shops", "Look for the market"],
            photoChallenge: "Take a creative photo with the colorful gum wall",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 22,
            name: "Seattle Central Library Architecture",
            description: "Marvel at the unique architecture of this modern library",
            category: .hiddenGems,
            location: "1000 4th Ave, Seattle, WA 98104",
            coordinates: "47.6082,-122.3321",
            challenge: "Find the 'Red Floor' and take a photo in the unique reading room",
            points: 35,
            difficulty: .medium,
            timeEstimate: "1-2 hours",
            tips: ["Free to visit", "Amazing architecture", "Check out the book spiral", "Great for photos"],
            photoChallenge: "Capture the unique geometric patterns of the library interior",
            isCompleted: false,
            completedAt: nil
        ),
        
        // MARK: - Waterfront Wonders
        ScavengerHuntActivity(
            id: 23,
            name: "Seattle Aquarium Marine Life",
            description: "Discover the underwater world of the Pacific Northwest",
            category: .waterfront,
            location: "1483 Alaskan Way, Seattle, WA 98101",
            coordinates: "47.6080,-122.3375",
            challenge: "Find the giant Pacific octopus and learn about its intelligence",
            points: 40,
            difficulty: .easy,
            timeEstimate: "2-3 hours",
            tips: ["Great for families", "Check feeding times", "Interactive exhibits", "Gift shop"],
            photoChallenge: "Get a photo with the sea otters or octopus",
            isCompleted: false,
            completedAt: nil
        ),
        
        ScavengerHuntActivity(
            id: 24,
            name: "Alki Beach Walk",
            description: "Walk along Seattle's most popular beach with city views",
            category: .waterfront,
            location: "1702 Alki Ave SW, Seattle, WA 98116",
            coordinates: "47.5805,-122.4090",
            challenge: "Walk the entire beach and spot 3 different types of boats",
            points: 35,
            difficulty: .easy,
            timeEstimate: "1-2 hours",
            tips: ["Great for walking", "Check the weather", "Look for sea life", "Visit the lighthouse"],
            photoChallenge: "Capture the beach with the Seattle skyline in the distance",
            isCompleted: false,
            completedAt: nil
        )
    ]
    
    // MARK: - Scavenger Hunt Progress Tracking
    
    struct ScavengerHuntProgress: Codable {
        var completedActivities: Set<Int> = []
        var totalPoints: Int = 0
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var categoriesCompleted: Set<ScavengerHuntCategory> = []
        var startDate: Date = Date()
        var lastActivityDate: Date?
        
        var completionPercentage: Double {
            let total = SeattleScavengerHunt.seattleActivities.count
            return Double(completedActivities.count) / Double(total) * 100
        }
        
        var pointsByCategory: [ScavengerHuntCategory: Int] {
            var points: [ScavengerHuntCategory: Int] = [:]
            for category in ScavengerHuntCategory.allCases {
                points[category] = 0
            }
            
            for activityId in completedActivities {
                if let activity = SeattleScavengerHunt.seattleActivities.first(where: { $0.id == activityId }) {
                    points[activity.category, default: 0] += activity.points
                }
            }
            
            return points
        }
    }
    
    // MARK: - Scavenger Hunt Achievements
    
    enum ScavengerHuntAchievement: String, CaseIterable {
        case firstActivity = "first_activity"
        case categoryExplorer = "category_explorer"
        case pointCollector = "point_collector"
        case photoMaster = "photo_master"
        case seattleExpert = "seattle_expert"
        case completionist = "completionist"
        
        var displayName: String {
            switch self {
            case .firstActivity: return "First Steps"
            case .categoryExplorer: return "Category Explorer"
            case .pointCollector: return "Point Collector"
            case .photoMaster: return "Photo Master"
            case .seattleExpert: return "Seattle Expert"
            case .completionist: return "Completionist"
            }
        }
        
        var description: String {
            switch self {
            case .firstActivity: return "Complete your first activity"
            case .categoryExplorer: return "Complete activities in 5 different categories"
            case .pointCollector: return "Earn 500 points"
            case .photoMaster: return "Complete 10 photo challenges"
            case .seattleExpert: return "Complete 15 activities"
            case .completionist: return "Complete all 24 activities"
            }
        }
        
        var icon: String {
            switch self {
            case .firstActivity: return "star.fill"
            case .categoryExplorer: return "map.fill"
            case .pointCollector: return "star.circle.fill"
            case .photoMaster: return "camera.fill"
            case .seattleExpert: return "building.2.fill"
            case .completionist: return "trophy.fill"
            }
        }
    }
    
    // MARK: - Helper Functions
    
    static func getActivitiesByCategory(_ category: ScavengerHuntCategory) -> [ScavengerHuntActivity] {
        return seattleActivities.filter { $0.category == category }
    }
    
    static func getRandomActivity() -> ScavengerHuntActivity? {
        return seattleActivities.randomElement()
    }
    
    static func getActivitiesByDifficulty(_ difficulty: ScavengerHuntActivity.Difficulty) -> [ScavengerHuntActivity] {
        return seattleActivities.filter { $0.difficulty == difficulty }
    }
    
    static func getNearbyActivities(latitude: Double, longitude: Double, radius: Double = 1.0) -> [ScavengerHuntActivity] {
        // This would implement location-based filtering
        // For now, return all activities
        return seattleActivities
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


