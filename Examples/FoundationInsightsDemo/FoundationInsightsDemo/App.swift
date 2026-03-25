import SwiftUI

@main
struct FoundationInsightsDemoApp: App {

    @State private var viewModel = AppDependencies.makeLogAnalysisViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
