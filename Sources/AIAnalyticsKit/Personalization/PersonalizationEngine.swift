import SwiftUI

// MARK: - Protocol

/// Contract for generating personalized UI configurations from predictions.
protocol PersonalizationEngineProtocol: Sendable {
    func configure(for prediction: UserPrediction) -> UIConfiguration
}

// MARK: - Default Implementation

/// Maps AI predictions to concrete UI parameters.
/// Each user type receives a tailored greeting, accent color, and recommended actions.
struct PersonalizationEngine: PersonalizationEngineProtocol {

    func configure(for prediction: UserPrediction) -> UIConfiguration {
        switch prediction.userType {
        case .power:
            return UIConfiguration(
                greeting: "Welcome back, power user",
                accentColor: .purple,
                showAdvancedFeatures: true,
                recommendedActions: [
                    .init(title: "Batch Analysis", subtitle: "Analyze multiple log files at once", icon: "square.stack.3d.up.fill"),
                    .init(title: "Export Report", subtitle: "Generate a detailed analysis report", icon: "doc.richtext"),
                ]
            )
        case .casual:
            return UIConfiguration(
                greeting: "Welcome back",
                accentColor: .blue,
                showAdvancedFeatures: false,
                recommendedActions: [
                    .init(title: "Quick Scan", subtitle: "Analyze your most recent logs", icon: "bolt.fill"),
                    .init(title: "Getting Started", subtitle: "Learn about log analysis basics", icon: "book.fill"),
                ]
            )
        case .explorer:
            return UIConfiguration(
                greeting: "Discover something new",
                accentColor: .teal,
                showAdvancedFeatures: true,
                recommendedActions: [
                    .init(title: "Try Adapter Mode", subtitle: "Enable the enriched analysis path", icon: "sparkles"),
                    .init(title: "Custom Filters", subtitle: "Filter logs by severity or module", icon: "line.3.horizontal.decrease.circle.fill"),
                ]
            )
        case .atRisk:
            return UIConfiguration(
                greeting: "We missed you!",
                accentColor: .orange,
                showAdvancedFeatures: false,
                recommendedActions: [
                    .init(title: "What's New", subtitle: "See the latest improvements", icon: "star.fill"),
                    .init(title: "Quick Help", subtitle: "Get started in under a minute", icon: "questionmark.circle.fill"),
                ]
            )
        }
    }
}
