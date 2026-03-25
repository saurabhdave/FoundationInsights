import Foundation
import Observation
import FoundationInsights

@Observable
@MainActor
final class LogAnalysisViewModel {

    // MARK: - Dependencies

    let service: LogIntelligenceService

    // MARK: - State

    var logText: String = SampleLogBatches.highUrgency
    var selectedSample: SampleLogBatches.Sample = .highUrgency
    var result: LogSummary? = nil
    var isAnalyzing: Bool = false
    var errorMessage: String? = nil

    // MARK: - Init

    init(service: LogIntelligenceService) {
        self.service = service
    }

    // MARK: - Actions

    func selectSample(_ sample: SampleLogBatches.Sample) {
        selectedSample = sample
        logText = sample.logText
        result = nil
        errorMessage = nil
    }

    func analyze() async {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        result = nil
        errorMessage = nil

        do {
            result = try await service.analyze(logBatch: logText)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }
}
