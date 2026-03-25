import Foundation
import Observation

// MARK: - ViewModel

/// Owns all mutable state for the AI Insights home screen.
/// Orchestrates the full pipeline: events -> features -> prediction -> personalization.
///
/// Data flow:
///   User Action → AnalyticsManager → Event Store → Feature Builder → AI Engine
///     → Personalization Engine → UIConfiguration → SwiftUI View
@Observable
@MainActor
public final class HomeViewModel {

    // MARK: - Dependencies

    private let analyticsManager: AnalyticsManager
    private let featureBuilder: any FeatureBuilding
    private let aiEngine: any AIEngine
    private let personalizationEngine: any PersonalizationEngineProtocol

    // MARK: - Published State

    public var viewState: HomeViewState = .idle
    public var eventCount: Int = 0
    /// All persisted events, newest first. Updated after every pipeline run.
    public var recentEvents: [AnalyticsEvent] = []
    /// The feature vector computed from the last pipeline run, or nil before first run.
    public var currentFeatures: UserFeatures?

    // MARK: - Init

    init(
        analyticsManager: AnalyticsManager,
        featureBuilder: some FeatureBuilding,
        aiEngine: some AIEngine,
        personalizationEngine: some PersonalizationEngineProtocol
    ) {
        self.analyticsManager = analyticsManager
        self.featureBuilder = featureBuilder
        self.aiEngine = aiEngine
        self.personalizationEngine = personalizationEngine
    }

    // MARK: - Pipeline

    /// Runs the full prediction pipeline: fetch events → build features → predict → personalize.
    public func loadInsights() async {
        guard !viewState.isLoading else { return }
        viewState = .loading

        do {
            let events = await analyticsManager.allEvents()
            eventCount = events.count
            recentEvents = events
            let features = featureBuilder.buildFeatures(from: events)
            currentFeatures = features
            let prediction = try await aiEngine.predict(from: features)
            let config = personalizationEngine.configure(for: prediction)
            viewState = .ready(config, prediction)
        } catch {
            viewState = .failure(error.localizedDescription)
        }
    }

    // MARK: - Event Tracking

    /// Tracks a single event then refreshes the prediction pipeline.
    public func trackEvent(
        name: String,
        category: AnalyticsEvent.EventCategory,
        properties: [String: String] = [:]
    ) async {
        let event = AnalyticsEvent(name: name, category: category, properties: properties)
        await analyticsManager.track(event)
        await loadInsights()
    }

    /// Tracks a batch of events then refreshes the prediction pipeline.
    public func trackEvents(_ events: [AnalyticsEvent]) async {
        await analyticsManager.trackBatch(events)
        await loadInsights()
    }

    /// Inserts a predefined batch of sample events to demonstrate the pipeline.
    public func trackSampleEvents() async {
        let sampleEvents: [AnalyticsEvent] = [
            AnalyticsEvent(name: "app_opened", category: .navigation, properties: ["screen": "home"]),
            AnalyticsEvent(name: "log_analysis_started", category: .analysis),
            AnalyticsEvent(name: "sample_selected", category: .interaction, properties: ["sample": "High Urgency"]),
            AnalyticsEvent(name: "settings_viewed", category: .navigation, properties: ["screen": "settings"]),
            AnalyticsEvent(name: "results_viewed", category: .navigation, properties: ["screen": "results"]),
        ]
        await analyticsManager.trackBatch(sampleEvents)
        await loadInsights()
    }

    // MARK: - Reset

    /// Deletes all persisted events and resets the view to idle.
    public func clearAllEvents() async {
        await analyticsManager.clearAll()
        eventCount = 0
        recentEvents = []
        currentFeatures = nil
        viewState = .idle
    }
}
