import FoundationInsights

/// Default repository implementation.
/// Thin pass-through to the data source — exists to decouple domain use cases
/// from the concrete SDK data source.
struct DefaultLogAnalysisRepository: LogAnalysisRepositoryProtocol {

    private let dataSource: any LogAnalysisDataSourceProtocol

    init(dataSource: some LogAnalysisDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func analyze(logBatch: String) async throws -> LogSummary {
        try await dataSource.analyze(logBatch: logBatch)
    }
}
