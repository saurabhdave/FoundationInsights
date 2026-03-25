import FoundationInsights

// MARK: - Protocol

/// Contract for the analyze-logs business operation.
/// Inject a mock conformance in tests to verify ViewModel behaviour independently.
protocol AnalyzeLogsUseCaseProtocol: Sendable {
    func execute(logBatch: String) async throws -> LogSummary
}

// MARK: - Default Implementation

/// Validates input, wraps thrown errors into domain types, then delegates to the repository.
struct AnalyzeLogsUseCase: AnalyzeLogsUseCaseProtocol {

    private let repository: any LogAnalysisRepositoryProtocol

    init(repository: some LogAnalysisRepositoryProtocol) {
        self.repository = repository
    }

    func execute(logBatch: String) async throws -> LogSummary {
        guard !logBatch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LogAnalysisError.emptyBatch
        }
        do {
            return try await repository.analyze(logBatch: logBatch)
        } catch let error as LogAnalysisError {
            throw error
        } catch {
            throw LogAnalysisError.analysisFailure(underlying: error)
        }
    }
}
