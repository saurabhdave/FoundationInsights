import SwiftUI

/// Generic card wrapper that applies the standard surface treatment.
struct CardContainer<Content: View>: View {

    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    CardContainer {
        Text("Sample card content")
            .font(.body)
    }
    .padding()
}
