import SwiftUI

// MARK: - Root View

/// Entry point for the log analysis screen.
/// Purely declarative — all logic lives in LogAnalysisViewModel.
struct LogAnalysisView: View {

    @Environment(LogAnalysisViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(spacing: 20) {
                SamplePickerCard()

                LogBatchCard(text: $vm.logText)

                AnalyzeButton()

                if let message = viewModel.viewState.errorMessage {
                    ErrorBanner(message: message)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let result = viewModel.viewState.result {
                    ResultCard(summary: result)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8),
                       value: viewModel.viewState.result != nil)
            .animation(.easeInOut(duration: 0.2),
                       value: viewModel.viewState.errorMessage != nil)
        }
        .contentMargins(.top, 8, for: .scrollContent)
        #if !os(macOS)
        .scrollDismissesKeyboard(.immediately)
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
// MARK: - Previews

#Preview("Idle") {
    NavigationStack {
        LogAnalysisView()
            .navigationTitle("FoundationInsights")
    }
    .environment(PreviewHelpers.makeViewModel())
}

#Preview("With Result") {
    NavigationStack {
        LogAnalysisView()
            .navigationTitle("FoundationInsights")
    }
    .environment(PreviewHelpers.makeSuccessViewModel())
}

#Preview("With Error") {
    NavigationStack {
        LogAnalysisView()
            .navigationTitle("FoundationInsights")
    }
    .environment(PreviewHelpers.makeErrorViewModel())
}

