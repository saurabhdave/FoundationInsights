import Foundation
import OSLog

// MARK: - LogAnalyticsCoordinator
//
// Thin coordinator that shows how a ViewModel or UseCase layer would
// call LogIntelligenceService and handle the two-path response.

public final class LogAnalyticsCoordinator {

    private let service: LogIntelligenceService
    private let logger = Logger(subsystem: "com.app.FoundationInsights",
                                category: "LogAnalyticsCoordinator")

    public init(service: LogIntelligenceService) {
        self.service = service
    }

    /// Collects the last N log entries from OSLog and submits them for analysis.
    public func runAnalysis(logBatch: String) async {
        do {
            let summary = try await service.analyze(logBatch: logBatch)
            handleSummary(summary)
        } catch {
            logger.error("Analysis failed: \(error)")
        }
    }

    private func handleSummary(_ summary: LogSummary) {
        logger.info("""
            ── Log Batch Summary ──────────────────────
            Urgency : \(summary.urgency.rawValue)
            Summary : \(summary.summary)
            Tags    : \(summary.tags.joined(separator: ", "))
            Error   : \(summary.dominantErrorCode ?? "none")
            ───────────────────────────────────────────
            """)

        // Route high-urgency batches to your crash reporter / analytics pipeline.
        if summary.urgency == .high {
            NotificationCenter.default.post(
                name: .highUrgencyLogsDetected,
                object: summary
            )
        }
    }
}

public extension Notification.Name {
    static let highUrgencyLogsDetected = Notification.Name(
        "com.app.FoundationInsights.highUrgencyLogsDetected"
    )
}
