import SwiftUI
import AIAnalyticsKit

// MARK: - Events Tab

struct EventsTab: View {

    @Environment(HomeViewModel.self) private var viewModel

    private var navCount: Int        { viewModel.recentEvents.filter { $0.category == .navigation }.count }
    private var interactionCount: Int { viewModel.recentEvents.filter { $0.category == .interaction }.count }
    private var analysisCount: Int   { viewModel.recentEvents.filter { $0.category == .analysis }.count }
    private var errorCount: Int      { viewModel.recentEvents.filter { $0.category == .error }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                categoryBreakdownCard
                quickTrackCard
                scenariosCard
                if !viewModel.recentEvents.isEmpty {
                    eventHistoryCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.eventCount)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "chart.bar.fill", title: "Event Breakdown")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    CategoryStatView(label: "Navigation", count: navCount,
                                     icon: "arrow.right.circle.fill", color: .blue)
                    CategoryStatView(label: "Interaction", count: interactionCount,
                                     icon: "hand.tap.fill", color: .green)
                    CategoryStatView(label: "Analysis", count: analysisCount,
                                     icon: "waveform", color: .purple)
                    CategoryStatView(label: "Errors", count: errorCount,
                                     icon: "exclamationmark.triangle.fill", color: .red)
                }
            }
        }
    }

    // MARK: - Quick Track

    private var quickTrackCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "plus.circle.fill", title: "Quick Log")

                // Static API — call from anywhere, no ViewModel or await needed.
                Text("AIAnalytics.logEvent() — fire-and-forget, works from any file or actor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    QuickTrackButton(label: "Navigation", icon: "arrow.right.circle.fill", color: .blue) {
                        let screens = ["home", "dashboard", "analytics", "reports", "settings", "profile", "export"]
                        let screen = screens[navCount % screens.count]
                        // Static call — no Task, no await, no ViewModel reference needed.
                        AIAnalytics.logEvent("screen_viewed", parameters: ["screen": screen])
                        Task { await viewModel.loadInsights() }
                    }
                    QuickTrackButton(label: "Interaction", icon: "hand.tap.fill", color: .green) {
                        AIAnalytics.logEvent("button_tapped", parameters: ["element": "primary_cta"])
                        Task { await viewModel.loadInsights() }
                    }
                    QuickTrackButton(label: "Analysis", icon: "waveform", color: .purple) {
                        AIAnalytics.logEvent("analysis_started", parameters: ["type": "on_demand"])
                        Task { await viewModel.loadInsights() }
                    }
                    QuickTrackButton(label: "Error", icon: "exclamationmark.triangle.fill", color: .red) {
                        AIAnalytics.logEvent("network_error", parameters: ["code": "408"])
                        Task { await viewModel.loadInsights() }
                    }
                }
                .disabled(viewModel.viewState.isLoading)
            }
        }
    }

    // MARK: - Simulation Scenarios

    private var scenariosCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(icon: "sparkles", title: "Simulate Behavior")
                Text("Apply a realistic event pattern to trigger a specific user type classification.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ScenarioButton(
                        title: "Power User Pattern",
                        subtitle: "57 events · 15 analyses · 6 screens",
                        icon: "bolt.fill",
                        color: .purple
                    ) { await applyScenario(DemoScenarios.powerUser) }

                    ScenarioButton(
                        title: "Explorer Pattern",
                        subtitle: "28 events · 7 unique screens",
                        icon: "safari.fill",
                        color: .teal
                    ) { await applyScenario(DemoScenarios.explorer) }

                    ScenarioButton(
                        title: "At-Risk Pattern",
                        subtitle: "15 events · 33% error rate",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    ) { await applyScenario(DemoScenarios.atRisk) }

                    Divider()

                    ScenarioButton(
                        title: "Reset All Events",
                        subtitle: "Clear all data and start fresh",
                        icon: "trash.fill",
                        color: Color(.systemGray)
                    ) { await viewModel.clearAllEvents() }
                }
                .disabled(viewModel.viewState.isLoading)
            }
        }
    }

    private func applyScenario(_ events: [AnalyticsEvent]) async {
        await viewModel.clearAllEvents()
        await viewModel.trackEvents(events)
    }

    // MARK: - Event History

    private var eventHistoryCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(icon: "clock.fill", title: "Recent Events")
                    Spacer()
                    Text("\(viewModel.eventCount) total")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                ForEach(viewModel.recentEvents.prefix(20)) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.category.demoIcon)
                            .foregroundStyle(event.category.demoColor)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            if !event.properties.isEmpty {
                                Text(event.properties.map { "\($0.key): \($0.value)" }.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 4)

                        Text(event.timestamp, style: .relative)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.quaternary)
                    }
                    .padding(.vertical, 1)
                }

                if viewModel.recentEvents.count > 20 {
                    Text("+ \(viewModel.recentEvents.count - 20) earlier events not shown")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct CategoryStatView: View {
    let label: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct QuickTrackButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.footnote)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ScenarioButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
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
}

// MARK: - Demo Scenarios

private enum DemoScenarios {

    static let powerUser: [AnalyticsEvent] = {
        let screens = ["home", "dashboard", "analytics", "reports", "settings", "export"]
        var events: [AnalyticsEvent] = []

        // 18 navigation events across 6 screens
        for (i, screen) in (screens + screens + screens).prefix(18).enumerated() {
            events.append(AnalyticsEvent(
                name: "screen_viewed",
                category: .navigation,
                properties: ["screen": screen],
                timestamp: .now.addingTimeInterval(Double(-i * 120))
            ))
        }
        // 15 analysis events
        let analysisNames = ["log_analysis_started", "batch_analysis_run", "report_generated",
                             "export_triggered", "deep_scan_run"]
        for i in 0..<15 {
            events.append(AnalyticsEvent(
                name: analysisNames[i % analysisNames.count],
                category: .analysis,
                properties: ["depth": "full"],
                timestamp: .now.addingTimeInterval(Double(-i * 90))
            ))
        }
        // 22 interaction events
        let interactions = ["filter_applied", "item_selected", "search_performed",
                            "sort_changed", "refresh_triggered"]
        for i in 0..<22 {
            events.append(AnalyticsEvent(
                name: interactions[i % interactions.count],
                category: .interaction,
                timestamp: .now.addingTimeInterval(Double(-i * 60))
            ))
        }
        // 2 error events (≈3.5% rate)
        events.append(AnalyticsEvent(name: "parse_warning", category: .error))
        events.append(AnalyticsEvent(name: "cache_miss", category: .error))
        return events
    }()

    static let explorer: [AnalyticsEvent] = {
        var events: [AnalyticsEvent] = []
        // 20 navigation events across 7 screens
        let screens = ["home", "discover", "analytics", "settings", "profile", "filters", "export"]
        for (i, screen) in (screens + screens + screens).prefix(20).enumerated() {
            events.append(AnalyticsEvent(
                name: "screen_viewed",
                category: .navigation,
                properties: ["screen": screen],
                timestamp: .now.addingTimeInterval(Double(-i * 100))
            ))
        }
        // 5 interactions
        for i in 0..<5 {
            events.append(AnalyticsEvent(
                name: "feature_discovered",
                category: .interaction,
                properties: ["feature": "feature_\(i)"],
                timestamp: .now.addingTimeInterval(Double(-i * 80))
            ))
        }
        // 2 analysis, 1 error (3.6% error rate)
        events.append(AnalyticsEvent(name: "quick_scan", category: .analysis))
        events.append(AnalyticsEvent(name: "trial_analysis", category: .analysis))
        events.append(AnalyticsEvent(name: "connection_retry", category: .error))
        return events
    }()

    static let atRisk: [AnalyticsEvent] = {
        var events: [AnalyticsEvent] = []
        // 5 navigation events (2 screens)
        for i in 0..<5 {
            events.append(AnalyticsEvent(
                name: "screen_viewed",
                category: .navigation,
                properties: ["screen": i % 2 == 0 ? "home" : "settings"],
                timestamp: .now.addingTimeInterval(Double(-i * 300))
            ))
        }
        // 3 interactions
        for i in 0..<3 {
            events.append(AnalyticsEvent(
                name: "button_tapped",
                category: .interaction,
                timestamp: .now.addingTimeInterval(Double(-i * 200))
            ))
        }
        // 2 analysis
        events.append(AnalyticsEvent(name: "failed_analysis", category: .analysis))
        events.append(AnalyticsEvent(name: "partial_scan", category: .analysis))
        // 5 error events → 33% error rate (5/15)
        let errors = ["network_timeout", "auth_failure", "parse_error", "crash_recovered", "sync_failed"]
        for (i, name) in errors.enumerated() {
            events.append(AnalyticsEvent(
                name: name,
                category: .error,
                timestamp: .now.addingTimeInterval(Double(-i * 150))
            ))
        }
        return events
    }()
}

// MARK: - EventCategory Display Helpers

extension AnalyticsEvent.EventCategory {
    var demoIcon: String {
        switch self {
        case .navigation:   return "arrow.right.circle.fill"
        case .interaction:  return "hand.tap.fill"
        case .analysis:     return "waveform"
        case .error:        return "exclamationmark.triangle.fill"
        }
    }

    var demoColor: Color {
        switch self {
        case .navigation:   return .blue
        case .interaction:  return .green
        case .analysis:     return .purple
        case .error:        return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventsTab()
            .navigationTitle("Events")
    }
    .environment(AIAnalyticsContainer.makeHomeViewModel())
    .modelContainer(AIAnalyticsContainer.modelContainer)
}
