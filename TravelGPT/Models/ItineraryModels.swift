import Foundation
import SwiftUI

// MARK: - Itinerary Models

struct TravelItinerary: Identifiable, Codable {
    let id: Int
    let title: String
    let destination_city: String
    let start_date: String
    let end_date: String
    let total_days: Int
    let ai_summary: String
    let itinerary_data: [ItineraryDay]
    let recommendations: [String]
    let created_at: String?
    
    // Computed properties for display
    var formattedStartDate: String {
        formatDate(start_date)
    }
    
    var formattedEndDate: String {
        formatDate(end_date)
    }
    
    var dateRange: String {
        "\(formattedStartDate) - \(formattedEndDate)"
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct ItineraryDay: Identifiable, Codable {
    let day: Int
    let date: String
    let theme: String
    let activities: [ItineraryActivity]
    let meals: [ItineraryMeal]
    let notes: String?
    
    var id: Int { day }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: date) {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
        return date
    }
}

struct ItineraryActivity: Identifiable, Codable {
    let time: String
    let activity: String
    let location: String
    let duration: String
    let description: String
    let priority: String?
    
    var id: String { "\(time)-\(activity)" }
    
    var priorityEnum: WishlistPriority? {
        guard let priority = priority else { return nil }
        return WishlistPriority(rawValue: priority)
    }
    
    var formattedTime: String {
        // Convert 24-hour format to 12-hour format
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let time = formatter.date(from: time) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: time)
        }
        return time
    }
}

struct ItineraryMeal: Identifiable, Codable {
    let time: String
    let type: String
    let suggestion: String
    
    var id: String { "\(time)-\(type)" }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let time = formatter.date(from: time) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: time)
        }
        return time
    }
    
    var mealIcon: String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "cup.and.saucer.fill"
        default: return "fork.knife"
        }
    }
    
    var mealColor: Color {
        switch type.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .blue
        }
    }
}

// MARK: - Request Models

struct GenerateItineraryRequest: Codable {
    let destination_city: String
    let start_date: String
    let end_date: String
    let travel_style: TravelStyle
    let max_activities_per_day: Int
    let include_must_do: Bool
    let include_sounds_fun: Bool
    let include_maybe: Bool
    let additional_notes: String?
    
    init(destination_city: String, start_date: String, end_date: String, 
         travel_style: TravelStyle = .moderate, max_activities_per_day: Int = 3,
         include_must_do: Bool = true, include_sounds_fun: Bool = true, 
         include_maybe: Bool = false, additional_notes: String? = nil) {
        self.destination_city = destination_city
        self.start_date = start_date
        self.end_date = end_date
        self.travel_style = travel_style
        self.max_activities_per_day = max_activities_per_day
        self.include_must_do = include_must_do
        self.include_sounds_fun = include_sounds_fun
        self.include_maybe = include_maybe
        self.additional_notes = additional_notes
    }
}

enum TravelStyle: String, CaseIterable, Codable {
    case relaxed = "relaxed"
    case moderate = "moderate"
    case packed = "packed"
    case adventure = "adventure"
    case cultural = "cultural"
    case foodie = "foodie"
    
    var displayName: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .moderate: return "Moderate"
        case .packed: return "Packed"
        case .adventure: return "Adventure"
        case .cultural: return "Cultural"
        case .foodie: return "Foodie"
        }
    }
    
    var description: String {
        switch self {
        case .relaxed: return "Leisurely exploration with lots of downtime"
        case .moderate: return "Balanced mix of activities and relaxation"
        case .packed: return "Maximum sightseeing with minimal breaks"
        case .adventure: return "Outdoor activities and nature-focused"
        case .cultural: return "Museums, history, and educational experiences"
        case .foodie: return "Culinary experiences and food tours"
        }
    }
    
    var icon: String {
        switch self {
        case .relaxed: return "leaf.fill"
        case .moderate: return "balance.scale.fill"
        case .packed: return "bolt.fill"
        case .adventure: return "mountain.2.fill"
        case .cultural: return "book.fill"
        case .foodie: return "fork.knife"
        }
    }
    
    var color: Color {
        switch self {
        case .relaxed: return .green
        case .moderate: return .blue
        case .packed: return .red
        case .adventure: return .orange
        case .cultural: return .purple
        case .foodie: return .pink
        }
    }
    
    var activitiesPerDay: Int {
        switch self {
        case .relaxed: return 2
        case .moderate: return 3
        case .packed: return 5
        case .adventure: return 3
        case .cultural: return 3
        case .foodie: return 3
        }
    }
}

// MARK: - Response Models

struct GenerateItineraryResponse: Codable {
    let id: Int
    let title: String
    let destination_city: String
    let start_date: String
    let end_date: String
    let total_days: Int
    let ai_summary: String
    let itinerary_data: [ItineraryDay]
    let recommendations: [String]
}

struct ItinerariesResponse: Codable {
    let results: [TravelItinerary]
    let count: Int
    let next: Bool?
    let previous: Bool?
}

