import Foundation

// MARK: - View State

/// Explicit view state for the AI Insights home screen.
public enum HomeViewState: Sendable {
    case idle
    case loading
    case ready(UIConfiguration, UserPrediction)
    case failure(String)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var configuration: UIConfiguration? {
        if case .ready(let config, _) = self { return config }
        return nil
    }

    public var prediction: UserPrediction? {
        if case .ready(_, let prediction) = self { return prediction }
        return nil
    }

    public var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}
