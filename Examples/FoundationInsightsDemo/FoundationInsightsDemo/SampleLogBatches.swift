import Foundation

enum SampleLogBatches {

    enum Sample: String, CaseIterable, Identifiable {
        case highUrgency   = "High Urgency"
        case mediumUrgency = "Medium Urgency"
        case lowUrgency    = "Low Urgency"

        var id: String { rawValue }

        var logText: String {
            switch self {
            case .highUrgency:   return SampleLogBatches.highUrgency
            case .mediumUrgency: return SampleLogBatches.mediumUrgency
            case .lowUrgency:    return SampleLogBatches.lowUrgency
            }
        }
    }

    // MARK: - High Urgency
    // Crash loop: EXC_BAD_ACCESS, nil unwrap, repeated -1001 timeouts,
    // 401 auth failure, Core Data merge conflict, app termination.
    static let highUrgency = """
        2026-03-25 08:01:02.101 MyApp[1234:5678] [ERROR] \
        Uncaught exception: EXC_BAD_ACCESS (SIGSEGV) — code=1 addr=0x0
        2026-03-25 08:01:02.205 MyApp[1234:5678] [FAULT] \
        Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
        2026-03-25 08:01:05.310 MyApp[1234:5679] [ERROR] \
        URLSession task failed: NSURLErrorDomain error=-1001 (request timed out)
        2026-03-25 08:01:05.412 MyApp[1234:5679] [ERROR] \
        URLSession task failed: NSURLErrorDomain error=-1001 (request timed out)
        2026-03-25 08:01:06.000 MyApp[1234:5680] [ERROR] \
        Auth token refresh failed: HTTP 401 Unauthorized — user will be signed out
        2026-03-25 08:01:06.100 MyApp[1234:5681] [FAULT] \
        Core Data save failed: NSCocoaErrorDomain error=133021 (merge conflict)
        2026-03-25 08:01:06.200 MyApp[1234:5681] [ERROR] \
        Core Data save failed: NSCocoaErrorDomain error=133021 (merge conflict)
        2026-03-25 08:01:07.000 MyApp[1234:5682] [FAULT] \
        App will terminate — repeated unhandled exceptions in session
        """

    // MARK: - Medium Urgency
    // Degraded but operational: slow API responses, memory pressure,
    // non-fatal JSON decode errors, disk I/O stall.
    static let mediumUrgency = """
        2026-03-25 10:15:00.000 MyApp[2001:6001] [WARNING] \
        API response latency exceeded threshold: 3.2s (threshold: 1.0s) — endpoint: /feed
        2026-03-25 10:15:01.500 MyApp[2001:6001] [WARNING] \
        API response latency exceeded threshold: 2.8s — endpoint: /notifications
        2026-03-25 10:15:03.000 MyApp[2001:6002] [WARNING] \
        Memory warning received (level=2) — flushing image cache (512 MB freed)
        2026-03-25 10:15:04.100 MyApp[2001:6003] [ERROR] \
        JSON decode error: keyNotFound("user_avatar_url") in FeedItem — using fallback
        2026-03-25 10:15:04.200 MyApp[2001:6003] [ERROR] \
        JSON decode error: keyNotFound("user_avatar_url") in FeedItem — using fallback
        2026-03-25 10:15:05.000 MyApp[2001:6004] [WARNING] \
        Disk I/O stall detected: 1.4s write latency on Documents directory
        2026-03-25 10:15:06.000 MyApp[2001:6004] [INFO] \
        Retry #1 of /feed request succeeded after 1.1s
        """

    // MARK: - Low Urgency
    // Routine operational logs with minor informational notices.
    static let lowUrgency = """
        2026-03-25 14:30:00.000 MyApp[3001:7001] [INFO] \
        App did become active — restoring UI state
        2026-03-25 14:30:00.200 MyApp[3001:7001] [DEBUG] \
        Loaded 48 cached feed items from disk
        2026-03-25 14:30:00.350 MyApp[3001:7002] [INFO] \
        Background refresh completed: 3 new items fetched
        2026-03-25 14:30:01.000 MyApp[3001:7003] [DEBUG] \
        Image prefetch queue drained (12 items, 0 failures)
        2026-03-25 14:30:02.000 MyApp[3001:7003] [NOTICE] \
        Analytics batch upload succeeded: 200 events flushed
        2026-03-25 14:30:03.000 MyApp[3001:7004] [INFO] \
        Push notification token refreshed successfully
        2026-03-25 14:30:04.000 MyApp[3001:7004] [DEBUG] \
        Session heartbeat sent — server acknowledged
        """
}
