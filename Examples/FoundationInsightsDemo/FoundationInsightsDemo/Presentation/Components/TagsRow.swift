import SwiftUI

/// Horizontally scrollable row of domain tag pills.
struct TagsRow: View {

    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}
// MARK: - Preview

#Preview {
    TagsRow(tags: ["crash", "networking", "auth"])
        .padding()
}

