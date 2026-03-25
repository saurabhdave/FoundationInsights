import SwiftUI

/// Monospaced text editor for viewing and editing the raw log batch.
struct LogBatchCard: View {

    @Binding var text: String

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "terminal", title: "Log Batch")

                TextEditor(text: $text)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160, maxHeight: 220)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
    }
}
// MARK: - Preview

#Preview {
    LogBatchCard(text: .constant(SampleLogBatches.highUrgency))
        .padding()
}

