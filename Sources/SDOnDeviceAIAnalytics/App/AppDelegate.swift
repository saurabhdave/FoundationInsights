import UIKit
import BackgroundAssets

// MARK: - AppDelegate
//
// Integration helper showing how to wire together AdapterAssetDownloader and
// LogIntelligenceService at the two critical lifecycle moments:
//   1. didFinishLaunching  → register BA delegate, kick off any pending download
//   2. applicationDidEnterBackground → evict the adapter session to reclaim GPU RAM
//
// Usage: assign an instance as your app's delegate, or copy this wiring into
// your own UIApplicationDelegate subclass.
//
// Note: @main must live in the consuming app target, not in this library.

public final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Shared service instance — actor isolation makes it safe to store here.
    public let intelligenceService = LogIntelligenceService()

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        BADownloadManager.shared.delegate = AdapterAssetDownloader.shared
        AdapterAssetDownloader.shared.scheduleDownloadIfNeeded()

        // If the adapter is already on disk (e.g. after an app update), compile
        // it now so it is ready before the user's first meaningful interaction.
        if let url = AdapterAssetDownloader.shared.localAdapterURL,
           AdapterAssetDownloader.shared.isAdapterCompatible(at: url) {
            Task {
                await intelligenceService.prepare(adapterURL: url)
            }
        }

        return true
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        Task {
            // Proactively free ~160 MB of GPU-addressable memory before
            // the Jetsam threshold is breached in the background.
            await intelligenceService.evictAdapterSession()
        }
    }
}
