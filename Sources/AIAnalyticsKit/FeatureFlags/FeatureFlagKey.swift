// MARK: - FeatureFlagKey

/// Predefined feature flag key constants shipped with AIAnalyticsKit.
///
/// Use these keys when registering and querying built-in flags, or define
/// your own `String` constants for app-specific flags.
///
/// ```swift
/// await registry.register(FeatureFlag(
///     key: FeatureFlagKey.batchProcessing,
///     enabledForUserTypes: [.power],
///     minimumConfidence: 0.7
/// ))
/// let isEnabled = await registry.isEnabled(FeatureFlagKey.batchProcessing)
/// ```
public enum FeatureFlagKey {
    /// Enables batch processing features for power users.
    public static let batchProcessing = "batchProcessing"
    /// Enables the export report feature.
    public static let exportReport = "exportReport"
    /// Enables advanced filter controls.
    public static let advancedFilters = "advancedFilters"
    /// Enables re-engagement prompts for at-risk users.
    public static let reEngagement = "reEngagement"
}
