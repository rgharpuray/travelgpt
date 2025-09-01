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
        case .common: return Color.gray.opacity(0.6)
        case .rare: return Color.blue.opacity(0.7)
        case .legendary: return Color.orange.opacity(0.8)
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .common: return LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rare: return LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .legendary: return LinearGradient(colors: [.orange.opacity(0.5), .yellow.opacity(0.4), .orange.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "circle.fill"
        case .rare: return "diamond.fill"
        case .legendary: return "star.fill"
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

