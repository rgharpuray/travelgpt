import Foundation

struct ReportCard: Codable {
    let reason: ReportReason
    let description: String?
    
    enum ReportReason: String, CaseIterable, Codable {
        case inappropriate = "inappropriate"
        case spam = "spam"
        case harassment = "harassment"
        case violence = "violence"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .inappropriate:
                return "Inappropriate Content"
            case .spam:
                return "Spam"
            case .harassment:
                return "Harassment"
            case .violence:
                return "Violence"
            case .other:
                return "Other"
            }
        }
        
        var description: String {
            switch self {
            case .inappropriate:
                return "Content that is offensive, vulgar, or not suitable for all audiences"
            case .spam:
                return "Repeated or unwanted content that clutters the feed"
            case .harassment:
                return "Content that targets or bullies other users"
            case .violence:
                return "Content that promotes or depicts violence"
            case .other:
                return "Other reasons not listed above"
            }
        }
    }
}
