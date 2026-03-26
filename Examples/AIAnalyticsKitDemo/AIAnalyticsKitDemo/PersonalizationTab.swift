import SwiftUI
import AIAnalyticsKit

// MARK: - Personalization Tab

struct PersonalizationTab: View {

    @Environment(HomeViewModel.self) private var viewModel

    let flagRegistry: FeatureFlagRegistry
    let experimentEngine: ExperimentEngine

    // Cached results from async actor calls, refreshed after each prediction.
    @State private var flagStates: [String: Bool] = [:]
    @State private var assignments: [String: ExperimentAssignment] = [:]

    private let demoFlags: [(key: String, label: String, icon: String, color: Color, eligibleTypes: String)] = [
        (FeatureFlagKey.batchProcessing,  "Batch Processing",  "square.stack.3d.up.fill",               .purple, "Power"),
        (FeatureFlagKey.exportReport,     "Export Report",     "doc.richtext",                          .blue,   "Power · Explorer"),
        (FeatureFlagKey.advancedFilters,  "Advanced Filters",  "line.3.horizontal.decrease.circle.fill", .teal,   "Power · Explorer"),
        (FeatureFlagKey.reEngagement,     "Re-Engagement",     "star.fill",                             .orange, "At-Risk"),
    ]

    private let demoExperimentKeys = ["dashboard_layout", "onboarding_flow", "cta_copy"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.viewState.prediction == nil {
                    noPredictionCard
                }
                featureFlagsCard
                abTestingCard
                realTimeAdaptationCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.viewState.prediction?.userType)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Re-evaluate flags and experiments whenever the user type changes.
        .task(id: viewModel.viewState.prediction?.userType) {
            await refreshState()
        }
    }

    // MARK: - No Prediction Placeholder

    private var noPredictionCard: some View {
        CardContainer {
            VStack(spacing: 14) {
                Image(systemName: "person.crop.circle.badge.questionmark.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.quaternary)
                VStack(spacing: 6) {
                    Text("No Prediction Yet")
                        .font(.headline)
                    Text("Go to the Insights tab and tap Refresh, or log some events via the Events tab. Feature flags and experiments will evaluate automatically once a prediction is available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Feature Flags Card

    private var featureFlagsCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(icon: "flag.fill", title: "AI-Driven Feature Flags")
                    Spacer()
                    if let userType = viewModel.viewState.prediction?.userType {
                        UserTypePill(userType: userType)
                    }
                }

                Text("Flags are evaluated against the current AI prediction. Eligibility is determined by user type and minimum confidence threshold.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(demoFlags, id: \.key) { flag in
                        FlagRow(
                            label: flag.label,
                            icon: flag.icon,
                            color: flag.color,
                            eligibleTypes: flag.eligibleTypes,
                            isEnabled: flagStates[flag.key] ?? false
                        )
                        if flag.key != demoFlags.last?.key {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: - A/B Testing Card

    private var abTestingCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "arrow.triangle.branch", title: "AI-Driven A/B Tests")

                Text("Variant assignments are determined by the user's AI classification. Assignments are stable — the same user always receives the same variant.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(demoExperimentKeys, id: \.self) { key in
                        ExperimentRow(
                            experimentKey: key,
                            assignment: assignments[key]
                        )
                        if key != demoExperimentKeys.last {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Real-Time Adaptation Card

    private var realTimeAdaptationCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "waveform.path.ecg.rectangle.fill", title: "Real-Time Adaptation")

                VStack(spacing: 10) {
                    AdaptationRow(
                        icon: "timer",
                        color: .blue,
                        title: "Debounced Pipeline",
                        detail: "Events are batched — the AI pipeline fires 2 s after the last event, not after every single event."
                    )
                    Divider().padding(.leading, 36)
                    AdaptationRow(
                        icon: "bolt.horizontal.fill",
                        color: .purple,
                        title: "Automatic Re-Evaluation",
                        detail: "Feature flags and experiment variants update instantly when a new prediction is ready — no manual refresh needed."
                    )
                    Divider().padding(.leading, 36)
                    AdaptationRow(
                        icon: "dot.radiowaves.right",
                        color: .green,
                        title: "AsyncStream Output",
                        detail: "viewModel.configurationStream emits a UIConfiguration value after each successful pipeline run for reactive consumers."
                    )
                }

                if let prediction = viewModel.viewState.prediction {
                    Divider()
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill").imageScale(.small)
                        Text("Last prediction: \(prediction.generatedAt, style: .relative) ago · \(Int(prediction.confidence * 100))% confidence")
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - State Refresh

    private func refreshState() async {
        for flag in demoFlags {
            flagStates[flag.key] = await flagRegistry.isEnabled(flag.key)
        }
        for key in demoExperimentKeys {
            assignments[key] = await experimentEngine.assignment(for: key)
        }
    }
}

// MARK: - Supporting Views

private struct FlagRow: View {
    let label: String
    let icon: String
    let color: Color
    let eligibleTypes: String
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isEnabled ? color : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(isEnabled ? .semibold : .regular))
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                Text("Eligible: \(eligibleTypes)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(isEnabled ? color : Color.secondary.opacity(0.3))
                    .frame(width: 7, height: 7)
                Text(isEnabled ? "ON" : "OFF")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isEnabled ? color : .secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(isEnabled ? color : .clear), in: .capsule)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct ExperimentRow: View {
    let experimentKey: String
    let assignment: ExperimentAssignment?

    var variantColor: Color {
        guard let v = assignment?.variant else { return .secondary }
        switch v {
        case "advanced", "simplified", "run_analysis": return .purple
        case "grid", "explore_more": return .teal
        case "get_started": return .orange
        case "standard", "default", "learn_more": return .secondary
        default: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(assignment != nil ? variantColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(experimentKey.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline.weight(.medium))
                if let userType = assignment?.userType {
                    Text("Classified as \(userType.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Pending prediction")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(assignment?.variant ?? "—")
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(variantColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .glassEffect(.regular.tint(assignment != nil ? variantColor : .clear), in: .capsule)
        }
        .padding(.vertical, 8)
    }
}

private struct AdaptationRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct UserTypePill: View {
    let userType: UserType

    private var color: Color {
        switch userType {
        case .power:   return .purple
        case .casual:  return .blue
        case .explorer: return .teal
        case .atRisk:  return .orange
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: userType.icon).imageScale(.small)
            Text(userType.rawValue)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .glassEffect(.regular.tint(color), in: .capsule)
    }
}

// MARK: - Preview

#Preview {
    let registry = AIAnalyticsContainer.makeFeatureFlagRegistry()
    let engine = AIAnalyticsContainer.makeExperimentEngine()
    NavigationStack {
        PersonalizationTab(flagRegistry: registry, experimentEngine: engine)
            .navigationTitle("Personalization")
    }
    .environment(AIAnalyticsContainer.makeHomeViewModel(flagRegistry: registry, experimentEngine: engine))
    .modelContainer(AIAnalyticsContainer.modelContainer)
}
