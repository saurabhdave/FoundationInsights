// MARK: - FeatureFlag

/// A named feature toggle whose enabled state is derived from the current AI prediction.
///
/// Evaluate against a live prediction using `isEnabled(for:)`, or query the shared
/// `FeatureFlagRegistry` after prediction updates are propagated automatically.
///
/// ```swift
/// let flag = FeatureFlag(
///     key: FeatureFlagKey.batchProcessing,
///     enabledForUserTypes: [.power],
///     minimumConfidence: 0.7
/// )
/// let isOn = flag.isEnabled(for: prediction)
/// ```
public struct FeatureFlag: Sendable {

    /// Stable string identifier for this flag. Use `FeatureFlagKey` constants or define your own.
    public let key: String

    /// The user types for which this flag is enabled.
    public let enabledForUserTypes: Set<UserType>

    /// The minimum confidence score the prediction must meet for the flag to be enabled.
    /// Defaults to `0.0`, meaning any confidence level qualifies.
    public let minimumConfidence: Double

    public init(
        key: String,
        enabledForUserTypes: Set<UserType>,
        minimumConfidence: Double = 0.0
    ) {
        self.key = key
        self.enabledForUserTypes = enabledForUserTypes
        self.minimumConfidence = minimumConfidence
    }

    /// Returns `true` if the prediction's user type is in `enabledForUserTypes`
    /// and the prediction's confidence meets `minimumConfidence`.
    public func isEnabled(for prediction: UserPrediction) -> Bool {
        enabledForUserTypes.contains(prediction.userType)
            && prediction.confidence >= minimumConfidence
    }
}
