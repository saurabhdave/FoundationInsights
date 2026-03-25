import Foundation
import OSLog

// MARK: - Analytics Manager

/// Central coordinator for tracking user interaction events.
/// Persists events to the event store and exposes query methods for the feature builder.
actor AnalyticsManager: AnalyticsTracking {

    private let store: any EventStore
    private let logger = Logger(
        subsystem: "com.aianalyticskit.demo",
        category: "AnalyticsManager"
    )

    // MARK: - Init

    init(store: some EventStore) {
        self.store = store
    }

    // MARK: - AnalyticsTracking

    func track(_ event: AnalyticsEvent) async {
        do {
            try await store.save(event)
            logger.debug("Tracked event: \(event.name)")
        } catch {
            logger.error("Failed to save event: \(error)")
        }
    }

    func trackBatch(_ events: [AnalyticsEvent]) async {
        do {
            try await store.saveBatch(events)
            logger.debug("Tracked batch of \(events.count) events")
        } catch {
            logger.error("Failed to save event batch: \(error)")
        }
    }

    // MARK: - Query

    func allEvents() async -> [AnalyticsEvent] {
        do {
            return try await store.fetchAll()
        } catch {
            logger.error("Failed to fetch events: \(error)")
            return []
        }
    }

    func recentEvents(since date: Date) async -> [AnalyticsEvent] {
        do {
            return try await store.fetchEvents(since: date)
        } catch {
            logger.error("Failed to fetch recent events: \(error)")
            return []
        }
    }

    // MARK: - Mutation

    func clearAll() async {
        do {
            try await store.deleteAll()
            logger.debug("All events cleared")
        } catch {
            logger.error("Failed to clear events: \(error)")
        }
    }
}
