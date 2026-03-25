import FoundationModels
import OSLog

// MARK: - LogIntelligenceService
//
// Architecture overview
// ─────────────────────
//   ┌──────────────┐   fast path   ┌─────────────────────────────┐
//   │  Log Batch   │──────────────▶│  contentTagging session      │
//   │  (raw text)  │               │  (built-in, always ready)    │
//   └──────────────┘               └─────────────────────────────┘
//          │
//          │  slow / enriched path (adapter loaded + compiled)
//          ▼
//   ┌─────────────────────────────────────────────────────────────┐
//   │  UserFrictionAdapter session                                │
//   │  (custom .fmadapter, downloaded via Background Assets)      │
//   └─────────────────────────────────────────────────────────────┘
//
// Session pooling strategy
// ────────────────────────
// Each SystemLanguageModel.Adapter occupies ~160 MB of GPU-addressable memory.
// Keeping more than one adapter session resident simultaneously risks jetsam.
// The pool uses a single slot protected by an actor; callers that arrive while
// the slot is occupied await their turn rather than spawning a second session.

public actor LogIntelligenceService {

    // MARK: - Types

    public enum AnalysisPath {
        /// Built-in content-tagging model; no download required.
        case builtIn
        /// Domain-specific adapter for friction / UX-failure signals.
        case frictionAdapter
    }

    private enum AdapterState {
        case notLoaded
        case compiling
        case ready(SystemLanguageModel.Adapter)
        case failed(Error)
    }

    // MARK: - Private State

    private let logger = Logger(subsystem: "com.app.FoundationInsights",
                                category: "LogIntelligenceService")

    /// Built-in model — always available, zero cold-start.
    private let builtInModel = SystemLanguageModel(useCase: .contentTagging)

    /// Custom adapter state machine; transitions driven by prepare() and
    /// the Background Assets completion callback.
    private var adapterState: AdapterState = .notLoaded

    /// The one-slot session pool.  Nil when no session is currently active.
    /// Actor isolation guarantees exclusive access without a mutex.
    private var liveAdapterSession: LanguageModelSession?

    // MARK: - Init

    public init() {}

    // MARK: - Public API

    /// Call once — ideally at the end of the first user session — to compile
    /// the adapter weights for the current device's Neural Engine topology.
    /// compile() is idempotent; calling it multiple times is safe.
    public func prepare(adapterURL: URL) async {
        guard case .notLoaded = adapterState else { return }
        adapterState = .compiling

        do {
            let adapter = try SystemLanguageModel.Adapter(fileURL: adapterURL)
            // compile() converts the portable .fmadapter weights into a
            // device-specific Metal Performance Shaders graph cached on disk.
            // Subsequent process launches skip compilation entirely.
            logger.info("Compiling UserFrictionAdapter — this runs once per OS/device pair.")
            try await adapter.compile()
            adapterState = .ready(adapter)
            logger.info("UserFrictionAdapter compilation complete.")
        } catch {
            adapterState = .failed(error)
            logger.error("Adapter compilation failed: \(error)")
        }
    }

    /// Primary entry point.  Chooses the analysis path automatically:
    ///   • If the friction adapter is compiled → uses it (richer output).
    ///   • Otherwise → falls back to the built-in content-tagging model.
    public func analyze(logBatch: String) async throws -> LogSummary {
        if case .ready(let adapter) = adapterState {
            return try await analyzeWithAdapter(logBatch: logBatch, adapter: adapter)
        } else {
            return try await analyzeWithBuiltIn(logBatch: logBatch)
        }
    }

    // MARK: - Built-In Path

    private func analyzeWithBuiltIn(logBatch: String) async throws -> LogSummary {
        let session = LanguageModelSession(model: builtInModel)
        let prompt = Prompt(logBatch, role: .user)
        return try await session.respond(
            to: prompt,
            generating: LogSummary.self
        )
    }

    // MARK: - Adapter Path (one-slot pool)
    //
    // The pool prevents two adapter sessions from being resident at once.
    // Because this method is on an actor, `await` naturally serialises callers:
    //
    //   Caller A                 Caller B
    //   ────────                 ────────
    //   enters analyzeWithAdapter
    //   liveAdapterSession = session
    //                            awaits entry (actor is busy)
    //   respond() completes
    //   liveAdapterSession = nil  ← releases GPU memory
    //                            now enters; creates new session
    //
    // If you need concurrent throughput, replace this with a bounded async
    // channel / semaphore of size N (where N is the device memory budget ÷ 160 MB).

    private func analyzeWithAdapter(
        logBatch: String,
        adapter: SystemLanguageModel.Adapter
    ) async throws -> LogSummary {
        // Reuse an existing session or create a fresh one.
        let session: LanguageModelSession
        if let existing = liveAdapterSession {
            session = existing
        } else {
            session = LanguageModelSession(adapter: adapter)
            liveAdapterSession = session
        }

        defer {
            // Drop the session reference so the runtime can evict adapter
            // weights under memory pressure (the OS will re-page them on demand).
            liveAdapterSession = nil
        }

        let prompt = Prompt(logBatch, role: .user)
        return try await session.respond(
            to: prompt,
            generating: LogSummary.self
        )
    }

    // MARK: - Explicit Eviction

    /// Call when the app moves to background to proactively free ~160 MB.
    /// The next call to analyze() will re-create the session transparently.
    public func evictAdapterSession() {
        liveAdapterSession = nil
        logger.debug("Adapter session evicted — GPU memory reclaimed.")
    }
}
