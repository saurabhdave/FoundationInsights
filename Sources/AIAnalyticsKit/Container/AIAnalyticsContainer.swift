import Foundation
import SwiftData

// MARK: - DI Container

/// Composition root for the FoundationInsights module.
/// The single place that knows about concrete types within this module.
///
/// Full data flow wired here:
///   AnalyticsManager → SwiftDataEventStore (persistence)
///   FeatureBuilder (events → features)
///   FoundationPredictionEngine (features → prediction)
///   PersonalizationEngine (prediction → UI configuration)
///   HomeViewModel (orchestrates all of the above)
@MainActor
public enum AIAnalyticsContainer {

    // MARK: - Model Container

    public static let modelContainer: ModelContainer = {
        let schema = Schema([AnalyticsEventModel.self])
        let configuration = ModelConfiguration(
            "AIAnalytics",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Factory Methods

    static func makeEventStore() -> SwiftDataEventStore {
        SwiftDataEventStore(modelContainer: modelContainer)
    }

    static func makeAnalyticsManager() -> AnalyticsManager {
        AnalyticsManager(store: makeEventStore())
    }

    static func makeFeatureBuilder() -> FeatureBuilder {
        FeatureBuilder()
    }

    static func makeAIEngine() -> some AIEngine {
        FoundationPredictionEngine()
    }

    static func makePersonalizationEngine() -> PersonalizationEngine {
        PersonalizationEngine()
    }

    public static func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            analyticsManager: makeAnalyticsManager(),
            featureBuilder: makeFeatureBuilder(),
            aiEngine: makeAIEngine(),
            personalizationEngine: makePersonalizationEngine()
        )
    }
}
