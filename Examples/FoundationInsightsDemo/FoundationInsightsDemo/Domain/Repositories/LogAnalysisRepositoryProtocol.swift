import FoundationInsights

/// Defines the contract for fetching on-device log analysis results.
/// Conform to this protocol to swap FoundationInsights for a mock in unit tests.
protocol LogAnalysisRepositoryProtocol: Sendable {
    func analyze(logBatch: String) async throws -> LogSummary
}
