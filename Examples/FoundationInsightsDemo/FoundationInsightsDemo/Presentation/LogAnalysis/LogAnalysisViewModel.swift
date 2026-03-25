import Foundation
import Observation

// MARK: - ViewModel

/// Owns all mutable state for the log analysis screen.
/// Depends only on protocols — swap in mocks for unit tests without touching the view.
@Observable
@MainActor
final class LogAnalysisViewModel {

    // MARK: - Dependencies

    private let analyzeLogsUseCase: any AnalyzeLogsUseCaseProtocol
    private let loadSampleBatchUseCase: any LoadSampleBatchUseCaseProtocol

    // MARK: - Published State

    var viewState: LogAnalysisViewState = .idle
    var logText: String
    var selectedSample: SampleLogBatches.Sample

    // MARK: - Init

    init(
        analyzeLogsUseCase: some AnalyzeLogsUseCaseProtocol,
        loadSampleBatchUseCase: some LoadSampleBatchUseCaseProtocol
    ) {
        self.analyzeLogsUseCase = analyzeLogsUseCase
        self.loadSampleBatchUseCase = loadSampleBatchUseCase
        let defaultSample = SampleLogBatches.Sample.highUrgency
        self.selectedSample = defaultSample
        self.logText = loadSampleBatchUseCase.execute(for: defaultSample)
    }

    // MARK: - Actions

    func selectSample(_ sample: SampleLogBatches.Sample) {
        selectedSample = sample
        logText = loadSampleBatchUseCase.execute(for: sample)
        viewState = .idle
    }

    func analyze() async {
        guard !viewState.isLoading else { return }
        viewState = .loading
        do {
            let summary = try await analyzeLogsUseCase.execute(logBatch: logText)
            viewState = .success(summary)
        } catch {
            viewState = .failure(error.localizedDescription)
        }
    }
}
