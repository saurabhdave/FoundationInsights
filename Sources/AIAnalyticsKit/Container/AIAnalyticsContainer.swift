import Foundation
import OSLog
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
        let logger = Logger(subsystem: "com.aianalyticskit", category: "Container")

        // Attempt persistent on-disk store first.
        let persistentConfig = ModelConfiguration(
            "AIAnalytics",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            return container
        }

        // Persistent store failed (disk full, permissions, corruption, etc.).
        // Fall back to an in-memory store so the app remains functional.
        // Events will not survive a restart in this mode.
        logger.error("Persistent ModelContainer unavailable — falling back to in-memory store. Events will not persist across restarts.")
        let memoryConfig = ModelConfiguration(
            "AIAnalytics-Memory",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        guard let fallback = try? ModelContainer(for: schema, configurations: [memoryConfig]) else {
            // Both stores failed — nothing we can do.
            fatalError("AIAnalyticsKit: Cannot create any ModelContainer. This is unrecoverable.")
        }
        return fallback
    }()

    // MARK: - Factory Methods

    static func makeEventStore() -> SwiftDataEventStore {
        SwiftDataEventStore(modelContainer: modelContainer)
    }

    private static func makeAnalyticsManager() -> AnalyticsManager {
        AnalyticsManager(store: makeEventStore())
    }

    /// Shared `AnalyticsManager` instance used by both `AIAnalytics` and `HomeViewModel`.
    /// All events logged via `AIAnalytics.logEvent()` and tracked via `HomeViewModel.trackEvent()`
    /// go to the same store, so the AI pipeline sees every event.
    static let sharedAnalyticsManager: AnalyticsManager = makeAnalyticsManager()

    static func makeFeatureBuilder() -> FeatureBuilder {
        FeatureBuilder()
    }

    static func makeAIEngine() -> some AIEngine {
        FoundationPredictionEngine()
    }

    static func makePersonalizationEngine() -> PersonalizationEngine {
        PersonalizationEngine()
    }

    /// Creates a `FeatureFlagRegistry` for AI-driven feature flags.
    /// Register flags on the returned instance, then pass it to `makeHomeViewModel()`
    /// so the registry is updated automatically after each prediction pipeline run.
    public static func makeFeatureFlagRegistry() -> FeatureFlagRegistry {
        FeatureFlagRegistry()
    }

    /// Creates an `ExperimentEngine` for AI-driven A/B testing.
    /// Register experiments on the returned instance, then pass it to `makeHomeViewModel()`
    /// so variant assignments update automatically after each prediction pipeline run.
    public static func makeExperimentEngine() -> ExperimentEngine {
        ExperimentEngine(analyticsManager: sharedAnalyticsManager)
    }

    public static func makeHomeViewModel(
        flagRegistry: FeatureFlagRegistry? = nil,
        experimentEngine: ExperimentEngine? = nil
    ) -> HomeViewModel {
        HomeViewModel(
            analyticsManager: sharedAnalyticsManager,
            featureBuilder: makeFeatureBuilder(),
            aiEngine: makeAIEngine(),
            personalizationEngine: makePersonalizationEngine(),
            flagRegistry: flagRegistry,
            experimentEngine: experimentEngine
        )
    }
}
