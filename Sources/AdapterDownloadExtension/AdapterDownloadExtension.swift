#if os(iOS)
import BackgroundAssets

// MARK: - Background Assets App Extension
//
// This target must be a separate "Background Assets Extension" target in Xcode
// (File → New → Target → Background Download Extension).
//
// The extension runs in a *separate process* so the system can call
// applicationDidFinishLaunching(_:) during install/update even when the
// host app has never been launched.  This is the only place where
// BADownloaderExtension protocol conformance should live.
//
// Info.plist keys required in the *extension* target:
//   BAManifestURL            → https://cdn.yourapp.com/models/manifest.json
//   BAMaxInstallSize         → 168000000   (bytes, shown in App Store listing)
//   NSBackgroundAssetsBundleIdentifier → com.app.FoundationInsights

@main
struct AdapterDownloadExtension: BADownloaderExtension {

    /// Called by the system when the app is installed or updated.
    /// Return the set of assets the OS should fetch before the app first launches.
    func applicationDidFinishLaunching(_ application: BAApplicationExtension) {
        // Nothing to enqueue here — we rely on BAInitialDownloadRestrictions
        // in Info.plist to declare the initial asset set declaratively.
        // For *conditional* downloads (e.g. only on Wi-Fi), enqueue them here.
    }

    /// Called when a download the extension previously initiated finishes.
    func download(
        _ download: BADownload,
        finishedWithFileURL fileURL: URL
    ) {
        // The extension process is distinct from the app process.
        // Use an App Group shared container to hand the file to the app.
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier:
                "group.com.app.FoundationInsights")!
            .appendingPathComponent("UserFrictionAdapter_v2.fmadapter")

        try? FileManager.default.moveItem(at: fileURL, to: groupURL)
    }

    func download(_ download: BADownload, failedWithError error: Error) {
        // System will retry per BARetryPolicy.  Log for diagnostics only.
    }
}

#else

// macOS stub — Background Assets App Extensions are iOS-only.
// This target is only ever built and embedded in an iOS app extension bundle;
// the stub exists solely so `swift build` on a macOS host compiles cleanly.
@main
struct AdapterDownloadExtension {
    static func main() {}
}

#endif // os(iOS)
