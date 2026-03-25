import SwiftUI

struct ContentView: View {

    var body: some View {
        GlassEffectContainer {
            NavigationStack {
                LogAnalysisView()
                    .navigationTitle("FoundationInsights")
                    #if !os(macOS)
                    .navigationBarTitleDisplayMode(.large)
                    #endif
            }
        }
    }
}
// MARK: - Preview

#Preview {
    ContentView()
        .environment(PreviewHelpers.makeViewModel())
}

