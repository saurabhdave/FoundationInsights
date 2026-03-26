// MARK: - Experiment

/// Describes an A/B experiment with per-user-type variant assignments.
///
/// Each `UserType` can be mapped to a specific variant string. User types not
/// listed in `variantsByUserType` receive `controlVariant`.
///
/// ```swift
/// let experiment = Experiment(
///     key: "dashboard_v2",
///     variantsByUserType: [.power: "variant_b", .explorer: "variant_b"],
///     controlVariant: "variant_a"
/// )
/// await engine.register(experiment)
/// ```
public struct Experiment: Sendable {

    /// Stable string identifier for this experiment.
    public let key: String

    /// Maps each `UserType` to the variant string they should receive.
    /// User types absent from this dictionary fall back to `controlVariant`.
    public let variantsByUserType: [UserType: String]

    /// The fallback variant for user types not listed in `variantsByUserType`.
    public let controlVariant: String

    public init(
        key: String,
        variantsByUserType: [UserType: String],
        controlVariant: String = "control"
    ) {
        self.key = key
        self.variantsByUserType = variantsByUserType
        self.controlVariant = controlVariant
    }
}
