import Foundation
import SwiftData

// MARK: - SwiftData Implementation

/// Persists analytics events using SwiftData.
/// Uses `@ModelActor` for background-safe database access.
@ModelActor
actor SwiftDataEventStore: EventStore {

    // MARK: - EventStore Conformance

    func save(_ event: AnalyticsEvent) async throws {
        let model = AnalyticsEventModel(event: event)
        modelContext.insert(model)
        try modelContext.save()
    }

    func saveBatch(_ events: [AnalyticsEvent]) async throws {
        for event in events {
            let model = AnalyticsEventModel(event: event)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    func fetchAll() async throws -> [AnalyticsEvent] {
        let descriptor = FetchDescriptor<AnalyticsEventModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.compactMap { $0.toDomainEvent() }
    }

    func fetchEvents(since date: Date) async throws -> [AnalyticsEvent] {
        let predicate = #Predicate<AnalyticsEventModel> { $0.timestamp >= date }
        let descriptor = FetchDescriptor<AnalyticsEventModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.compactMap { $0.toDomainEvent() }
    }

    func deleteAll() async throws {
        try modelContext.delete(model: AnalyticsEventModel.self)
        try modelContext.save()
    }
}
