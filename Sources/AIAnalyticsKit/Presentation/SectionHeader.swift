import SwiftUI

/// Consistent icon + title label used at the top of each card section.
public struct SectionHeader: View {

    public let icon: String
    public let title: String

    public init(icon: String, title: String) {
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        Label(title, systemImage: icon)
            .font(.footnote.weight(.bold))
            .textCase(.uppercase)
            .kerning(0.5)
            .foregroundStyle(.secondary)
    }
}
