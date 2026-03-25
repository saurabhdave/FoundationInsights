import SwiftUI
import FoundationInsights

@main
struct FoundationInsightsDemoApp: App {

    @State private var viewModel = LogAnalysisViewModel(service: LogIntelligenceService())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
