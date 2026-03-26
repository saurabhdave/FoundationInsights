import Foundation

// MARK: - ExperimentAssignment

/// The resolved variant assignment for the current user in a given experiment.
public struct ExperimentAssignment: Sendable {

    /// The experiment key this assignment belongs to.
    public let experimentKey: String

    /// The variant string assigned to the current user (e.g. `"variant_b"` or `"control"`).
    public let variant: String

    /// The user type that drove this assignment.
    public let userType: UserType

    /// The confidence score of the underlying prediction.
    public let confidence: Double

    /// When this assignment was resolved.
    public let assignedAt: Date
}
