import Foundation

// MARK: - Protocol

/// Contract for extracting a feature vector from raw analytics events.
protocol FeatureBuilding: Sendable {
    func buildFeatures(from events: [AnalyticsEvent]) -> UserFeatures
}

// MARK: - Default Implementation

/// Extracts user behavior features from analytics events.
/// The feature vector feeds into the AI prediction engine.
struct FeatureBuilder: FeatureBuilding {

    func buildFeatures(from events: [AnalyticsEvent]) -> UserFeatures {
        guard !events.isEmpty else { return .empty }

        let uniqueScreens = Set(
            events
                .filter { $0.category == .navigation }
                .compactMap { $0.properties["screen"] }
        ).count

        let errorCount = events.filter { $0.category == .error }.count
        let errorRate = Double(errorCount) / Double(events.count)

        let analysisCount = events.filter { $0.category == .analysis }.count

        let timestamps = events.map(\.timestamp)
        let daysSinceFirst: Int
        if let earliest = timestamps.min() {
            daysSinceFirst = max(Calendar.current.dateComponents(
                [.day], from: earliest, to: .now
            ).day ?? 0, 0)
        } else {
            daysSinceFirst = 0
        }

        return UserFeatures(
            totalEvents: events.count,
            uniqueScreens: uniqueScreens,
            averageSessionDuration: 0,
            errorRate: errorRate,
            analysisCount: analysisCount,
            daysSinceFirstEvent: daysSinceFirst
        )
    }
}
