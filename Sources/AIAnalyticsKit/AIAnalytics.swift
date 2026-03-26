import Foundation
import OSLog
import SwiftData

// MARK: - AIAnalytics Static Facade

/// Firebase-style static entry point for AIAnalyticsKit.
///
/// **Quick start:**
/// ```swift
/// // App.swift — one modifier wires everything
/// @main struct MyApp: App {
///     var body: some Scene {
///         WindowGroup { ContentView() }
///             .aiAnalytics()
///     }
/// }
///
/// // Log events from anywhere — no await, no ViewModel needed
/// AIAnalytics.logEvent("button_tapped", parameters: ["id": "cta"])
/// AIAnalytics.logEvent("purchase", parameters: ["product": "premium", "price": 9.99])
/// AIAnalytics.logScreenView("HomeScreen")
/// ```
///
/// Events are persisted on-device via SwiftData and fed into the on-device
/// AI classification pipeline. The AI engine classifies users as Casual,
/// Explorer, Power, or At-Risk — entirely on-device, no data egress.
public enum AIAnalytics {

    // MARK: - Internal Shared State

    /// Written exactly once during `_configure()` from the `@MainActor`.
    /// Read from any context after setup. `nonisolated(unsafe)` is safe here
    /// because of write-once semantics: configure is guarded and always called
    /// before any `logEvent()` can arrive from the UI.
    nonisolated(unsafe) static var _manager: AnalyticsManager?

    private static let logger = Logger(subsystem: "com.aianalyticskit", category: "AIAnalytics")

    // MARK: - Validation limits
    private static let maxEventNameLength = 256
    private static let maxParameterKeyLength = 128
    private static let maxParameterValueLength = 512

    // MARK: - Configuration (called by .aiAnalytics() modifier)

    @MainActor
    static func _configure() {
        guard _manager == nil else { return }
        _manager = AIAnalyticsContainer.makeAnalyticsManager()
    }

    // MARK: - Public API

    /// Logs an event by name with optional parameters.
    ///
    /// - Parameters:
    ///   - name: Event name (e.g. `"button_tapped"`, `"screen_viewed"`).
    ///     Category is inferred automatically from the name — no enum needed.
    ///   - parameters: Key-value metadata. Values are coerced to `String`.
    ///
    /// Fire-and-forget — no `await` or `Task` needed at the call site.
    /// Silently dropped if called before `.aiAnalytics()` sets up the scene
    /// (same behaviour as Firebase Analytics before `FirebaseApp.configure()`).
    public static func logEvent(_ name: String, parameters: [String: Any] = [:]) {
        guard let manager = _manager else { return }

        // Validate event name — must be non-empty and within length limit.
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            logger.warning("logEvent called with empty name — event dropped")
            return
        }
        let validName = trimmedName.count <= maxEventNameLength
            ? trimmedName
            : String(trimmedName.prefix(maxEventNameLength))

        // Convert [String: Any] → [String: String] before the Task so only
        // Sendable types are captured in the closure (Swift 6 safe).
        // Keys and values are truncated to their respective length limits.
        let stringParams = parameters.reduce(into: [String: String]()) { result, pair in
            guard !pair.key.isEmpty else { return }
            let key = pair.key.count <= maxParameterKeyLength
                ? pair.key
                : String(pair.key.prefix(maxParameterKeyLength))
            let raw = "\(pair.value)"
            let value = raw.count <= maxParameterValueLength
                ? raw
                : String(raw.prefix(maxParameterValueLength))
            result[key] = value
        }

        let event = AnalyticsEvent(
            name: validName,
            category: inferCategory(from: validName),
            properties: stringParams
        )
        Task {
            await manager.track(event)
        }
    }

    /// Convenience for screen-view events. Automatically maps to the
    /// `.navigation` category and logs `"screen_viewed"`.
    ///
    /// - Parameters:
    ///   - screenName: Human-readable name (e.g. `"HomeScreen"`).
    ///   - screenClass: Optional Swift type name (e.g. `"HomeView"`).
    public static func logScreenView(_ screenName: String, screenClass: String? = nil) {
        var params: [String: Any] = ["screen": screenName]
        if let cls = screenClass { params["screen_class"] = cls }
        logEvent("screen_viewed", parameters: params)
    }

    // MARK: - Advanced Access (for custom integrations)

    /// The shared SwiftData `ModelContainer`. Access from the `@MainActor` only.
    /// Identical to `AIAnalyticsContainer.modelContainer`.
    @MainActor
    public static var modelContainer: ModelContainer {
        AIAnalyticsContainer.modelContainer
    }

    /// Creates a fully-wired `HomeViewModel`. Access from the `@MainActor` only.
    /// Use this if you need to inject the ViewModel manually instead of via
    /// the `.aiAnalytics()` scene modifier.
    @MainActor
    public static func makeHomeViewModel() -> HomeViewModel {
        AIAnalyticsContainer.makeHomeViewModel()
    }

    // MARK: - Category Inference

    /// Infers an `EventCategory` from the event name so callers never need
    /// to specify the enum. Heuristics:
    ///   - `"screen_*"` or `"*_viewed"` → `.navigation`
    ///   - contains `"error"` or `"crash"`   → `.error`
    ///   - contains `"analys"`, `"report"`, `"insight"` → `.analysis`
    ///   - everything else                  → `.interaction`
    static func inferCategory(from name: String) -> AnalyticsEvent.EventCategory {
        let lower = name.lowercased()
        if lower.hasPrefix("screen_") || lower.hasSuffix("_viewed") {
            return .navigation
        }
        if lower.contains("error") || lower.contains("crash") {
            return .error
        }
        if lower.contains("analys") || lower.contains("report") || lower.contains("insight") {
            return .analysis
        }
        return .interaction
    }
}
