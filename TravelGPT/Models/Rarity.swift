import Foundation
import SwiftUI

// MARK: - Rarity System
enum Rarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .legendary: return "Legendary"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return Color(red: 0.4, green: 0.6, blue: 0.8) // Ocean blue
        case .rare: return Color(red: 0.8, green: 0.4, blue: 0.9) // Purple sunset
        case .legendary: return Color(red: 1.0, green: 0.6, blue: 0.2) // Golden sunrise
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .common: return LinearGradient(
            colors: [
                Color(red: 0.3, green: 0.7, blue: 0.9), // Sky blue
                Color(red: 0.1, green: 0.5, blue: 0.8)  // Deep ocean
            ], 
            startPoint: .topLeading, 
            endPoint: .bottomTrailing
        )
        case .rare: return LinearGradient(
            colors: [
                Color(red: 0.9, green: 0.3, blue: 0.8), // Magenta
                Color(red: 0.6, green: 0.2, blue: 0.9), // Deep purple
                Color(red: 0.4, green: 0.1, blue: 0.8)  // Midnight purple
            ], 
            startPoint: .topLeading, 
            endPoint: .bottomTrailing
        )
        case .legendary: return LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.8, blue: 0.0), // Gold
                Color(red: 1.0, green: 0.5, blue: 0.0), // Orange
                Color(red: 0.9, green: 0.3, blue: 0.1), // Deep orange
                Color(red: 1.0, green: 0.8, blue: 0.0)  // Back to gold
            ], 
            startPoint: .topLeading, 
            endPoint: .bottomTrailing
        )
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "airplane.circle.fill"
        case .rare: return "mountain.2.fill"
        case .legendary: return "crown.fill"
        }
    }
    
    var sparkleEffect: Bool {
        switch self {
        case .common: return false
        case .rare: return true
        case .legendary: return true
        }
    }
}

