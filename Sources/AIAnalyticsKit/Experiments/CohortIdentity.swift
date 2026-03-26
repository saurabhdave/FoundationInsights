import Foundation

// MARK: - CohortIdentity

/// Generates a stable, device-local user cohort identifier.
///
/// Written once to `UserDefaults` and never changed. Used by `ExperimentEngine`
/// to produce deterministic variant assignments that are stable across app launches.
enum CohortIdentity {

    private static let defaultsKey = "com.aianalyticskit.cohortID"

    /// Returns the cohort ID, creating and persisting one on first call.
    static func cohortID() -> String {
        if let existing = UserDefaults.standard.string(forKey: defaultsKey) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: defaultsKey)
        return new
    }
}
