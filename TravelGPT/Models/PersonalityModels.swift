import Foundation

// MARK: - Onboarding Options
struct OnboardingOptions: Codable {
    let categories: [PersonalityCategory]
    let popularBreeds: [String]
    
    enum CodingKeys: String, CodingKey {
        case categories
        case popularBreeds = "popular_breeds"
    }
}

// MARK: - Personality Category
struct PersonalityCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    
    var isSelected: Bool = false
}

// MARK: - Onboarding Request
struct OnboardingRequest: Codable {
    let personalityCategories: [String]
    let breed: String?
    
    enum CodingKeys: String, CodingKey {
        case personalityCategories = "personality_categories"
        case breed
    }
}

// MARK: - Onboarding Response
struct OnboardingResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Personality Category Definitions
struct PersonalityCategories {
    static let allCategories: [PersonalityCategory] = [
        PersonalityCategory(
            id: "chaos_crew",
            name: "The Chaos Crew",
            description: "High-energy, unpredictable"
        ),
        PersonalityCategory(
            id: "cuddle_comfort",
            name: "The Cuddle & Comfort Department",
            description: "Affectionate, emotional support"
        ),
        PersonalityCategory(
            id: "food_obsessed",
            name: "The Food-Obsessed Union",
            description: "Snack schemers, kitchen lurkers"
        ),
        PersonalityCategory(
            id: "socialites_extroverts",
            name: "The Socialites & Extroverts",
            description: "Outgoing, friendly, show-offs"
        ),
        PersonalityCategory(
            id: "drama_sass",
            name: "The Drama & Sass League",
            description: "Expressive, stubborn, theatrical"
        ),
        PersonalityCategory(
            id: "oddballs_daydreamers",
            name: "The Oddballs & Daydreamers",
            description: "Quirky, strange habits"
        ),
        PersonalityCategory(
            id: "planners_plotters",
            name: "The Planners & Plotters",
            description: "Calculated mischief, clever thinkers"
        ),
        PersonalityCategory(
            id: "low_energy_legends",
            name: "The Low-Energy Legends",
            description: "Chill, lazy, living slow life"
        )
    ]
    
    static let popularBreeds: [String] = [
        "Golden Retriever",
        "Labrador Retriever",
        "German Shepherd",
        "Bulldog",
        "Beagle",
        "Poodle",
        "Rottweiler",
        "Yorkshire Terrier",
        "Boxer",
        "Dachshund",
        "Great Dane",
        "Doberman",
        "Shih Tzu",
        "Siberian Husky",
        "Chihuahua",
        "Pomeranian",
        "Cavalier King Charles Spaniel",
        "Bernese Mountain Dog",
        "Border Collie",
        "Australian Shepherd",
        "Corgi",
        "French Bulldog",
        "Pug",
        "Maltese",
        "Newfoundland",
        "Saint Bernard",
        "Alaskan Malamute",
        "Samoyed",
        "Chow Chow",
        "Akita",
        "Mixed Breed",
        "Other"
    ]
} 