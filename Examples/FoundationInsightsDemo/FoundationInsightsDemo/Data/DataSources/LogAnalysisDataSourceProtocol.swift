import FoundationInsights

/// Abstracts the low-level analysis API.
/// Swap this out for a mock to test the repository without touching FoundationInsights.
protocol LogAnalysisDataSourceProtocol: Sendable {
    func analyze(logBatch: String) async throws -> LogSummary
}
