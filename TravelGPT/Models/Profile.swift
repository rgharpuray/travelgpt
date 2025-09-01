import Foundation

struct Profile: Codable {
    // New API fields (current)
    let total_cards: Int?
    let total_likes: Int?
    var destination_name: String?
    var profile_image_url: String?
    let is_premium: Bool?
    let blocked_users_count: Int?
    
    // Personality and breed fields
    let personality_categories: [String]?
    let breed: String?
    
    // Old API fields (for backward compatibility)
    let device_id: String?
    let cards_generated_normal: Int?
    let cards_generated_intrusive: Int?
    let date_joined: String?
    
    // Computed properties for consistent access
    var totalCards: Int {
        return total_cards ?? cards_generated_normal ?? 0
    }
    
    var totalLikes: Int {
        return total_likes ?? 0
    }
    
    var isPremium: Bool {
        return is_premium ?? false
    }
    
    var deviceId: String {
        return device_id ?? DeviceIDService.shared.getOrCreateDeviceID()
    }
    
    var cardsGeneratedNormal: Int {
        return cards_generated_normal ?? total_cards ?? 0
    }
    
    var cardsGeneratedIntrusive: Int {
        return cards_generated_intrusive ?? 0
    }
    
    var blockedUsersCount: Int {
        return blocked_users_count ?? 0
    }
    
    var dateJoined: String {
        return date_joined ?? ISO8601DateFormatter().string(from: Date())
    }
    
    var personalityCategories: [String] {
        return personality_categories ?? []
    }
    
    var dogBreed: String {
        return breed ?? ""
    }
    
    // Custom initializer for creating profiles with updated data
    init(total_cards: Int?, total_likes: Int?, destination_name: String?, profile_image_url: String?, is_premium: Bool?, blocked_users_count: Int?, personality_categories: [String]?, breed: String?, device_id: String?, cards_generated_normal: Int?, cards_generated_intrusive: Int?, date_joined: String?) {
        self.total_cards = total_cards
        self.total_likes = total_likes
        self.destination_name = destination_name
        self.profile_image_url = profile_image_url
        self.is_premium = is_premium
        self.blocked_users_count = blocked_users_count
        self.personality_categories = personality_categories
        self.breed = breed
        self.device_id = device_id
        self.cards_generated_normal = cards_generated_normal
        self.cards_generated_intrusive = cards_generated_intrusive
        self.date_joined = date_joined
    }
    
    // Custom initializer for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode new API fields first
        total_cards = try container.decodeIfPresent(Int.self, forKey: .total_cards)
        total_likes = try container.decodeIfPresent(Int.self, forKey: .total_likes)
        var decodedPetName = try container.decodeIfPresent(String.self, forKey: .destination_name)
        var decodedProfileImageUrl = try container.decodeIfPresent(String.self, forKey: .profile_image_url)
        is_premium = try container.decodeIfPresent(Bool.self, forKey: .is_premium)
        blocked_users_count = try container.decodeIfPresent(Int.self, forKey: .blocked_users_count)
        
        // Personality and breed fields
        personality_categories = try container.decodeIfPresent([String].self, forKey: .personality_categories)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        
        // Try to decode old API fields for backward compatibility
        device_id = try container.decodeIfPresent(String.self, forKey: .device_id)
        cards_generated_normal = try container.decodeIfPresent(Int.self, forKey: .cards_generated_normal)
        cards_generated_intrusive = try container.decodeIfPresent(Int.self, forKey: .cards_generated_intrusive)
        date_joined = try container.decodeIfPresent(String.self, forKey: .date_joined)
        
        // Assign to var properties
        self.destination_name = decodedPetName
        self.profile_image_url = decodedProfileImageUrl
    }
    
    // Custom encoding to ensure we save in the new format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(totalCards, forKey: .total_cards)
        try container.encodeIfPresent(totalLikes, forKey: .total_likes)
        try container.encodeIfPresent(destination_name, forKey: .destination_name)
        try container.encodeIfPresent(profile_image_url, forKey: .profile_image_url)
        try container.encodeIfPresent(isPremium, forKey: .is_premium)
        try container.encodeIfPresent(blockedUsersCount, forKey: .blocked_users_count)
        try container.encodeIfPresent(personalityCategories, forKey: .personality_categories)
        try container.encodeIfPresent(dogBreed, forKey: .breed)
    }
    
    private enum CodingKeys: String, CodingKey {
        case total_cards, total_likes, destination_name, profile_image_url, is_premium, blocked_users_count
        case personality_categories, breed
        case device_id, cards_generated_normal, cards_generated_intrusive, date_joined
    }
} 