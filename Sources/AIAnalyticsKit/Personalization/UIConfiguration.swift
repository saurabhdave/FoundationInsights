import SwiftUI

// MARK: - UI Configuration

/// Personalized UI parameters derived from the AI prediction.
/// Views read this model to adapt layout, messaging, and feature visibility.
public struct UIConfiguration: Sendable {
    public let greeting: String
    public let accentColor: Color
    public let showAdvancedFeatures: Bool
    public let recommendedActions: [RecommendedAction]

    public struct RecommendedAction: Sendable, Identifiable {
        public let id: UUID
        public let title: String
        public let subtitle: String
        public let icon: String

        public init(
            id: UUID = UUID(),
            title: String,
            subtitle: String,
            icon: String
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
        }
    }

    public init(
        greeting: String,
        accentColor: Color,
        showAdvancedFeatures: Bool,
        recommendedActions: [RecommendedAction]
    ) {
        self.greeting = greeting
        self.accentColor = accentColor
        self.showAdvancedFeatures = showAdvancedFeatures
        self.recommendedActions = recommendedActions
    }

    /// Default configuration before any prediction is available.
    public static let `default` = UIConfiguration(
        greeting: "Welcome",
        accentColor: .accentColor,
        showAdvancedFeatures: false,
        recommendedActions: []
    )
}
