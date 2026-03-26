import Foundation

// MARK: - ExperimentEngine

/// Thread-safe, actor-isolated engine for AI-driven A/B testing.
///
/// Register experiments at app startup, then query variant assignments.
/// Assignments are:
/// - **AI-driven**: determined by the current `UserType` classification.
/// - **Stable**: the same user always receives the same variant across launches.
/// - **Tracked**: the first call to `assignment(for:)` per experiment per session
///   logs an `"experiment_exposed"` analytics event automatically.
///
/// The engine is updated automatically by `HomeViewModel` after each pipeline run
/// when passed to `AIAnalyticsContainer.makeHomeViewModel(experimentEngine:)`.
///
/// ```swift
/// let engine = AIAnalyticsContainer.makeExperimentEngine()
/// await engine.register(Experiment(
///     key: "dashboard_v2",
///     variantsByUserType: [.power: "variant_b", .explorer: "variant_b"]
/// ))
///
/// // In a view
/// .task(id: viewModel.viewState.prediction?.userType) {
///     if let assignment = await engine.assignment(for: "dashboard_v2") {
///         showNewDashboard = assignment.variant == "variant_b"
///     }
/// }
/// ```
public actor ExperimentEngine {

    private var experiments: [String: Experiment] = [:]
    private var currentPrediction: UserPrediction?
    private var exposedExperiments: Set<String> = []
    private let cohortID: String
    private let analyticsManager: AnalyticsManager

    init(analyticsManager: AnalyticsManager) {
        self.cohortID = CohortIdentity.cohortID()
        self.analyticsManager = analyticsManager
    }

    // MARK: - Registration

    /// Registers an experiment. Replaces any existing experiment with the same key.
    public func register(_ experiment: Experiment) {
        experiments[experiment.key] = experiment
    }

    // MARK: - Assignment

    /// Returns the variant assignment for the current user in the given experiment.
    ///
    /// Returns `nil` if the experiment key is not registered.
    /// Returns the `controlVariant` if no prediction exists yet.
    ///
    /// The first call per experiment key per session logs an `"experiment_exposed"` event.
    public func assignment(for experimentKey: String) async -> ExperimentAssignment? {
        guard let experiment = experiments[experimentKey] else { return nil }

        let prediction = currentPrediction
        let variant: String
        let userType: UserType
        let confidence: Double

        if let p = prediction {
            variant = experiment.variantsByUserType[p.userType] ?? experiment.controlVariant
            userType = p.userType
            confidence = p.confidence
        } else {
            variant = experiment.controlVariant
            userType = .casual
            confidence = 0.0
        }

        // Track exposure once per experiment per session.
        if !exposedExperiments.contains(experimentKey) {
            exposedExperiments.insert(experimentKey)
            let exposureEvent = AnalyticsEvent(
                name: "experiment_exposed",
                category: .interaction,
                properties: [
                    "experiment_key": experimentKey,
                    "variant": variant,
                    "user_type": userType.rawValue
                ]
            )
            await analyticsManager.track(exposureEvent)
        }

        return ExperimentAssignment(
            experimentKey: experimentKey,
            variant: variant,
            userType: userType,
            confidence: confidence,
            assignedAt: .now
        )
    }

    // MARK: - Pipeline Integration (internal)

    /// Called by `HomeViewModel` after each successful prediction pipeline run.
    /// Not part of the public SDK surface — the ViewModel drives this automatically.
    func updatePrediction(_ prediction: UserPrediction) {
        currentPrediction = prediction
        // Reset exposed set so re-classification re-triggers exposure tracking.
        exposedExperiments.removeAll()
    }
}
