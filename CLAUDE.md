# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build all targets
swift build

# Build release
swift build -c release

# Run tests (none defined yet — add test targets to Package.swift as needed)
swift test

# Build the sample app (requires Xcode + iOS 26 Simulator)
xcodebuild -project Examples/FoundationInsightsDemo/FoundationInsightsDemo.xcodeproj \
  -scheme FoundationInsightsDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

## Architecture

**FoundationInsights** is an on-device log intelligence library using Apple's Foundation Models framework (iOS 26+, arm64). It analyzes log batches entirely on-device via the Neural Engine — no network calls, no data egress.

### Two Targets

- **FoundationInsights** (library) — the main product consumed by apps
- **AdapterDownloadExtension** (executable) — a Background Assets App Extension that downloads the custom adapter out-of-process

### Dual-Path Analysis

`LogIntelligenceService` (actor) operates in two modes:

1. **Fast path** — uses `SystemLanguageModel` with `.contentTagging` (always available, zero cold-start)
2. **Enriched path** — uses a custom `UserFrictionAdapter` (~160 MB) downloaded via Background Assets and compiled once per device/OS pair, then cached to disk

The service automatically upgrades to the enriched path once `prepare(adapterURL:)` is called and compilation completes.

### Key Patterns

**Actor isolation** (`LogIntelligenceService` is a Swift `actor`): concurrent `analyze()` calls serialize automatically; Swift 6 strict concurrency is enforced across both targets.

**Single-slot session pool**: The adapter session (~160 MB of GPU memory) is created lazily, used, then evicted via `defer { liveAdapterSession = nil }` after each call to prevent jetsam pressure.

**Adapter state machine**: `AdapterState` enum transitions `notLoaded → compiling → ready(adapter)` (or `failed`). `prepare()` is idempotent.

**Constrained generation**: `LogSummary` uses `@Generable` + `@Guide` annotations so the model is constrained at the logit level — worst-case ~50 output tokens → <200ms on A17 Pro.

**Coordinator pattern**: `LogAnalyticsCoordinator` sits between the view layer and `LogIntelligenceService`, routing high-urgency summaries to crash reporters and posting `NotificationCenter` events.

### Swift Version & Platform

- Swift 6.0 (strict concurrency, `.swiftLanguageMode(.v6)`)
- iOS 26.0 minimum, arm64 only
- No external dependencies — only Apple frameworks: `FoundationModels`, `BackgroundAssets`, `UIKit`, `OSLog`

### Sample App

`Examples/FoundationInsightsDemo/` is a standalone Xcode project that imports FoundationInsights as a local SPM dependency (`relativePath = "../.."`). Open `FoundationInsightsDemo.xcodeproj` directly — no workspace needed.

- **Fast path** works in the simulator (built-in `.contentTagging` model)
- **Enriched path** requires a physical device with a Neural Engine and the downloaded adapter
- Pre-canned log batches (High / Medium / Low urgency) are in `SampleLogBatches.swift`

### Background Assets Setup

The `AdapterDownloadExtension` executable requires an App Group (`group.com.app.FoundationInsights`) shared between the main app and the extension. The adapter remote URL and download identifier are configured in `AdapterAssetDownloader.swift`.
