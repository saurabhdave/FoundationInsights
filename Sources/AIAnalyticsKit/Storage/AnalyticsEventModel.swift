import Foundation
import SwiftData

// MARK: - SwiftData Model

/// Persistent representation of an analytics event.
/// Maps to/from the domain `AnalyticsEvent` type.
@Model
final class AnalyticsEventModel {
    var eventID: UUID
    var name: String
    var category: String
    var properties: [String: String]
    var timestamp: Date

    init(
        eventID: UUID,
        name: String,
        category: String,
        properties: [String: String],
        timestamp: Date
    ) {
        self.eventID = eventID
        self.name = name
        self.category = category
        self.properties = properties
        self.timestamp = timestamp
    }

    // MARK: - Domain Mapping

    convenience init(event: AnalyticsEvent) {
        self.init(
            eventID: event.id,
            name: event.name,
            category: event.category.rawValue,
            properties: event.properties,
            timestamp: event.timestamp
        )
    }

    func toDomainEvent() -> AnalyticsEvent? {
        guard let category = AnalyticsEvent.EventCategory(rawValue: category) else {
            return nil
        }
        return AnalyticsEvent(
            id: eventID,
            name: name,
            category: category,
            properties: properties,
            timestamp: timestamp
        )
    }
}
