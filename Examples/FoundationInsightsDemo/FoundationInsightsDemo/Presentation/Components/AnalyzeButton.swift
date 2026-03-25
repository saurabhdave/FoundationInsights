import SwiftUI

/// Primary CTA button that triggers on-device log analysis.
struct AnalyzeButton: View {

    @Environment(LogAnalysisViewModel.self) private var viewModel

    var body: some View {
        Button {
            Task { await viewModel.analyze() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.viewState.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "brain.filled.head.profile")
                        .imageScale(.medium)
                }
                Text(viewModel.viewState.isLoading ? "Analyzing\u{2026}" : "Analyze Logs")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glassProminent)
        .tint(.accentColor)
        .disabled(viewModel.viewState.isLoading || viewModel.logText.isEmpty)
    }
}

// MARK: - Preview

#Preview {
    AnalyzeButton()
        .padding()
        .environment(PreviewHelpers.makeViewModel())
}
