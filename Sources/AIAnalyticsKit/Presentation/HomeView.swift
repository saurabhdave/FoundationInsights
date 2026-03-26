import SwiftUI

// MARK: - Home View

/// AI-personalized home screen that adapts based on user behavior predictions.
/// Demonstrates the full data flow:
///   User Action → AnalyticsManager → Event Store → Feature Builder
///     → AI Engine → Personalization Engine → Dynamic SwiftUI UI
public struct HomeView: View {

    @Environment(HomeViewModel.self) private var viewModel
    @State private var selectedAction: UIConfiguration.RecommendedAction?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusCard

                actionButtons

                if let message = viewModel.viewState.errorMessage {
                    ErrorBanner(message: message)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let config = viewModel.viewState.configuration,
                   let prediction = viewModel.viewState.prediction {
                    predictionCard(prediction: prediction, config: config)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    recommendationsSection(config: config)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8),
                       value: viewModel.viewState.configuration != nil)
            .animation(.easeInOut(duration: 0.2),
                       value: viewModel.viewState.errorMessage != nil)
        }
        .contentMargins(.top, 8, for: .scrollContent)
        #if !os(macOS)
        .scrollDismissesKeyboard(.immediately)
        #endif
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadInsights()
        }
        .alert(
            selectedAction?.title ?? "",
            isPresented: Binding(
                get: { selectedAction != nil },
                set: { if !$0 { selectedAction = nil } }
            )
        ) {
            Button("OK") { selectedAction = nil }
        } message: {
            Text(selectedAction?.subtitle ?? "")
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(icon: "chart.bar.fill", title: "Analytics Status")

                HStack {
                    Label("\(viewModel.eventCount) events tracked", systemImage: "number.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if viewModel.viewState.isLoading {
                        ProgressView()
                            .scaleEffect(0.85)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.trackSampleEvents() }
            } label: {
                Label("Add Events", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .disabled(viewModel.viewState.isLoading)

            Button {
                Task { await viewModel.loadInsights() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
            .disabled(viewModel.viewState.isLoading)
        }
    }

    // MARK: - Prediction Card

    private func predictionCard(prediction: UserPrediction, config: UIConfiguration) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    SectionHeader(icon: "brain.fill", title: "User Profile")
                    Spacer()
                    Text(prediction.userType.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(config.accentColor)
                        .glassEffect(.regular.tint(config.accentColor), in: .capsule)
                }

                HStack(spacing: 12) {
                    Image(systemName: prediction.userType.icon)
                        .font(.title2)
                        .foregroundStyle(config.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(config.greeting)
                            .font(.headline)
                        Text(prediction.userType.typeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.needle.fill")
                        .foregroundStyle(.secondary)
                    Text("Confidence: \(Int(prediction.confidence * 100))%")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: .rect(cornerRadius: 8))

                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                        .imageScale(.small)
                    Text("Predicted entirely on-device")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Recommendations

    private func recommendationsSection(config: UIConfiguration) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(icon: "lightbulb.fill", title: "Recommended for You")

                ForEach(config.recommendedActions) { action in
                    Button {
                        selectedAction = action
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .foregroundStyle(config.accentColor)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(action.title)
                                    .font(.subheadline.weight(.medium))
                                Text(action.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }

                if config.showAdvancedFeatures {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .imageScale(.small)
                        Text("Advanced features unlocked")
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Idle") {
    NavigationStack {
        HomeView()
            .navigationTitle("AI Insights")
    }
    .environment(AIAnalyticsContainer.makeHomeViewModel())
}
