import SwiftUI
import AIAnalyticsKit

@main
struct AIAnalyticsKitDemoApp: App {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
            .aiAnalytics()
        }
    }
}
