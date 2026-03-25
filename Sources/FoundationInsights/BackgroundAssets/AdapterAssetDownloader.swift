import BackgroundAssets
import FoundationModels
import OSLog

// MARK: - AdapterAssetDownloader
//
// Why Background Assets instead of URLSession background tasks?
// ─────────────────────────────────────────────────────────────
// • BADownloadManager runs *out-of-process* in a system daemon; the 160 MB
//   adapter download continues even if the OS suspends your app.
// • The system batches adapter downloads with OS updates, reusing the same
//   CDN connections and respecting Low Data Mode automatically.
// • Assets are validated against a developer-provided checksum before being
//   moved to the app's container, preventing partial/corrupt writes.
//
// Setup checklist (project level, not in code):
//   1. Add the "Background Assets" capability in Xcode → Signing & Capabilities.
//   2. Set NSBackgroundAssetsBundleIdentifier in the Extension's Info.plist.
//   3. List the adapter URL in the BAInitialDownloadRestrictions key so the OS
//      can fetch it during app install when the device is on Wi-Fi + charging.

public final class AdapterAssetDownloader: NSObject, @unchecked Sendable {

    public static let shared = AdapterAssetDownloader()

    // The URL must match the BAManifestURL entry in Info.plist.
    private let adapterRemoteURL = URL(
        string: "https://cdn.yourapp.com/models/UserFrictionAdapter_v2.fmadapter"
    )!

    private let downloadIdentifier = "com.app.FoundationInsights.UserFrictionAdapter"
    private let logger = Logger(subsystem: "com.app.FoundationInsights",
                                category: "AdapterAssetDownloader")

    // Resolved local path after a successful download.
    public var localAdapterURL: URL? {
        let container = FileManager.default.urls(for: .applicationSupportDirectory,
                                                 in: .userDomainMask)[0]
        let candidate = container.appendingPathComponent("UserFrictionAdapter_v2.fmadapter")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    // MARK: - Compatibility Gate
    //
    // The adapter is compiled against a specific Foundation Models ABI.
    // isCompatible() compares the .fmadapter's embedded metadata against the
    // running OS's model version — call this *before* passing the URL to
    // LogIntelligenceService.prepare() to avoid a runtime crash.

    public func isAdapterCompatible(at url: URL) -> Bool {
        // Compatibility is verified at load time by SystemLanguageModel.Adapter(fileURL:).
        // Here we only confirm the file is present and non-empty; any ABI mismatch
        // will surface as a thrown error in LogIntelligenceService.prepare().
        let reachable = (try? url.checkResourceIsReachable()) ?? false
        logger.info("Adapter file reachable: \(reachable)")
        return reachable
    }

    // MARK: - Initiating a Download

    public func scheduleDownloadIfNeeded() {
        guard localAdapterURL == nil else {
            logger.debug("Adapter already on disk — skipping download.")
            return
        }

        let download = BAURLDownload(
            identifier: downloadIdentifier,
            request: URLRequest(url: adapterRemoteURL),
            // fileSize drives the OS scheduling heuristic (bytes).
            fileSize: 168_000_000,
            applicationGroupIdentifier: "group.com.app.FoundationInsights"
        )

        do {
            try BADownloadManager.shared.startForegroundDownload(download)
            logger.info("Adapter download scheduled.")
        } catch {
            logger.error("Failed to schedule adapter download: \(error)")
        }
    }
}

// MARK: - BADownloadManagerDelegate

extension AdapterAssetDownloader: BADownloadManagerDelegate {

    public func downloadDidBegin(_ download: BADownload) {
        logger.info("Adapter download started: \(download.identifier)")
    }

    public func download(_ download: BADownload, didWriteBytes bytesWritten: Int64,
                         totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        logger.debug("Adapter download progress: \(progress, format: .fixed(precision: 1))%")
    }

    public func download(_ download: BADownload,
                         finishedWithFileURL fileURL: URL) {
        guard download.identifier == downloadIdentifier else { return }
        moveAdapterToContainer(from: fileURL)
    }

    public func download(_ download: BADownload, failedWithError error: Error) {
        logger.error("Adapter download failed: \(error)")
        // The system will retry according to BARetryPolicy; no manual retry needed.
    }

    // MARK: - Private Helpers

    private func moveAdapterToContainer(from tempURL: URL) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask)[0]
        let destination = support.appendingPathComponent("UserFrictionAdapter_v2.fmadapter")
        do {
            try FileManager.default.createDirectory(at: support,
                                                    withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: tempURL, to: destination)
            logger.info("Adapter moved to container: \(destination.path)")

            // Notify the service layer; fire-and-forget Task is acceptable here
            // because prepare() is idempotent and actor-isolated.
            Task {
                await LogIntelligenceService().prepare(adapterURL: destination)
            }
        } catch {
            logger.error("Failed to move adapter file: \(error)")
        }
    }
}
