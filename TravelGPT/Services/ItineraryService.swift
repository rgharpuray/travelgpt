import Foundation
import UIKit

class ItineraryService: ObservableObject {
    static let shared = ItineraryService()
    
    private let baseURL = Config.apiBaseURL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Generate Itinerary
    
    func generateItinerary(request: GenerateItineraryRequest) async throws -> TravelItinerary {
        // For now, return a mock itinerary since the backend API might not be ready
        // TODO: Replace with actual API call when backend is ready
        return try await generateMockItinerary(request: request)
    }
    
    private func generateMockItinerary(request: GenerateItineraryRequest) async throws -> TravelItinerary {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDate = dateFormatter.date(from: request.start_date) ?? Date()
        let endDate = dateFormatter.date(from: request.end_date) ?? Date()
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        
        var itineraryDays: [ItineraryDay] = []
        
        for day in 1...days {
            let currentDate = calendar.date(byAdding: .day, value: day - 1, to: startDate) ?? startDate
            let dateString = dateFormatter.string(from: currentDate)
            
            let activities = generateMockActivities(for: day, style: request.travel_style, destination: request.destination_city)
            let meals = generateMockMeals(for: day)
            
            let day = ItineraryDay(
                day: day,
                date: dateString,
                theme: getDayTheme(for: day, style: request.travel_style),
                activities: activities,
                meals: meals,
                notes: day == 1 ? "Start your adventure early to make the most of your time!" : nil
            )
            
            itineraryDays.append(day)
        }
        
        return TravelItinerary(
            id: Int.random(in: 1...1000),
            title: "\(days)-Day \(request.destination_city) Adventure",
            destination_city: request.destination_city,
            start_date: request.start_date,
            end_date: request.end_date,
            total_days: days,
            ai_summary: "A \(request.travel_style.displayName.lowercased()) \(days)-day adventure in \(request.destination_city). This itinerary is designed to give you the perfect balance of must-see attractions and local experiences, tailored to your \(request.travel_style.displayName.lowercased()) travel style.",
            itinerary_data: itineraryDays,
            recommendations: [
                "Book accommodations in advance",
                "Check local transportation options",
                "Download offline maps",
                "Pack comfortable walking shoes",
                "Try local cuisine at recommended restaurants"
            ],
            created_at: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func generateMockActivities(for day: Int, style: TravelStyle, destination: String) -> [ItineraryActivity] {
        let activitiesPerDay = style.activitiesPerDay
        var activities: [ItineraryActivity] = []
        
        let baseTime = 9 // Start at 9 AM
        let timeInterval = 3 // 3 hours between activities
        
        for i in 0..<activitiesPerDay {
            let time = baseTime + (i * timeInterval)
            let timeString = String(format: "%02d:00", time)
            
            let activity = ItineraryActivity(
                time: timeString,
                activity: getMockActivity(for: day, index: i, style: style, destination: destination),
                location: destination,
                duration: "2-3 hours",
                description: getMockActivityDescription(for: day, index: i, style: style),
                priority: i == 0 ? "must_do" : (i == 1 ? "sounds_fun" : "maybe")
            )
            
            activities.append(activity)
        }
        
        return activities
    }
    
    private func getMockActivity(for day: Int, index: Int, style: TravelStyle, destination: String) -> String {
        let activities = [
            ["Historic City Center Walking Tour", "Local Market Visit", "Traditional Restaurant"],
            ["Museum of Local History", "Art Gallery", "Cultural Performance"],
            ["Nature Park Exploration", "Scenic Viewpoint", "Local Brewery Tour"],
            ["Shopping District", "Café Culture Experience", "Evening Entertainment"]
        ]
        
        return activities[day % activities.count][index % activities[day % activities.count].count]
    }
    
    private func getMockActivityDescription(for day: Int, index: Int, style: TravelStyle) -> String {
        let descriptions = [
            "Explore the heart of the city and discover its rich history and culture.",
            "Immerse yourself in local traditions and learn about the area's heritage.",
            "Enjoy the natural beauty and scenic views that make this destination special.",
            "Experience the local lifestyle and connect with the community."
        ]
        
        return descriptions[index % descriptions.count]
    }
    
    private func getDayTheme(for day: Int, style: TravelStyle) -> String {
        let themes = [
            "City Discovery", "Cultural Immersion", "Nature & Adventure", "Local Life"
        ]
        
        return themes[day % themes.count]
    }
    
    private func generateMockMeals(for day: Int) -> [ItineraryMeal] {
        return [
            ItineraryMeal(time: "08:00", type: "breakfast", suggestion: "Local café with traditional breakfast"),
            ItineraryMeal(time: "13:00", type: "lunch", suggestion: "Authentic local restaurant"),
            ItineraryMeal(time: "19:00", type: "dinner", suggestion: "Fine dining experience")
        ]
    }
    
    // MARK: - Get User's Itineraries
    
    func getUserItineraries() async throws -> [TravelItinerary] {
        // For now, return empty array since we're using mock data
        // TODO: Replace with actual API call when backend is ready
        return []
    }
    
    // MARK: - Get User's Wishlist for Destination
    
    func getUserWishlist(for destination: String) async throws -> [WishlistEntry] {
        guard let url = URL(string: "\(baseURL)/wishlist/") else {
            throw ItineraryError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        // Add authentication headers
        if let deviceID = KeychainManager.shared.getDeviceID() {
            urlRequest.setValue(deviceID, forHTTPHeaderField: "Device-ID")
        }
        
        if let token = AuthService.shared.getAccessToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ItineraryError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let wishlist = try JSONDecoder().decode([WishlistEntry].self, from: data)
                // Filter wishlist items that match the destination
                return wishlist.filter { entry in
                    entry.card.location?.lowercased().contains(destination.lowercased()) == true ||
                    entry.card.destination_name?.lowercased().contains(destination.lowercased()) == true
                }
            case 401:
                throw ItineraryError.unauthorized("Authentication required")
            case 500:
                throw ItineraryError.serverError("Server error occurred")
            default:
                throw ItineraryError.unknown("Unexpected error: \(httpResponse.statusCode)")
            }
        } catch let error as ItineraryError {
            throw error
        } catch {
            throw ItineraryError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Itinerary Errors

enum ItineraryError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case badRequest(String)
    case unauthorized(String)
    case serverError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let message):
            return "Network error: \(message)"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
