import Foundation

// MARK: - Protocol

/// Contract for tracking analytics events.
/// Conform to this protocol to swap in test recorders or third-party SDKs.
protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent) async
    func trackBatch(_ events: [AnalyticsEvent]) async
}
