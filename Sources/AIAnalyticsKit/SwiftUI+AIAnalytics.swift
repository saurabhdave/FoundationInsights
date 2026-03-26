import SwiftUI
import SwiftData

// MARK: - View Extension

extension View {
    /// Configures AIAnalyticsKit for the entire app in a single call.
    ///
    /// Apply to the root view inside your `WindowGroup`. It:
    /// 1. Initialises the shared `AIAnalytics` event manager (idempotent).
    /// 2. Injects the SwiftData `ModelContainer` so persistence works throughout
    ///    the view hierarchy.
    /// 3. Creates a shared `HomeViewModel` and injects it as an environment
    ///    object so `HomeView` and any view reading
    ///    `@Environment(HomeViewModel.self)` works without manual setup.
    ///
    /// **Usage:**
    /// ```swift
    /// @main struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .aiAnalytics()
    ///         }
    ///     }
    /// }
    /// ```
    public func aiAnalytics() -> some View {
        modifier(AIAnalyticsViewModifier())
    }

    /// Configures AIAnalyticsKit with AI-driven feature flags and A/B testing.
    ///
    /// Pass a `FeatureFlagRegistry` and/or `ExperimentEngine` created via
    /// `AIAnalyticsContainer` to wire them into the prediction pipeline.
    /// Both are updated automatically after every prediction run.
    ///
    /// ```swift
    /// let flags = AIAnalyticsContainer.makeFeatureFlagRegistry()
    /// let experiments = AIAnalyticsContainer.makeExperimentEngine()
    ///
    /// ContentView()
    ///     .aiAnalytics(flagRegistry: flags, experimentEngine: experiments)
    /// ```
    public func aiAnalytics(
        flagRegistry: FeatureFlagRegistry? = nil,
        experimentEngine: ExperimentEngine? = nil
    ) -> some View {
        modifier(AIAnalyticsViewModifier(flagRegistry: flagRegistry, experimentEngine: experimentEngine))
    }
}

// MARK: - View Modifier

/// `@MainActor` so its `init` can safely call `@MainActor`-isolated APIs
/// (`AIAnalytics._configure()` and `AIAnalyticsContainer.makeHomeViewModel()`).
@MainActor
private struct AIAnalyticsViewModifier: ViewModifier {

    @State private var homeViewModel: HomeViewModel

    init(flagRegistry: FeatureFlagRegistry? = nil, experimentEngine: ExperimentEngine? = nil) {
        // Configure the static facade's shared AnalyticsManager (idempotent).
        AIAnalytics._configure()
        // Initialise @State using the explicit State(wrappedValue:) form,
        // which is the correct pattern when init arguments are needed.
        _homeViewModel = State(wrappedValue: AIAnalyticsContainer.makeHomeViewModel(
            flagRegistry: flagRegistry,
            experimentEngine: experimentEngine
        ))
    }

    func body(content: Content) -> some View {
        content
            .modelContainer(AIAnalytics.modelContainer)
            .environment(homeViewModel)
    }
}
