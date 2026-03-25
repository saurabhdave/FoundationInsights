import Foundation

// MARK: - User Prediction

/// Result of an on-device AI prediction about user behavior.
public struct UserPrediction: Sendable {
    public let userType: UserType
    public let confidence: Double
    public let generatedAt: Date

    public init(
        userType: UserType,
        confidence: Double,
        generatedAt: Date = .now
    ) {
        self.userType = userType
        self.confidence = min(max(confidence, 0), 1)
        self.generatedAt = generatedAt
    }
}
