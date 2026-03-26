import SwiftUI
import AIAnalyticsKit

@main
struct AIAnalyticsKitDemoApp: App {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Create the registry and engine once at app level.
    // They are passed to .aiAnalytics() so the prediction pipeline updates them
    // automatically after every classification run.
    private let flagRegistry = AIAnalyticsContainer.makeFeatureFlagRegistry()
    private let experimentEngine = AIAnalyticsContainer.makeExperimentEngine()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView(
                        hasCompletedOnboarding: $hasCompletedOnboarding,
                        flagRegistry: flagRegistry,
                        experimentEngine: experimentEngine
                    )
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
            .aiAnalytics(flagRegistry: flagRegistry, experimentEngine: experimentEngine)
            .task {
                await registerDemoFlags()
                await registerDemoExperiments()
            }
        }
    }

    // MARK: - Demo Flag Definitions

    private func registerDemoFlags() async {
        await flagRegistry.register([
            // Only Power Users with high confidence get batch processing
            FeatureFlag(
                key: FeatureFlagKey.batchProcessing,
                enabledForUserTypes: [.power],
                minimumConfidence: 0.6
            ),
            // Power Users and Explorers can export reports
            FeatureFlag(
                key: FeatureFlagKey.exportReport,
                enabledForUserTypes: [.power, .explorer],
                minimumConfidence: 0.5
            ),
            // Advanced filters for engaged users
            FeatureFlag(
                key: FeatureFlagKey.advancedFilters,
                enabledForUserTypes: [.power, .explorer],
                minimumConfidence: 0.5
            ),
            // Re-engagement prompts shown only to at-risk users
            FeatureFlag(
                key: FeatureFlagKey.reEngagement,
                enabledForUserTypes: [.atRisk],
                minimumConfidence: 0.4
            ),
        ])
    }

    // MARK: - Demo Experiment Definitions

    private func registerDemoExperiments() async {
        // Dashboard layout experiment: power users see advanced layout, explorers see grid
        await experimentEngine.register(Experiment(
            key: "dashboard_layout",
            variantsByUserType: [.power: "advanced", .explorer: "grid"],
            controlVariant: "standard"
        ))
        // Onboarding experiment: simplified flow for at-risk users
        await experimentEngine.register(Experiment(
            key: "onboarding_flow",
            variantsByUserType: [.atRisk: "simplified"],
            controlVariant: "default"
        ))
        // CTA copy experiment: power users see action-oriented copy
        await experimentEngine.register(Experiment(
            key: "cta_copy",
            variantsByUserType: [.power: "run_analysis", .explorer: "explore_more", .atRisk: "get_started"],
            controlVariant: "learn_more"
        ))
    }
}
