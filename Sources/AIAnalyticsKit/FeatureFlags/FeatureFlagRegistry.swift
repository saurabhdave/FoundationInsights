// MARK: - FeatureFlagRegistry

/// Thread-safe, actor-isolated registry for AI-driven feature flags.
///
/// Register flags at app startup, then query them after the AI prediction pipeline
/// runs. The registry is automatically updated by `HomeViewModel` after each
/// pipeline run — no manual wiring needed once you pass it to `makeHomeViewModel()`.
///
/// ```swift
/// // At startup
/// let registry = AIAnalyticsContainer.makeFeatureFlagRegistry()
/// await registry.register(FeatureFlag(
///     key: FeatureFlagKey.batchProcessing,
///     enabledForUserTypes: [.power],
///     minimumConfidence: 0.7
/// ))
///
/// // In a SwiftUI view
/// .task(id: viewModel.viewState.prediction?.userType) {
///     showBatchButton = await registry.isEnabled(FeatureFlagKey.batchProcessing)
/// }
/// ```
public actor FeatureFlagRegistry {

    private var flags: [String: FeatureFlag] = [:]
    private var currentPrediction: UserPrediction?

    public init() {}

    // MARK: - Registration

    /// Registers a flag. Replaces any existing flag with the same key.
    public func register(_ flag: FeatureFlag) {
        flags[flag.key] = flag
    }

    /// Registers multiple flags at once. Each replaces any existing flag with the same key.
    public func register(_ flags: [FeatureFlag]) {
        for flag in flags {
            self.flags[flag.key] = flag
        }
    }

    // MARK: - Evaluation

    /// Returns `true` if the flag identified by `key` is enabled for the current prediction.
    ///
    /// Returns `false` when:
    /// - The key has not been registered.
    /// - No prediction has been received yet.
    /// - The current prediction's user type or confidence does not satisfy the flag's conditions.
    public func isEnabled(_ key: String) -> Bool {
        guard let flag = flags[key], let prediction = currentPrediction else { return false }
        return flag.isEnabled(for: prediction)
    }

    // MARK: - Pipeline Integration (internal)

    /// Called by `HomeViewModel` after each successful prediction pipeline run.
    /// Not part of the public SDK surface — the ViewModel drives this automatically.
    func updatePrediction(_ prediction: UserPrediction) {
        currentPrediction = prediction
    }
}
