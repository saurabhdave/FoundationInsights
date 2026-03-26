import Foundation
import OSLog
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

    private let logger = Logger(subsystem: "com.aianalyticskit", category: "HomeViewModel")
    private let analyticsManager: AnalyticsManager
    private let featureBuilder: any FeatureBuilding
    private let aiEngine: any AIEngine
    private let personalizationEngine: any PersonalizationEngineProtocol
    private let flagRegistry: FeatureFlagRegistry?
    private let experimentEngine: ExperimentEngine?

    // MARK: - Published State

    public var viewState: HomeViewState = .idle
    public var eventCount: Int = 0
    /// All persisted events, newest first. Updated after every pipeline run.
    public var recentEvents: [AnalyticsEvent] = []
    /// The feature vector computed from the last pipeline run, or nil before first run.
    public var currentFeatures: UserFeatures?

    // MARK: - Real-Time Adaptation

    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: Duration

    /// Emits a new `UIConfiguration` after every successful pipeline run.
    /// Useful for SDK consumers who want to reactively observe configuration changes
    /// without polling `viewState`.
    public let configurationStream: AsyncStream<UIConfiguration>
    private let configurationContinuation: AsyncStream<UIConfiguration>.Continuation

    // MARK: - Init

    init(
        analyticsManager: AnalyticsManager,
        featureBuilder: some FeatureBuilding,
        aiEngine: some AIEngine,
        personalizationEngine: some PersonalizationEngineProtocol,
        flagRegistry: FeatureFlagRegistry? = nil,
        experimentEngine: ExperimentEngine? = nil,
        adaptationDebounceInterval: Duration = .seconds(2)
    ) {
        self.analyticsManager = analyticsManager
        self.featureBuilder = featureBuilder
        self.aiEngine = aiEngine
        self.personalizationEngine = personalizationEngine
        self.flagRegistry = flagRegistry
        self.experimentEngine = experimentEngine
        self.debounceInterval = adaptationDebounceInterval

        let (stream, continuation) = AsyncStream<UIConfiguration>.makeStream()
        self.configurationStream = stream
        self.configurationContinuation = continuation
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
            configurationContinuation.yield(config)
            await flagRegistry?.updatePrediction(prediction)
            await experimentEngine?.updatePrediction(prediction)
        } catch {
            logger.error("Prediction pipeline failed: \(error)")
            let message: String
            if error is CancellationError {
                message = String(localized: "Analysis was interrupted. Please try again.")
            } else {
                message = String(localized: "Unable to load insights. Please try again.")
            }
            viewState = .failure(message)
        }
    }

    // MARK: - Debounced Adaptation

    /// Schedules a debounced `loadInsights()` call. Cancels any pending schedule
    /// so rapid event bursts result in a single pipeline run after the quiet period.
    private func scheduleAdaptation() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(for: self?.debounceInterval ?? .seconds(2))
                await self?.loadInsights()
            } catch {
                // Task was cancelled — a newer event arrived, that's expected.
            }
        }
    }

    // MARK: - Event Tracking

    /// Tracks a single event then schedules a debounced pipeline refresh.
    public func trackEvent(
        name: String,
        category: AnalyticsEvent.EventCategory,
        properties: [String: String] = [:]
    ) async {
        let event = AnalyticsEvent(name: name, category: category, properties: properties)
        await analyticsManager.track(event)
        scheduleAdaptation()
    }

    /// Tracks a batch of events then schedules a debounced pipeline refresh.
    public func trackEvents(_ events: [AnalyticsEvent]) async {
        await analyticsManager.trackBatch(events)
        scheduleAdaptation()
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
        scheduleAdaptation()
    }

    // MARK: - Reset

    /// Deletes all persisted events and resets the view to idle.
    public func clearAllEvents() async {
        debounceTask?.cancel()
        await analyticsManager.clearAll()
        eventCount = 0
        recentEvents = []
        currentFeatures = nil
        viewState = .idle
    }
}
