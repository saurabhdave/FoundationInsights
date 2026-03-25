<div align="center">

# 🧠 FoundationInsights

**On-device log intelligence powered by Apple's Foundation Models framework.**

Analyze local app logs for urgency, friction signals, and domain insights —
entirely on-device, zero network latency, zero data egress.

<br/>

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-34C759?style=flat-square)](https://swift.org/package-manager/)
[![Foundation Models](https://img.shields.io/badge/Foundation%20Models-✦-6E40C9?style=flat-square)](https://developer.apple.com/documentation/foundationmodels)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

</div>

---

## ✦ Why FoundationInsights?

Most log analytics pipelines ship raw logs to a remote server for processing — introducing latency, privacy risk, and an internet dependency. This library runs the entire intelligence pipeline on the device's Neural Engine:

| | Traditional Pipeline | FoundationInsights |
|---|:---:|:---:|
| Network required | ✅ | ❌ |
| User data leaves device | ✅ | ❌ |
| Inference latency | 500 ms – 2 s | **< 200 ms** |
| Works offline | ❌ | ✅ |
| Custom domain model | ❌ | ✅ |

---

## ✦ Features

<table>
<tr>
<td width="50%">

**⚡ Dual-Path Analysis**
Built-in `.contentTagging` for instant zero-cold-start baseline. Automatically upgrades to the custom `UserFrictionAdapter` once compiled.

</td>
<td width="50%">

**🎯 Constrained Generation**
`@Generable` + `@Guide` annotations lock output at the logit level. Worst-case: 50 tokens. Target latency: < 200 ms on A17 Pro.

</td>
</tr>
<tr>
<td>

**🛡️ Memory-Safe Session Pool**
Actor-isolated single-slot pool. Only one 160 MB adapter session resident at a time — jetsam never triggered.

</td>
<td>

**📦 Background Asset Download**
160 MB+ adapter files fetched out-of-process via Background Assets. Never bundled in your `.ipa`.

</td>
</tr>
</table>

---

## ✦ Architecture

```
                         ┌─────────────────────────────────────────┐
                         │            LogIntelligenceService        │
                         │               (Swift actor)              │
                         └───────────────────┬─────────────────────┘
                                             │
               ┌─────────────────────────────┴──────────────────────────┐
               │                                                         │
               ▼  FAST PATH  (always available)                          ▼  ENRICHED PATH  (after compile)
  ┌────────────────────────────┐                          ┌──────────────────────────────────┐
  │   SystemLanguageModel      │                          │   SystemLanguageModel.Adapter    │
  │   useCase: .contentTagging │                          │   "UserFrictionAdapter.fmadapter"│
  │   (built-in, 0 ms startup) │                          │   (~160 MB, Neural Engine MPS)   │
  └────────────────────────────┘                          └──────────────────────────────────┘
               │                                                         │
               └─────────────────────────────┬──────────────────────────┘
                                             │
                                             ▼
                              ┌──────────────────────────┐
                              │        LogSummary         │
                              │  urgency  · summary       │
                              │  tags     · errorCode     │
                              └──────────────────────────┘
```

### SPM Targets

```
FoundationInsights/
├── Sources/
│   ├── FoundationInsights/          ← 📦 Library  (import this in your app)
│   │   ├── Models/LogSummary.swift
│   │   ├── Services/LogIntelligenceService.swift
│   │   ├── BackgroundAssets/AdapterAssetDownloader.swift
│   │   └── App/AppDelegate.swift · LogAnalyticsCoordinator.swift
│   └── AdapterDownloadExtension/       ← ⚙️ Executable  (embed as BA extension)
│       └── AdapterDownloadExtension.swift
├── Package.swift
└── .swift-version
```

---

## ✦ Requirements

| | Minimum |
|---|---|
| 📱 iOS | **26.0** |
| 🔨 Xcode | **26.0** |
| 🐦 Swift | **6.0** |
| 🖥️ Architecture | arm64 (Neural Engine required) |

---

## ✦ Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/FoundationInsights", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["FoundationInsights"]
    )
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the repo URL.

---

## ✦ Quick Start

### Step 1 — Wire up the app delegate

The included `AppDelegate` handles Background Assets delegate registration, download scheduling, and background session eviction automatically:

```swift
import UIKit
import FoundationInsights

@main
final class MyAppDelegate: AppDelegate {
    // Done. Adapter download + lifecycle wiring handled for you.
}
```

<details>
<summary>Manual wiring for existing delegates</summary>

```swift
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    BADownloadManager.shared.delegate = AdapterAssetDownloader.shared
    AdapterAssetDownloader.shared.scheduleDownloadIfNeeded()

    if let url = AdapterAssetDownloader.shared.localAdapterURL,
       AdapterAssetDownloader.shared.isAdapterCompatible(at: url) {
        Task { await intelligenceService.prepare(adapterURL: url) }
    }
    return true
}

func applicationDidEnterBackground(_ application: UIApplication) {
    Task { await intelligenceService.evictAdapterSession() }
}
```

</details>

---

### Step 2 — Analyze a log batch

```swift
let service = LogIntelligenceService()

let summary = try await service.analyze(logBatch: recentLogs)

print(summary.urgency)            // "High" | "Medium" | "Low"
print(summary.summary)            // "Repeated auth failures preceded crash"
print(summary.tags)               // ["auth", "crash", "onboarding"]
print(summary.dominantErrorCode)  // Optional("ERR_TOKEN_EXPIRED")
```

---

### Step 3 — React to high-urgency events

```swift
NotificationCenter.default.addObserver(
    forName: .highUrgencyLogsDetected,
    object: nil,
    queue: .main
) { notification in
    guard let summary = notification.object as? LogSummary else { return }
    MyCrashReporter.flag(summary.dominantErrorCode, tags: summary.tags)
}
```

---

## ✦ Output Model

`LogSummary` uses `@Guide` constraints that operate **at the logit level** — the model is physically incapable of producing tokens outside the allowed set:

```swift
@Generable
public struct LogSummary {

    @Guide(description: "Triage urgency", .anyOf(["High", "Medium", "Low"]))
    var urgency: String            // → always 1 token

    @Guide(description: "Plain-language summary", .maximumCount(40))
    var summary: String            // → ≤ 40 words

    @Guide(description: "Up to 3 domain tags", .maximumCount(3))
    var tags: [String]             // → ≤ 3 × ~2 tokens

    var dominantErrorCode: String? // → 0–1 token
}
//                                    ──────────────
//                                    Worst case: ~50 tokens total
```

---

## ✦ Adapter Compilation Lifecycle

`adapter.compile()` translates portable `.fmadapter` weights into a device-specific Metal Performance Shaders graph. It runs **once**, then the result is cached on disk keyed to `(device model × OS build × adapter checksum)`.

```
  First launch                        All subsequent launches
  ────────────                        ──────────────────────

  prepare(adapterURL:)                prepare(adapterURL:)
       │                                   │
       ▼                                   ▼
  AdapterState → .compiling          AdapterState already .ready
       │                                   │
       ▼                                   ▼
  adapter.compile()                  return immediately (no-op)
  ⏱ ~2–5 s on ANE
       │
       ▼
  MPS graph written to disk
  (persists across app restarts)
       │
       ▼
  AdapterState → .ready
```

> [!IMPORTANT]
> Call `prepare(adapterURL:)` at the **end of the first user session** — not at launch. The 2–5 s ANE compilation should not compete with your first-render pass.

---

## ✦ Background Assets Setup

The adapter (~160 MB) is downloaded out-of-process by the system daemon — no `URLSession`, no manual retry logic, and Low Data Mode is respected automatically.

**Xcode setup checklist:**

- [ ] **File → New → Target → Background Download Extension** — point it at `Sources/AdapterDownloadExtension/`
- [ ] Add the **Background Assets** capability to both the app and extension targets
- [ ] Add an **App Group** (`group.com.app.FoundationInsights`) to both targets
- [ ] Set these keys in the **extension's** `Info.plist`:

| Key | Value |
|---|---|
| `BAManifestURL` | `https://cdn.yourapp.com/models/manifest.json` |
| `BAMaxInstallSize` | `168000000` |
| `NSBackgroundAssetsBundleIdentifier` | `com.app.FoundationInsights` |

> [!NOTE]
> Always call `AdapterAssetDownloader.isAdapterCompatible(at:)` before `prepare()`. This checks the adapter's embedded ABI manifest against the running OS version without loading the 160 MB weights.

---

## ✦ Memory Management

Each adapter session occupies ~160 MB of GPU-addressable memory. The service manages this through an actor-isolated single-slot pool:

```
  analyze() called
       │
       ├── liveAdapterSession == nil?
       │       └── YES → create new session  (+160 MB GPU)
       │
       ├── respond() executes
       │
       └── defer { liveAdapterSession = nil }  (–160 MB GPU)
```

| Trigger | Action | Memory |
|---|---|---|
| `analyze()` call | Session created (or reused) | +160 MB |
| `analyze()` returns / throws | `defer` drops the session | −160 MB |
| `applicationDidEnterBackground` | `evictAdapterSession()` | −160 MB |
| Built-in `.contentTagging` path | Managed by system `aned` daemon | **0 MB against your app** |

---

## ✦ License

MIT © 2025
