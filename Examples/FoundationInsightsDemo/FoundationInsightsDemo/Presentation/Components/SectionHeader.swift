import SwiftUI

/// Consistent icon + title label used at the top of each card section.
struct SectionHeader: View {

    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.footnote.weight(.bold))
            .textCase(.uppercase)
            .kerning(0.5)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SectionHeader(icon: "doc.text.magnifyingglass", title: "Sample Batches")
        SectionHeader(icon: "terminal", title: "Log Batch")
        SectionHeader(icon: "sparkles", title: "Analysis")
    }
    .padding()
}
