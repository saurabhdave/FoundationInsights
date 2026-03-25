import Foundation

/// Domain-level errors propagated from the log analysis pipeline.
enum LogAnalysisError: LocalizedError {
    case emptyBatch
    case analysisFailure(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .emptyBatch:
            return "Log batch is empty. Add some log entries before analyzing."
        case .analysisFailure(let error):
            return error.localizedDescription
        }
    }
}
