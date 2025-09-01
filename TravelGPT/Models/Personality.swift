import Foundation
import SwiftUI

// MARK: - Personality System

struct Subpersonality: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let emoji: String
}

struct Personality: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: PersonalityType
    let subpersonalities: [Subpersonality]
    let color: PersonalityColor
    let emoji: String
    
    static let allPersonalities: [Personality] = [
        // 1. The Chaos Crew
        Personality(
            id: "chaos_crew",
            name: "The Chaos Crew",
            description: "High-energy, unpredictable pups who bring excitement and mayhem to every moment.",
            category: .chaos,
            subpersonalities: [
                Subpersonality(id: "spitfire", name: "The Spitfire", description: "Midnight zoomie champion", emoji: "⚡"),
                Subpersonality(id: "zoomie_comet", name: "The Zoomie Comet", description: "Mach 3, no destination", emoji: "🚀"),
                Subpersonality(id: "chaos_intern", name: "The Chaos Intern", description: "Boundless energy, zero strategy", emoji: "🌀"),
                Subpersonality(id: "doorbell_sprinter", name: "The Doorbell Sprinter", description: "Teleports to the front door before the chime finishes", emoji: "🏃‍♂️"),
                Subpersonality(id: "parkour_pup", name: "The Parkour Pup", description: "Rebounds off furniture like a caffeinated squirrel", emoji: "🤸‍♂️"),
                Subpersonality(id: "drama_sprinter", name: "The Drama Sprinter", description: "Runs to the door, realizes no one's there, sighs dramatically", emoji: "🎭"),
                Subpersonality(id: "helicopter_tail", name: "The Helicopter Tail", description: "Tail propeller strong enough to generate wind", emoji: "🚁")
            ],
            color: .orange,
            emoji: "⚡"
        ),
        
        // 2. The Cuddle & Comfort Department
        Personality(
            id: "cuddle_comfort",
            name: "The Cuddle & Comfort Department",
            description: "Affectionate, emotional support experts who specialize in love and comfort.",
            category: .cuddle,
            subpersonalities: [
                Subpersonality(id: "velcro_cuddler", name: "The Velcro Cuddler", description: "Can't be more than 3 inches away", emoji: "🫂"),
                Subpersonality(id: "professional_therapist", name: "The Professional Therapist", description: "Snout nudges in times of crisis", emoji: "🧠"),
                Subpersonality(id: "weighted_blanket", name: "The Weighted Blanket", description: "Sits directly on you for hours", emoji: "🛏️"),
                Subpersonality(id: "eye_contact_healer", name: "The Eye Contact Healer", description: "Stares into your soul with pure love", emoji: "👁️"),
                Subpersonality(id: "gentle_pillow", name: "The Gentle Pillow", description: "Carefully rests head on you like you're royalty", emoji: "👑"),
                Subpersonality(id: "loyal_shadow", name: "The Loyal Shadow", description: "Follows you from room to room like a bodyguard", emoji: "👥")
            ],
            color: .pink,
            emoji: "🫂"
        ),
        
        // 3. The Food-Obsessed Union
        Personality(
            id: "food_obsessed",
            name: "The Food-Obsessed Union",
            description: "Snack schemers and kitchen lurkers who live for the next treat.",
            category: .food,
            subpersonalities: [
                Subpersonality(id: "snack_bandit", name: "The Snack Bandit", description: "Can hear a chip bag from two blocks away", emoji: "🥨"),
                Subpersonality(id: "sock_sommelier", name: "The Sock Sommelier", description: "Refined taste for laundry 'vintage'", emoji: "🧦"),
                Subpersonality(id: "crumb_inspector", name: "The Crumb Inspector", description: "Eats anything that hits the floor in 0.2 seconds", emoji: "🔍"),
                Subpersonality(id: "treat_accountant", name: "The Treat Accountant", description: "Remembers exactly how many you've given… and when", emoji: "📊"),
                Subpersonality(id: "kitchen_supervisor", name: "The Kitchen Supervisor", description: "Stares up during cooking like an unpaid sous chef", emoji: "👨‍🍳"),
                Subpersonality(id: "trash_panda_diplomat", name: "The Trash Panda Diplomat", description: "'Liberates' garbage with surgical precision", emoji: "🦝")
            ],
            color: .yellow,
            emoji: "🍖"
        ),
        
        // 4. The Socialites & Extroverts
        Personality(
            id: "socialites_extroverts",
            name: "The Socialites & Extroverts",
            description: "Outgoing, friendly show-offs who make friends everywhere they go.",
            category: .social,
            subpersonalities: [
                Subpersonality(id: "social_butterfly", name: "The Social Butterfly", description: "Makes friends with every living creature", emoji: "🦋"),
                Subpersonality(id: "neighborhood_mayor", name: "The Neighborhood Mayor", description: "Knows all the gossip via sniff intel", emoji: "🏛️"),
                Subpersonality(id: "flirt", name: "The Flirt", description: "Shamelessly leans on strangers for pets", emoji: "💕"),
                Subpersonality(id: "tail_wag_influencer", name: "The Tail Wag Influencer", description: "Poses like they're building a personal brand", emoji: "📸"),
                Subpersonality(id: "barkaholic", name: "The Barkaholic", description: "Contributes to every conversation", emoji: "🗣️"),
                Subpersonality(id: "meet_greet_marathoner", name: "The Meet & Greet Marathoner", description: "Still greeting guests 45 minutes later", emoji: "🏃‍♀️")
            ],
            color: .blue,
            emoji: "🌟"
        ),
        
        // 5. The Drama & Sass League
        Personality(
            id: "drama_sass",
            name: "The Drama & Sass League",
            description: "Expressive, stubborn, theatrical pups with attitude to spare.",
            category: .drama,
            subpersonalities: [
                Subpersonality(id: "sass_master", name: "The Sass Master", description: "Sighs like you've ruined their week", emoji: "😤"),
                Subpersonality(id: "drama_queen", name: "The Drama Queen", description: "Yelps if you think about stepping on their tail", emoji: "👑"),
                Subpersonality(id: "moody_teen", name: "The Moody Teen", description: "Obeys only if it suits them", emoji: "😒"),
                Subpersonality(id: "side_eye_judge", name: "The Side-Eye Judge", description: "Silently disapproves of your life choices", emoji: "👀"),
                Subpersonality(id: "sock_lawyer", name: "The Sock Lawyer", description: "Argues possession of stolen laundry", emoji: "⚖️"),
                Subpersonality(id: "bark_lawyer", name: "The Bark Lawyer", description: "Objects to everything you say", emoji: "📢")
            ],
            color: .purple,
            emoji: "🎭"
        ),
        
        // 6. The Oddballs & Daydreamers
        Personality(
            id: "oddballs_daydreamers",
            name: "The Oddballs & Daydreamers",
            description: "Quirky, strange habits that make them uniquely lovable.",
            category: .oddball,
            subpersonalities: [
                Subpersonality(id: "derpy_philosopher", name: "The Derpy Philosopher", description: "Contemplates walls for hours", emoji: "🤔"),
                Subpersonality(id: "wannabe_cat", name: "The Wannabe Cat", description: "Climbs to weird perches just to stare", emoji: "🐱"),
                Subpersonality(id: "mystery_napper", name: "The Mystery Napper", description: "Disappears and reappears in random spots", emoji: "👻"),
                Subpersonality(id: "invisible_squirrel_chaser", name: "The Invisible Squirrel Chaser", description: "Sprints after… nothing", emoji: "🏃‍♂️"),
                Subpersonality(id: "ghost_tracker", name: "The Ghost Tracker", description: "Barks at corners like they see spirits", emoji: "👻"),
                Subpersonality(id: "cloud_watcher", name: "The Cloud Watcher", description: "Lies on back and watches the sky", emoji: "☁️")
            ],
            color: .green,
            emoji: "🌈"
        ),
        
        // 7. The Planners & Plotters
        Personality(
            id: "planners_plotters",
            name: "The Planners & Plotters",
            description: "Calculated mischief and clever thinkers who always have a plan.",
            category: .planner,
            subpersonalities: [
                Subpersonality(id: "plotter", name: "The Plotter", description: "Sits quietly, calculating treat heist", emoji: "🧠"),
                Subpersonality(id: "door_strategist", name: "The Door Strategist", description: "Waits for the exact moment you open it", emoji: "🚪"),
                Subpersonality(id: "escape_artist", name: "The Escape Artist", description: "Can slip collars and baby gates with ease", emoji: "🎪"),
                Subpersonality(id: "toy_hoarder", name: "The Toy Hoarder", description: "Collects all toys into one secret stash", emoji: "🏴‍☠️"),
                Subpersonality(id: "bed_negotiator", name: "The Bed Negotiator", description: "Slowly expands their territory each night", emoji: "🛏️"),
                Subpersonality(id: "squirrel_economist", name: "The Squirrel Economist", description: "'Invests' bones in multiple dig sites", emoji: "💰")
            ],
            color: .red,
            emoji: "🎯"
        ),
        
        // 8. The Low-Energy Legends
        Personality(
            id: "low_energy_legends",
            name: "The Low-Energy Legends",
            description: "Chill, lazy pups who live the slow life and love their naps.",
            category: .chill,
            subpersonalities: [
                Subpersonality(id: "potato", name: "The Potato", description: "Considers movement a personal insult", emoji: "🥔"),
                Subpersonality(id: "couch_politician", name: "The Couch Politician", description: "Rules from their throne", emoji: "👑"),
                Subpersonality(id: "sunny_spot_specialist", name: "The Sunny Spot Specialist", description: "Naps wherever the light hits", emoji: "☀️"),
                Subpersonality(id: "olympic_napper", name: "The Olympic Napper", description: "Sleeps through any apocalypse", emoji: "😴"),
                Subpersonality(id: "selective_fetcher", name: "The Selective Fetcher", description: "Only chases balls they like", emoji: "🎾"),
                Subpersonality(id: "retired_athlete", name: "The Retired Athlete", description: "Still limps for sympathy snacks", emoji: "🏃‍♂️"),
                Subpersonality(id: "blanket_burrito", name: "The Blanket Burrito", description: "Wraps self so tightly they can't move", emoji: "🌯")
            ],
            color: .teal,
            emoji: "😌"
        )
    ]
}

enum PersonalityType: String, CaseIterable, Codable {
    case chaos = "chaos"
    case cuddle = "cuddle"
    case food = "food"
    case social = "social"
    case drama = "drama"
    case oddball = "oddball"
    case planner = "planner"
    case chill = "chill"
    
    var displayName: String {
        switch self {
        case .chaos: return "Chaos"
        case .cuddle: return "Cuddle"
        case .food: return "Food"
        case .social: return "Social"
        case .drama: return "Drama"
        case .oddball: return "Oddball"
        case .planner: return "Planner"
        case .chill: return "Chill"
        }
    }
}

enum PersonalityColor: String, CaseIterable, Codable {
    case orange = "orange"
    case pink = "pink"
    case yellow = "yellow"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case red = "red"
    case teal = "teal"
    
    var color: Color {
        switch self {
        case .orange: return Color.orange
        case .pink: return Color.pink
        case .yellow: return Color.yellow
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .green: return Color.green
        case .red: return Color.red
        case .teal: return Color.teal
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .orange: return LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pink: return LinearGradient(colors: [.pink, .pink.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .yellow: return LinearGradient(colors: [.yellow, .yellow.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue: return LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple: return LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green: return LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .red: return LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .teal: return LinearGradient(colors: [.teal, .teal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Pet Profile with Personality
struct PetProfile: Codable {
    var name: String
    var imageUrl: String?
    var personality: Personality?
    var subpersonality: Subpersonality?
    var personalityImageUrl: String?
    var aiAvatarUrl: String?
    
    init(name: String, imageUrl: String? = nil) {
        self.name = name
        self.imageUrl = imageUrl
    }
}

// MARK: - Personality Store
@MainActor
class PersonalityStore: ObservableObject {
    @Published var selectedPersonality: Personality?
    @Published var selectedSubpersonality: Subpersonality?
    @Published var personalityImageUrl: String?
    @Published var aiAvatarUrl: String?
    
    func generatePersonalityImage(for personality: Personality) async {
        // For now, we'll use placeholder images
        // In a real implementation, this would call an AI image generation service
        personalityImageUrl = "personality_\(personality.id)"
    }
    
    func generateAIAvatar(for pet: PetProfile) async {
        // For now, we'll use placeholder images
        // In a real implementation, this would call an AI image generation service
        aiAvatarUrl = "avatar_\(pet.name)_\(pet.personality?.id ?? "unknown")"
    }
}


