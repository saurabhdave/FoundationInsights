import SwiftUI
import FoundationInsights

/// Displays the on-device analysis result: urgency, summary, tags, and dominant error code.
struct ResultCard: View {

    let summary: LogSummary

    private var accentColor: Color {
        switch summary.urgency {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {

                HStack(alignment: .center) {
                    SectionHeader(icon: "sparkles", title: "Analysis")
                    Spacer()
                    UrgencyBadge(urgency: summary.urgency)
                }

                Rectangle()
                    .fill(accentColor.opacity(0.2))
                    .frame(height: 1)

                Text(summary.summary)
                    .font(.callout)
                    .lineSpacing(4)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !summary.tags.isEmpty {
                    TagsRow(tags: summary.tags)
                }

                if let code = summary.dominantErrorCode {
                    HStack(spacing: 6) {
                        Image(systemName: "number.circle.fill")
                            .foregroundStyle(.secondary)
                        Text(code)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                        .imageScale(.small)
                    Text("Processed entirely on-device")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.05))
                .allowsHitTesting(false)
        )
    }
}
// MARK: - Previews

#Preview("High Urgency") {
    ResultCard(summary: PreviewHelpers.highUrgencySummary)
        .padding()
}

#Preview("Medium Urgency") {
    ResultCard(summary: PreviewHelpers.mediumUrgencySummary)
        .padding()
}

#Preview("Low Urgency") {
    ResultCard(summary: PreviewHelpers.lowUrgencySummary)
        .padding()
}

