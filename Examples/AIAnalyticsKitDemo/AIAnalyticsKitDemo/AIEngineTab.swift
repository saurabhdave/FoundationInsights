import SwiftUI
import AIAnalyticsKit

// MARK: - AI Engine Tab

struct AIEngineTab: View {

    @Environment(HomeViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                modelStatusCard
                if let prediction = viewModel.viewState.prediction,
                   let features = viewModel.currentFeatures {
                    predictionDetailCard(prediction: prediction)
                    featureAttributionCard(features: features, prediction: prediction)
                } else {
                    pendingPredictionCard
                }
                privacyCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Model Status

    private var modelStatusCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "cpu.fill", title: "On-Device AI Engine")

                HStack(spacing: 14) {
                    Image(systemName: "brain.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .frame(width: 52, height: 52)
                        .glassEffect(.regular.tint(.purple), in: .circle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Foundation Models")
                            .font(.headline)
                        Text("Apple · SystemLanguageModel(.general)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusPill(label: "Active", color: .green)
                }

                Divider()

                VStack(spacing: 8) {
                    EngineInfoRow(label: "Framework", value: "FoundationModels")
                    EngineInfoRow(label: "Use Case", value: ".general")
                    EngineInfoRow(label: "Fallback", value: "Heuristic (simulator)")
                    EngineInfoRow(label: "Network Required", value: "No")
                    EngineInfoRow(label: "Data Egress", value: "None")
                }
            }
        }
    }

    // MARK: - Prediction Detail

    private func predictionDetailCard(prediction: UserPrediction) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "gauge.with.needle.fill", title: "Last Prediction")

                HStack(spacing: 16) {
                    Image(systemName: prediction.userType.icon)
                        .font(.largeTitle)
                        .foregroundStyle(viewModel.viewState.configuration?.accentColor ?? .secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(prediction.userType.rawValue)
                            .font(.title3.weight(.bold))
                        Text(prediction.userType.typeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 10) {
                    HStack {
                        Text("Confidence")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(prediction.confidence * 100))%")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.12))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            viewModel.viewState.configuration?.accentColor.opacity(0.6) ?? .purple.opacity(0.6),
                                            viewModel.viewState.configuration?.accentColor ?? .purple
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * prediction.confidence)
                                .animation(.spring(response: 0.6), value: prediction.confidence)
                        }
                    }
                    .frame(height: 8)
                }

                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .imageScale(.small)
                    Text("Generated \(prediction.generatedAt, style: .relative) ago")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Feature Attribution

    private func featureAttributionCard(features: UserFeatures, prediction: UserPrediction) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "list.bullet.rectangle.fill", title: "Feature Attribution")
                Text("Which features drove the \"\(prediction.userType.rawValue)\" classification:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(attributionDrivers(features: features, prediction: prediction)) { driver in
                        AttributionRow(driver: driver)
                    }
                }
            }
        }
    }

    private func attributionDrivers(features: UserFeatures, prediction: UserPrediction) -> [AttributionDriver] {
        [
            AttributionDriver(
                id: "error",
                label: "Error Rate",
                detail: "\(Int(features.errorRate * 100))% of events failed",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                isActive: prediction.userType == .atRisk,
                impact: features.errorRate > ClassificationConfig.atRiskErrorRate ? .decisive : .neutral
            ),
            AttributionDriver(
                id: "activity",
                label: "High Activity",
                detail: "\(features.totalEvents) events, \(features.analysisCount) analyses",
                icon: "bolt.fill",
                color: .purple,
                isActive: prediction.userType == .power,
                impact: (features.totalEvents > ClassificationConfig.powerUserMinEvents && features.analysisCount > ClassificationConfig.powerUserMinAnalyses) ? .decisive : .neutral
            ),
            AttributionDriver(
                id: "screens",
                label: "Screen Breadth",
                detail: "\(features.uniqueScreens) unique screens explored",
                icon: "safari.fill",
                color: .teal,
                isActive: prediction.userType == .explorer,
                impact: features.uniqueScreens > ClassificationConfig.explorerMinScreens ? .supporting : .neutral
            ),
            AttributionDriver(
                id: "moderate",
                label: "Moderate Usage",
                detail: "No dominant signal detected",
                icon: "leaf.fill",
                color: .blue,
                isActive: prediction.userType == .casual,
                impact: prediction.userType == .casual ? .decisive : .neutral
            ),
        ]
    }

    // MARK: - Pending State

    private var pendingPredictionCard: some View {
        CardContainer {
            VStack(spacing: 16) {
                Image(systemName: "brain.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.quaternary)
                VStack(spacing: 6) {
                    Text("Prediction Pending")
                        .font(.headline)
                    Text("Go to the Insights tab and tap Refresh to run a prediction, then come back here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Privacy Card

    private var privacyCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "lock.shield.fill", title: "Privacy Guarantees")

                VStack(spacing: 10) {
                    PrivacyRow(icon: "xmark.icloud.fill", text: "No network requests — ever")
                    PrivacyRow(icon: "internaldrive.fill",  text: "All inference runs on the Neural Engine")
                    PrivacyRow(icon: "eye.slash.fill",      text: "Event data never leaves the device")
                    PrivacyRow(icon: "lock.fill",           text: "SwiftData store is sandboxed to the app")
                }
            }
        }
    }
}

// MARK: - Supporting Types & Views

private struct AttributionDriver: Identifiable {
    let id: String
    let label: String
    let detail: String
    let icon: String
    let color: Color
    let isActive: Bool

    enum Impact { case decisive, supporting, neutral }
    let impact: Impact
}

private struct AttributionRow: View {
    let driver: AttributionDriver

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: driver.icon)
                .foregroundStyle(driver.isActive ? driver.color : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(driver.label)
                    .font(.subheadline.weight(driver.isActive ? .semibold : .regular))
                    .foregroundStyle(driver.isActive ? .primary : .secondary)
                Text(driver.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if driver.impact == .decisive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(driver.color)
                    .imageScale(.small)
            } else {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.quaternary)
                    .imageScale(.small)
            }
        }
        .padding(.vertical, 2)
        .opacity(driver.isActive || driver.impact != .neutral ? 1.0 : 0.45)
    }
}

private struct StatusPill: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundStyle(color)
        .glassEffect(.regular.tint(color))
    }
}

private struct EngineInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium).monospaced())
        }
    }
}

private struct PrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIEngineTab()
            .navigationTitle("AI Engine")
    }
    .environment(AIAnalyticsContainer.makeHomeViewModel())
    .modelContainer(AIAnalyticsContainer.modelContainer)
}
