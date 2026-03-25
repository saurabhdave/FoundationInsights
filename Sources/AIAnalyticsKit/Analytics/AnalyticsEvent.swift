import Foundation

// MARK: - Analytics Event

/// Domain model representing a single user interaction event.
/// Sendable for safe cross-actor transport.
public struct AnalyticsEvent: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: EventCategory
    public let properties: [String: String]
    public let timestamp: Date

    public enum EventCategory: String, Sendable, CaseIterable {
        case navigation
        case interaction
        case analysis
        case error
    }

    public init(
        id: UUID = UUID(),
        name: String,
        category: EventCategory,
        properties: [String: String] = [:],
        timestamp: Date = .now
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.properties = properties
        self.timestamp = timestamp
    }
}
