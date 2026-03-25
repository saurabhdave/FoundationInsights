import FoundationInsights
import FoundationModels
import SwiftUI

// MARK: - Preview Helpers

/// Mock use cases and sample data for SwiftUI previews.
/// Kept in a single file so every preview can reference the same fixtures.

enum PreviewHelpers {

    // MARK: - Mock Use Cases

    struct MockAnalyzeLogsUseCase: AnalyzeLogsUseCaseProtocol {
        var result: LogSummary

        func execute(logBatch: String) async throws -> LogSummary {
            result
        }
    }

    struct MockLoadSampleBatchUseCase: LoadSampleBatchUseCaseProtocol {
        func execute(for sample: SampleLogBatches.Sample) -> String {
            sample.logText
        }
    }

    // MARK: - LogSummary Construction

    /// Builds a `LogSummary` via `GeneratedContent` since `@Generable` does not
    /// synthesize a standard memberwise init.
    private static func makeSummary(
        urgency: String,
        summary: String,
        tags: [String],
        dominantErrorCode: String? = nil
    ) -> LogSummary {
        let urgencyContent = GeneratedContent(urgency)
        let summaryContent = GeneratedContent(summary)
        let tagsContent = GeneratedContent(elements: tags.map { GeneratedContent($0) })

        let errorCodeContent: GeneratedContent
        if let code = dominantErrorCode {
            errorCodeContent = GeneratedContent(code)
        } else {
            errorCodeContent = GeneratedContent(kind: .null)
        }

        let content = GeneratedContent(properties: [
            "urgency": urgencyContent,
            "summary": summaryContent,
            "tags": tagsContent,
            "dominantErrorCode": errorCodeContent,
        ])

        return try! LogSummary(content)
    }

    // MARK: - Sample Summaries

    static let highUrgencySummary = makeSummary(
        urgency: "High",
        summary: "Crash loop detected with EXC_BAD_ACCESS, repeated network timeouts, and auth token failure causing forced sign-out.",
        tags: ["crash", "networking", "auth"],
        dominantErrorCode: "EXC_BAD_ACCESS"
    )

    static let mediumUrgencySummary = makeSummary(
        urgency: "Medium",
        summary: "Degraded API performance with elevated latency and non-fatal JSON decode errors using fallback values.",
        tags: ["latency", "json", "memory"]
    )

    static let lowUrgencySummary = makeSummary(
        urgency: "Low",
        summary: "Routine operational activity including background refresh, analytics upload, and push token renewal.",
        tags: ["lifecycle", "analytics"]
    )

    // MARK: - ViewModel Factory

    @MainActor
    static func makeViewModel(
        summary: LogSummary = highUrgencySummary
    ) -> LogAnalysisViewModel {
        LogAnalysisViewModel(
            analyzeLogsUseCase: MockAnalyzeLogsUseCase(result: summary),
            loadSampleBatchUseCase: MockLoadSampleBatchUseCase()
        )
    }

    @MainActor
    static func makeSuccessViewModel() -> LogAnalysisViewModel {
        let vm = makeViewModel(summary: highUrgencySummary)
        vm.viewState = .success(highUrgencySummary)
        return vm
    }

    @MainActor
    static func makeErrorViewModel() -> LogAnalysisViewModel {
        let vm = makeViewModel()
        vm.viewState = .failure("The on-device model is not available on this simulator.")
        return vm
    }
}
