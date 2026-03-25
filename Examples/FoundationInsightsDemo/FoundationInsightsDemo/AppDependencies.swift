import FoundationInsights

/// Composition root — the single place in the app that knows about concrete types.
///
/// Views and ViewModels depend only on protocols; this factory wires up the full
/// object graph at launch. To test with mocks, provide alternate implementations
/// of `AnalyzeLogsUseCaseProtocol` / `LogAnalysisRepositoryProtocol` instead of
/// calling this factory.
@MainActor
enum AppDependencies {

    static func makeLogAnalysisViewModel() -> LogAnalysisViewModel {
        let service = LogIntelligenceService()
        let dataSource = FoundationInsightsDataSource(service: service)
        let repository = DefaultLogAnalysisRepository(dataSource: dataSource)
        return LogAnalysisViewModel(
            analyzeLogsUseCase: AnalyzeLogsUseCase(repository: repository),
            loadSampleBatchUseCase: LoadSampleBatchUseCase()
        )
    }
}
