import Foundation
import FoundationModels
import OSLog

// MARK: - Foundation Models Prediction Engine

/// Uses Apple's on-device Foundation Models framework to classify
/// user behavior patterns from the feature vector.
/// Falls back to a heuristic classification if the model is unavailable.
struct FoundationPredictionEngine: AIEngine {

    private let logger = Logger(
        subsystem: "com.app.FoundationInsightsDemo",
        category: "FoundationPredictionEngine"
    )

    func predict(from features: UserFeatures) async throws -> UserPrediction {
        let model = SystemLanguageModel(useCase: .general)

        guard model.availability == .available else {
            logger.info("Foundation model unavailable — using heuristic fallback")
            return heuristicPrediction(from: features)
        }

        let session = LanguageModelSession(model: model)

        let prompt = """
            You are a user behavior analyst. Given these app usage metrics, classify \
            the user as exactly one of: "Power User", "Casual User", "Explorer", or "At-Risk".
            Respond with only the classification label.

            Metrics:
            - Total events: \(features.totalEvents)
            - Unique screens: \(features.uniqueScreens)
            - Error rate: \(String(format: "%.2f", features.errorRate))
            - Analysis count: \(features.analysisCount)
            - Days since first event: \(features.daysSinceFirstEvent)
            """

        let response = try await session.respond(to: prompt)
        let responseText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let userType = UserType.allCases.first {
            responseText.localizedCaseInsensitiveContains($0.rawValue)
        } ?? .casual

        return UserPrediction(userType: userType, confidence: 0.85)
    }

    // MARK: - Heuristic Fallback

    private func heuristicPrediction(from features: UserFeatures) -> UserPrediction {
        let userType: UserType
        if features.errorRate > 0.3 {
            userType = .atRisk
        } else if features.totalEvents > 50 && features.analysisCount > 10 {
            userType = .power
        } else if features.uniqueScreens > 5 {
            userType = .explorer
        } else {
            userType = .casual
        }
        return UserPrediction(userType: userType, confidence: 0.6)
    }
}
