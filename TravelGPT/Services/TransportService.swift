import Foundation
import CoreLocation

// MARK: - Transport Service

class TransportService {
    static let shared = TransportService()
    
    private init() {}
    
    // MARK: - Calculate Transport Between Places
    
    /// Calculates transport information between two places
    func calculateTransport(
        from: (lat: Double, lon: Double, name: String?),
        to: (lat: Double, lon: Double, name: String?),
        destination: String
    ) -> TransportInfo {
        let fromLocation = CLLocation(latitude: from.lat, longitude: from.lon)
        let toLocation = CLLocation(latitude: to.lat, longitude: to.lon)
        
        let distance = fromLocation.distance(from: toLocation) // in meters
        
        // Determine transport method based on distance and destination
        let transport = determineTransportMethod(distance: distance, destination: destination)
        
        // Estimate time based on transport method and distance
        let estimatedTime = estimateTravelTime(distance: distance, method: transport)
        
        return TransportInfo(
            from: from.name ?? "Previous location",
            to: to.name ?? "Next location",
            method: transport,
            distance: distance,
            estimatedTime: estimatedTime,
            instructions: generateTransportInstructions(
                from: from.name ?? "Previous location",
                to: to.name ?? "Next location",
                method: transport,
                distance: distance,
                destination: destination
            )
        )
    }
    
    private func determineTransportMethod(distance: Double, destination: String) -> TransportMethod {
        // For Japan, prioritize public transport
        if destination.lowercased().contains("japan") || 
           destination.lowercased().contains("okinawa") ||
           destination.lowercased().contains("tokyo") ||
           destination.lowercased().contains("osaka") ||
           destination.lowercased().contains("kyoto") ||
           destination.lowercased().contains("naha") {
            if distance < 500 {
                return .walking
            } else if distance < 5000 {
                return .publicTransport
            } else {
                return .publicTransport
            }
        }
        
        // Default logic
        if distance < 500 {
            return .walking
        } else if distance < 2000 {
            return .walking // or bike
        } else if distance < 10000 {
            return .publicTransport
        } else {
            return .taxi // or car
        }
    }
    
    private func estimateTravelTime(distance: Double, method: TransportMethod) -> TimeInterval {
        switch method {
        case .walking:
            // Average walking speed: 5 km/h = 1.39 m/s
            return distance / 1.39
        case .publicTransport:
            // Average public transport: 30 km/h = 8.33 m/s, plus 5 min wait time
            return (distance / 8.33) + 300
        case .taxi:
            // Average taxi: 40 km/h = 11.11 m/s
            return distance / 11.11
        case .bike:
            // Average biking: 15 km/h = 4.17 m/s
            return distance / 4.17
        }
    }
    
    private func generateTransportInstructions(
        from: String,
        to: String,
        method: TransportMethod,
        distance: Double,
        destination: String
    ) -> String {
        let distanceKm = distance / 1000.0
        let distanceMiles = distanceKm * 0.621371
        let distanceStr = distance < 1000 ? "\(Int(distance))m" : String(format: "%.1f km", distanceKm)
        
        switch method {
        case .walking:
            return "Walk \(distanceStr) from \(from) to \(to). Estimated \(formatTime(estimateTravelTime(distance: distance, method: .walking)))."
            
        case .publicTransport:
            if destination.lowercased().contains("japan") || destination.lowercased().contains("okinawa") || destination.lowercased().contains("naha") {
                return "Take public transport (train/bus) from \(from) to \(to). Distance: \(distanceStr). Estimated \(formatTime(estimateTravelTime(distance: distance, method: .publicTransport))). Use Suica/IC card for easy payment."
            } else {
                return "Take public transport from \(from) to \(to). Distance: \(distanceStr). Estimated \(formatTime(estimateTravelTime(distance: distance, method: .publicTransport)))."
            }
            
        case .taxi:
            return "Take a taxi from \(from) to \(to). Distance: \(distanceStr). Estimated \(formatTime(estimateTravelTime(distance: distance, method: .taxi)))."
            
        case .bike:
            return "Bike \(distanceStr) from \(from) to \(to). Estimated \(formatTime(estimateTravelTime(distance: distance, method: .bike)))."
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    // MARK: - Estimate Activity Duration
    
    func estimateActivityDuration(category: String) -> TimeInterval {
        switch category.lowercased() {
        case "restaurant", "food", "cafe":
            return 60 * 60 // 1 hour
        case "bar":
            return 2 * 60 * 60 // 2 hours
        case "museum":
            return 2 * 60 * 60 // 2 hours
        case "attraction", "activity":
            return 90 * 60 // 1.5 hours
        case "park", "view", "scenic":
            return 45 * 60 // 45 minutes
        case "market", "shopping":
            return 60 * 60 // 1 hour
        case "beach":
            return 3 * 60 * 60 // 3 hours
        default:
            return 60 * 60 // 1 hour default
        }
    }
}

// MARK: - Transport Models

struct TransportInfo {
    let from: String
    let to: String
    let method: TransportMethod
    let distance: Double // in meters
    let estimatedTime: TimeInterval // in seconds
    let instructions: String
}

enum TransportMethod: String, Codable {
    case walking = "walking"
    case publicTransport = "public_transport"
    case taxi = "taxi"
    case bike = "bike"
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .publicTransport: return "tram.fill"
        case .taxi: return "car.fill"
        case .bike: return "bicycle"
        }
    }
    
    var displayName: String {
        switch self {
        case .walking: return "Walk"
        case .publicTransport: return "Public Transport"
        case .taxi: return "Taxi"
        case .bike: return "Bike"
        }
    }
}

// MARK: - Destination Tips Service

class DestinationTipsService {
    static let shared = DestinationTipsService()
    
    private init() {}
    
    func getDestinationTips(for destination: String) -> [String] {
        let lowercased = destination.lowercased()
        
        var tips: [String] = []
        
        // Japan-specific tips
        if lowercased.contains("japan") || 
           lowercased.contains("okinawa") ||
           lowercased.contains("tokyo") ||
           lowercased.contains("osaka") ||
           lowercased.contains("kyoto") ||
           lowercased.contains("naha") {
            tips.append("💳 Use Suica/IC card for trains, buses, and convenience stores")
            tips.append("🚇 JR Pass available for tourists (check if it covers your route)")
            tips.append("🗾 Download Google Maps or Japan Travel app for navigation")
            tips.append("💰 Carry cash - many places don't accept cards")
            tips.append("🚶 Walk on the left side, stand on the left on escalators")
        }
        
        // Add more destination-specific tips as needed
        if lowercased.contains("europe") {
            tips.append("💶 Euro is widely accepted")
            tips.append("🚂 Eurail pass available for train travel")
        }
        
        return tips
    }
}

