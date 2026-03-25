import SwiftUI

struct ContentView: View {

    @Environment(LogAnalysisViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            LogAnalysisView()
                .navigationTitle("FoundationInsights")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}
