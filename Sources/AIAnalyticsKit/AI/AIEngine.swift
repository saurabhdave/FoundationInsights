import Foundation

// MARK: - Protocol

/// Contract for on-device AI prediction engines.
/// Two implementations exist: CoreML-based and FoundationModels-based.
protocol AIEngine: Sendable {
    func predict(from features: UserFeatures) async throws -> UserPrediction
}
