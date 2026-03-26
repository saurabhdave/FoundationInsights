import SwiftUI
import AIAnalyticsKit

// MARK: - User Types Tab

struct UserTypesTab: View {

    @Environment(HomeViewModel.self) private var viewModel
    @State private var expandedType: UserType?

    private var currentType: UserType? {
        viewModel.viewState.prediction?.userType
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                ForEach(UserType.allCases) { userType in
                    UserTypeCard(
                        userType: userType,
                        isActive: currentType == userType,
                        isExpanded: expandedType == userType
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            expandedType = expandedType == userType ? nil : userType
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(icon: "person.3.fill", title: "Classification Model")
                Text("AIAnalyticsKit maps every user into one of four behavior types. The engine selects the best match from your feature vector.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let current = currentType {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .imageScale(.small)
                        Text("Current prediction: ")
                            .font(.caption)
                        Text(current.rawValue)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - User Type Card

private struct UserTypeCard: View {

    let userType: UserType
    let isActive: Bool
    let isExpanded: Bool
    let onTap: () -> Void

    private var personalization: UIConfiguration {
        PersonalizationEngine().configure(for: UserPrediction(userType: userType, confidence: 1.0))
    }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                // Header row — always visible
                Button(action: onTap) {
                    HStack(spacing: 14) {
                        Image(systemName: userType.icon)
                            .font(.title3)
                            .foregroundStyle(personalization.accentColor)
                            .frame(width: 46, height: 46)
                            .glassEffect(.regular.tint(personalization.accentColor), in: .circle)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(userType.rawValue)
                                    .font(.headline)
                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(personalization.accentColor)
                                        .imageScale(.small)
                                }
                            }
                            Text(userType.typeDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(isExpanded ? nil : 1)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // Expanded detail
                if isExpanded {
                    Divider()
                        .padding(.vertical, 12)

                    VStack(alignment: .leading, spacing: 12) {

                        // Personalization preview
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Personalization", systemImage: "paintbrush.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Circle()
                                    .fill(personalization.accentColor)
                                    .frame(width: 14, height: 14)
                                Text("Accent color · \(Text(personalization.greeting).italic())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: personalization.showAdvancedFeatures ? "star.fill" : "star")
                                    .foregroundStyle(personalization.showAdvancedFeatures ? personalization.accentColor : .secondary)
                                    .imageScale(.small)
                                Text(personalization.showAdvancedFeatures ? "Advanced features unlocked" : "Basic feature set")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Recommended actions
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Recommended Actions", systemImage: "lightbulb.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ForEach(personalization.recommendedActions) { action in
                                HStack(spacing: 10) {
                                    Image(systemName: action.icon)
                                        .foregroundStyle(personalization.accentColor)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(action.title)
                                            .font(.caption.weight(.medium))
                                        Text(action.subtitle)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        // Classification triggers
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Triggered By", systemImage: "slider.horizontal.3")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(classificationTrigger(for: userType))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isActive ? personalization.accentColor.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }

    private func classificationTrigger(for type: UserType) -> String {
        switch type {
        case .atRisk:
            return "Error rate exceeds \(Int(ClassificationConfig.atRiskErrorRate * 100))% of all tracked events."
        case .power:
            return "More than \(ClassificationConfig.powerUserMinEvents) total events AND more than \(ClassificationConfig.powerUserMinAnalyses) analysis events."
        case .explorer:
            return "More than \(ClassificationConfig.explorerMinScreens) unique screens navigated (requires screen property on navigation events)."
        case .casual:
            return "No dominant signal — falls through all other thresholds."
        }
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        UserTypesTab()
            .navigationTitle("User Types")
    }
    .environment(AIAnalyticsContainer.makeHomeViewModel())
    .modelContainer(AIAnalyticsContainer.modelContainer)
}
