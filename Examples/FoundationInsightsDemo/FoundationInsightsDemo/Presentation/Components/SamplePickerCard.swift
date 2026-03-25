import SwiftUI

/// Segmented picker for choosing a pre-canned log batch sample.
struct SamplePickerCard: View {

    @Environment(LogAnalysisViewModel.self) private var viewModel

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "doc.text.magnifyingglass", title: "Sample Batches")

                Picker("Sample", selection: Binding(
                    get: { viewModel.selectedSample },
                    set: { viewModel.selectSample($0) }
                )) {
                    ForEach(SampleLogBatches.Sample.allCases) { sample in
                        Text(sample.rawValue).tag(sample)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SamplePickerCard()
        .padding()
        .environment(PreviewHelpers.makeViewModel())
}
