import SwiftUI
import FoundationInsights

struct LogAnalysisView: View {

    @Environment(LogAnalysisViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                SamplePickerView()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Batch")
                        .font(.headline)
                    TextEditor(text: $vm.logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Task { await viewModel.analyze() }
                } label: {
                    HStack {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        Text(viewModel.isAnalyzing ? "Analyzing…" : "Analyze")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isAnalyzing || viewModel.logText.isEmpty)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if let result = viewModel.result {
                    ResultCardView(summary: result)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding()
            .animation(.easeInOut, value: viewModel.result != nil)
        }
    }
}

// MARK: - Sample Picker

private struct SamplePickerView: View {

    @Environment(LogAnalysisViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Log Batches")
                .font(.headline)
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

// MARK: - Result Card

private struct ResultCardView: View {

    let summary: LogSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Analysis Result")
                    .font(.headline)
                Spacer()
                UrgencyBadgeView(urgency: summary.urgency.rawValue)
            }

            Divider()

            Text(summary.summary)
                .font(.body)

            if !summary.tags.isEmpty {
                TagsRowView(tags: summary.tags)
            }

            if let errorCode = summary.dominantErrorCode {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Dominant Error: \(errorCode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgencyColor(summary.urgency).opacity(0.4), lineWidth: 1.5)
        )
    }

    private func urgencyColor(_ urgency: LogSummary.Urgency) -> Color {
        switch urgency {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }
}

// MARK: - Urgency Badge

private struct UrgencyBadgeView: View {

    let urgency: String

    private var color: Color {
        switch urgency {
        case "High":   return .red
        case "Medium": return .orange
        default:       return .green
        }
    }

    var body: some View {
        Text(urgency)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Tags Row

private struct TagsRowView: View {

    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
