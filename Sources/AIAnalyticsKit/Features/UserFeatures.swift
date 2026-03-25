import Foundation

// MARK: - User Features

/// Feature vector extracted from raw analytics events for AI prediction input.
/// Each property maps to a model input dimension.
public struct UserFeatures: Sendable {
    public let totalEvents: Int
    public let uniqueScreens: Int
    public let averageSessionDuration: TimeInterval
    public let errorRate: Double
    public let analysisCount: Int
    public let daysSinceFirstEvent: Int

    public init(
        totalEvents: Int,
        uniqueScreens: Int,
        averageSessionDuration: TimeInterval,
        errorRate: Double,
        analysisCount: Int,
        daysSinceFirstEvent: Int
    ) {
        self.totalEvents = totalEvents
        self.uniqueScreens = uniqueScreens
        self.averageSessionDuration = averageSessionDuration
        self.errorRate = errorRate
        self.analysisCount = analysisCount
        self.daysSinceFirstEvent = daysSinceFirstEvent
    }

    /// Placeholder feature vector for when no events exist yet.
    public static let empty = UserFeatures(
        totalEvents: 0,
        uniqueScreens: 0,
        averageSessionDuration: 0,
        errorRate: 0,
        analysisCount: 0,
        daysSinceFirstEvent: 0
    )
}
