import FoundationInsights

/// Adapts `LogIntelligenceService` (the SDK actor) to `LogAnalysisDataSourceProtocol`.
/// This is the only file in the data layer that imports and references the SDK directly.
struct FoundationInsightsDataSource: LogAnalysisDataSourceProtocol {

    private let service: LogIntelligenceService

    init(service: LogIntelligenceService) {
        self.service = service
    }

    func analyze(logBatch: String) async throws -> LogSummary {
        try await service.analyze(logBatch: logBatch)
    }
}
