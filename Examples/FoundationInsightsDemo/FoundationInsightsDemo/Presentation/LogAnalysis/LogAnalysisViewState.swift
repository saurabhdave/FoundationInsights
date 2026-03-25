import FoundationInsights

/// Explicit view state — one source of truth instead of three scattered properties
/// (isLoading Bool, result optional, errorMessage optional).
enum LogAnalysisViewState {
    case idle
    case loading
    case success(LogSummary)
    case failure(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var result: LogSummary? {
        if case .success(let summary) = self { return summary }
        return nil
    }

    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}
