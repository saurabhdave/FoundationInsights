import Foundation

// MARK: - Protocol

/// Contract for persisting and querying analytics events.
/// The SwiftData implementation is the default; inject a mock for tests.
protocol EventStore: Sendable {
    func save(_ event: AnalyticsEvent) async throws
    func saveBatch(_ events: [AnalyticsEvent]) async throws
    func fetchAll() async throws -> [AnalyticsEvent]
    func fetchEvents(since date: Date) async throws -> [AnalyticsEvent]
    func deleteAll() async throws
}
