import SwiftUI
import FoundationInsights

/// Color-coded capsule badge indicating the triage level of a log batch.
struct UrgencyBadge: View {

    let urgency: LogSummary.Urgency

    private var color: Color {
        switch urgency {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }

    private var icon: String {
        switch urgency {
        case .high:   return "flame.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low:    return "checkmark.circle.fill"
        }
    }

    var body: some View {
        Label(urgency.rawValue, systemImage: icon)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.16))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 12) {
        UrgencyBadge(urgency: .high)
        UrgencyBadge(urgency: .medium)
        UrgencyBadge(urgency: .low)
    }
    .padding()
}
