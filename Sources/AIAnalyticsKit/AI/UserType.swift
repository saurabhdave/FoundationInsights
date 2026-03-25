import Foundation

// MARK: - User Type

/// Classification of user behavior patterns derived from on-device AI prediction.
public enum UserType: String, Sendable, CaseIterable, Identifiable {
    case power    = "Power User"
    case casual   = "Casual User"
    case explorer = "Explorer"
    case atRisk   = "At-Risk"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .power:    return "bolt.fill"
        case .casual:   return "leaf.fill"
        case .explorer: return "safari.fill"
        case .atRisk:   return "exclamationmark.triangle.fill"
        }
    }

    public var typeDescription: String {
        switch self {
        case .power:    return "Highly engaged user with frequent, deep interactions."
        case .casual:   return "Occasional user with light, surface-level sessions."
        case .explorer: return "Curious user actively discovering new features."
        case .atRisk:   return "Declining engagement — may churn without intervention."
        }
    }
}
