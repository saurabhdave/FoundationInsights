import SwiftUI
import AIAnalyticsKit

// MARK: - Features Tab

struct FeaturesTab: View {

    @Environment(HomeViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let features = viewModel.currentFeatures {
                    pipelineCard
                    metricsCard(features: features)
                    thresholdsCard
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pipeline Card

    private var pipelineCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "arrow.forward.circle.fill", title: "AI Pipeline")
                HStack(spacing: 0) {
                    PipelineStep(icon: "list.bullet", label: "Events", value: "\(viewModel.eventCount)", color: .blue)
                    PipelineArrow()
                    PipelineStep(icon: "waveform.path", label: "Features", value: "6", color: .purple)
                    PipelineArrow()
                    PipelineStep(icon: "brain.fill", label: "Predict", value: predictionLabel, color: predictionColor)
                }
            }
        }
    }

    private var predictionLabel: String {
        viewModel.viewState.prediction?.userType.rawValue.components(separatedBy: " ").first ?? "—"
    }

    private var predictionColor: Color {
        viewModel.viewState.configuration?.accentColor ?? .secondary
    }

    // MARK: - Metrics Card

    private func metricsCard(features: UserFeatures) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(icon: "waveform.path", title: "Extracted Features")

                FeatureMetricRow(
                    name: "Total Events",
                    value: "\(features.totalEvents)",
                    progress: min(Double(features.totalEvents) / 100.0, 1.0),
                    statusLabel: features.totalEvents > ClassificationConfig.powerUserMinEvents ? "High" : features.totalEvents > 10 ? "Moderate" : "Low",
                    statusColor: features.totalEvents > ClassificationConfig.powerUserMinEvents ? .green : features.totalEvents > 10 ? .orange : .red
                )
                FeatureMetricRow(
                    name: "Unique Screens",
                    value: "\(features.uniqueScreens)",
                    progress: min(Double(features.uniqueScreens) / 10.0, 1.0),
                    statusLabel: features.uniqueScreens > ClassificationConfig.explorerMinScreens ? "Explorer" : features.uniqueScreens > 2 ? "Normal" : "Low",
                    statusColor: features.uniqueScreens > ClassificationConfig.explorerMinScreens ? .teal : features.uniqueScreens > 2 ? .orange : .red
                )
                FeatureMetricRow(
                    name: "Analysis Count",
                    value: "\(features.analysisCount)",
                    progress: min(Double(features.analysisCount) / 20.0, 1.0),
                    statusLabel: features.analysisCount > ClassificationConfig.powerUserMinAnalyses ? "Power" : features.analysisCount > 3 ? "Active" : "Low",
                    statusColor: features.analysisCount > ClassificationConfig.powerUserMinAnalyses ? .purple : features.analysisCount > 3 ? .orange : .secondary
                )
                FeatureMetricRow(
                    name: "Error Rate",
                    value: "\(Int(features.errorRate * 100))%",
                    progress: min(features.errorRate / 0.5, 1.0),
                    statusLabel: features.errorRate > ClassificationConfig.atRiskErrorRate ? "At-Risk" : features.errorRate > 0.1 ? "Watch" : "Healthy",
                    statusColor: features.errorRate > ClassificationConfig.atRiskErrorRate ? .red : features.errorRate > 0.1 ? .orange : .green
                )

                Divider()

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Days Active")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(features.daysSinceFirstEvent)")
                            .font(.title3.weight(.semibold).monospacedDigit())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Avg Session")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(features.averageSessionDuration > 0
                             ? String(format: "%.0fs", features.averageSessionDuration)
                             : "—")
                            .font(.title3.weight(.semibold).monospacedDigit())
                    }
                }
            }
        }
    }

    // MARK: - Thresholds Card

    private var thresholdsCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "slider.horizontal.3", title: "Classification Rules")
                Text("The feature vector is evaluated against these rules in priority order.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ThresholdRow(
                        icon: "exclamationmark.triangle.fill", color: .orange,
                        userType: "At-Risk",
                        rule: "Error Rate > \(Int(ClassificationConfig.atRiskErrorRate * 100))%"
                    )
                    ThresholdRow(
                        icon: "bolt.fill", color: .purple,
                        userType: "Power User",
                        rule: "Total Events > \(ClassificationConfig.powerUserMinEvents) AND Analyses > \(ClassificationConfig.powerUserMinAnalyses)"
                    )
                    ThresholdRow(
                        icon: "safari.fill", color: .teal,
                        userType: "Explorer",
                        rule: "Unique Screens > \(ClassificationConfig.explorerMinScreens)"
                    )
                    ThresholdRow(
                        icon: "leaf.fill", color: .blue,
                        userType: "Casual",
                        rule: "All other patterns"
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        CardContainer {
            VStack(spacing: 16) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 40))
                    .foregroundStyle(.quaternary)
                VStack(spacing: 6) {
                    Text("No Features Yet")
                        .font(.headline)
                    Text("Track some events on the Events tab, then refresh Insights to compute the feature vector.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Supporting Views

private struct PipelineStep: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PipelineArrow: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }
}

private struct FeatureMetricRow: View {
    let name: String
    let value: String
    let progress: Double
    let statusLabel: String
    let statusColor: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                Text(statusLabel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .foregroundStyle(statusColor)
                    .glassEffect(.regular.tint(statusColor))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.12))
                    Capsule().fill(statusColor.opacity(0.7))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)
        }
    }
}

private struct ThresholdRow: View {
    let icon: String
    let color: Color
    let userType: String
    let rule: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(userType)
                    .font(.subheadline.weight(.medium))
                Text(rule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeaturesTab()
            .navigationTitle("Feature Vector")
    }
    .environment(AIAnalyticsContainer.makeHomeViewModel())
    .modelContainer(AIAnalyticsContainer.modelContainer)
}
