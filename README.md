<div align="center">

# AIAnalyticsKit

<br/>

[![CI](https://github.com/saurabhdave/AIAnalyticsKit/actions/workflows/ci.yml/badge.svg)](https://github.com/saurabhdave/AIAnalyticsKit/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-26.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SPM-compatible-34C759?style=flat-square)](https://swift.org/package-manager/)
[![Foundation Models](https://img.shields.io/badge/Foundation%20Models-✦-6E40C9?style=flat-square)](https://developer.apple.com/documentation/foundationmodels)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

**On-device user behavior analytics and AI personalization — powered by Apple's Foundation Models**

*Classify users · Gate features · Run A/B tests · Adapt UI in real time — entirely on the Neural Engine. No server. No data egress.*

</div>

---

## Table of Contents

- [Overview](#overview)
- [Why AIAnalyticsKit?](#why-aianalyticskit)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Feature Flags](#feature-flags)
- [A/B Testing](#ab-testing)
- [Real-Time UI Adaptation](#real-time-ui-adaptation)
- [Use Cases & Scenarios](#use-cases--scenarios)
- [Advanced Integration](#advanced-integration)
- [Public API Reference](#public-api-reference)
- [User Classification](#user-classification)
- [Architecture](#architecture)
- [Key Design Patterns](#key-design-patterns)
- [Demo App](#demo-app)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

AIAnalyticsKit is a Swift 6 library that brings AI-powered user segmentation, adaptive UI personalization, feature flags, and A/B testing to iOS and macOS — with zero network calls. It tracks user behavior, extracts a 6-dimension feature vector, runs inference via Apple's Foundation Models framework, and delivers a tailored `UIConfiguration` — all on the Neural Engine in under 200 ms.

```
Track events  ──►  Build features  ──►  Predict segment  ──►  Adapt your UI
     │                   │                     │                     │
SwiftData           6-dimension            Foundation            Feature flags ·
persistence         feature vector         Models on             A/B variants ·
                                           Neural Engine         Personalized UI
```

---

## Why AIAnalyticsKit?

Traditional personalization pipelines ship behavioral data to a remote server for analysis. AIAnalyticsKit keeps the entire pipeline on-device:

|                          | Traditional Pipeline  | AIAnalyticsKit       |
|--------------------------|:---------------------:|:--------------------:|
| Requires network         | ✅                    | ❌                   |
| User data leaves device  | ✅                    | ❌                   |
| Inference latency        | 500 ms – 2 s          | **< 200 ms**         |
| Works offline            | ❌                    | ✅                   |
| Privacy compliant        | Conditional           | ✅ By design         |
| Adaptive UI              | ❌                    | ✅                   |
| AI-driven feature flags  | ❌                    | ✅                   |
| AI-driven A/B testing    | ❌                    | ✅                   |

---

## Requirements

| Requirement | Minimum  |
|-------------|----------|
| iOS         | **26.0** |
| macOS       | **26.0** |
| Xcode       | **26.0** |
| Swift       | **6.0**  |

No external dependencies — only Apple frameworks: `FoundationModels`, `SwiftData`, `SwiftUI`, `OSLog`.

---

![IMG_7933](https://github.com/user-attachments/assets/c7923a87-0f26-45a6-bea8-eeb4d4c6f3e4)
![IMG_7934](https://github.com/user-attachments/assets/6fe7e00c-dc69-4421-ae2a-cd8df780d4eb)
![IMG_7935](https://github.com/user-attachments/assets/7034bebb-a258-470a-8299-f37a0701e96d)
![IMG_7936](https://github.com/user-attachments/assets/84bd1c6b-4679-434e-bf85-df77c44e43c1)
![IMG_7937](https://github.com/user-attachments/assets/021a57d2-0a37-4dff-8088-cfd8a1814155)



---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/saurabhdave/AIAnalyticsKit", from: "1.0.0")
],
targets: [
    .target(name: "YourApp", dependencies: ["AIAnalyticsKit"])
]
```

### Xcode

**File → Add Package Dependencies…** and paste the repository URL.

---

## Quick Start

### 1. Set up in `App.swift` — one line

```swift
import SwiftUI
import AIAnalyticsKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .aiAnalytics()  // wires persistence, AI engine, and ViewModel
        }
    }
}
```

`.aiAnalytics()` bootstraps the full object graph — SwiftData store, `AnalyticsManager`, Foundation Models engine, and `HomeViewModel` — and injects them into the SwiftUI environment.

### 2. Log events from anywhere

```swift
// Fire-and-forget — no await, no ViewModel, no Task wrapper needed
AIAnalytics.logEvent("button_tapped", parameters: ["id": "subscribe_cta"])
AIAnalytics.logEvent("purchase_completed", parameters: ["product": "premium"])

// Convenience shorthand for screen views
AIAnalytics.logScreenView("DashboardScreen")
AIAnalytics.logScreenView("SettingsScreen", screenClass: "SettingsView")
```

Event categories are inferred automatically from the event name — no enum required:

| Event name pattern                              | Inferred category |
|-------------------------------------------------|-------------------|
| Starts with `screen_` or ends with `_viewed`    | `.navigation`     |
| Contains `error` or `crash`                     | `.error`          |
| Contains `analys`, `report`, or `insight`       | `.analysis`       |
| Everything else                                 | `.interaction`    |

### 3. Read AI-powered insights

```swift
@Environment(HomeViewModel.self) private var viewModel

// Run the full prediction pipeline
await viewModel.loadInsights()

// Consume the result
if case .ready(let config, let prediction) = viewModel.viewState {
    print(prediction.userType.rawValue)  // "Power User"
    print(config.greeting)               // "Welcome back, power user"
    print(config.showAdvancedFeatures)   // true
}
```

Or drop in the ready-made `HomeView` — it handles state, personalization rendering, and the privacy badge automatically.

---

## Feature Flags

AI-driven feature flags gate functionality based on the current on-device user classification. No remote config server — flags evaluate entirely against the local `UserPrediction`.

### Setup

```swift
@main
struct MyApp: App {
    private let flags = AIAnalyticsContainer.makeFeatureFlagRegistry()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .aiAnalytics(flagRegistry: flags)
                .task { await registerFlags() }
        }
    }

    private func registerFlags() async {
        await flags.register([
            // Only Power Users with ≥ 70% confidence unlock batch processing
            FeatureFlag(
                key: "batchProcessing",
                enabledForUserTypes: [.power],
                minimumConfidence: 0.7
            ),
            // Both Power and Explorer users can export reports
            FeatureFlag(
                key: "exportReport",
                enabledForUserTypes: [.power, .explorer],
                minimumConfidence: 0.5
            ),
            // Re-engagement banner shown only to At-Risk users
            FeatureFlag(
                key: "reEngagement",
                enabledForUserTypes: [.atRisk],
                minimumConfidence: 0.4
            ),
        ])
    }
}
```

Use `FeatureFlagKey` for the built-in key constants, or any `String` for custom keys.

### Querying flags in views

```swift
struct BatchButton: View {
    @Environment(HomeViewModel.self) private var viewModel
    let flags: FeatureFlagRegistry
    @State private var isEnabled = false

    var body: some View {
        Group {
            if isEnabled {
                Button("Batch Process") { /* … */ }
            }
        }
        // Re-evaluates automatically whenever the user type changes
        .task(id: viewModel.viewState.prediction?.userType) {
            isEnabled = await flags.isEnabled("batchProcessing")
        }
    }
}
```

### Usage scenarios

| Flag | Eligible types | Scenario |
|---|---|---|
| `batchProcessing` | Power | Unlock batch export only for heavy users |
| `exportReport` | Power, Explorer | Surface advanced tooling for engaged users |
| `advancedFilters` | Power, Explorer | Progressive disclosure of complex UI |
| `reEngagement` | At-Risk | Show win-back banner to users drifting away |

---

## A/B Testing

AI-driven A/B tests assign users to experiment variants based on their on-device classification. Assignments are **stable** across launches (backed by a write-once cohort ID in `UserDefaults`) and **automatically tracked** — the first call to `assignment(for:)` logs an `experiment_exposed` analytics event.

### Setup

```swift
@main
struct MyApp: App {
    private let experiments = AIAnalyticsContainer.makeExperimentEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .aiAnalytics(experimentEngine: experiments)
                .task { await registerExperiments() }
        }
    }

    private func registerExperiments() async {
        await experiments.register(Experiment(
            key: "dashboard_layout",
            variantsByUserType: [.power: "advanced", .explorer: "grid"],
            controlVariant: "standard"   // Casual and At-Risk receive this
        ))
        await experiments.register(Experiment(
            key: "onboarding_flow",
            variantsByUserType: [.atRisk: "simplified"],
            controlVariant: "default"
        ))
    }
}
```

### Querying variants in views

```swift
.task(id: viewModel.viewState.prediction?.userType) {
    let assignment = await experiments.assignment(for: "dashboard_layout")
    showAdvancedDashboard = assignment?.variant == "advanced"
}
```

`ExperimentAssignment` carries the resolved `variant`, `userType`, `confidence`, and `assignedAt` timestamp.

### Exposure tracking

The first call to `assignment(for:)` per experiment key per session automatically logs:

```
AnalyticsEvent(
    name: "experiment_exposed",
    category: .interaction,
    properties: ["experiment_key": "dashboard_layout", "variant": "advanced", "user_type": "Power User"]
)
```

Exposure is reset when the user re-classifies (e.g., moves from Casual to Power), so every new variant assignment is recorded.

### Usage scenarios

| Experiment | Variants | Scenario |
|---|---|---|
| `dashboard_layout` | `advanced` / `grid` / `standard` | Show richer layouts to engaged users |
| `onboarding_flow` | `simplified` / `default` | Reduce friction for at-risk users |
| `cta_copy` | `run_analysis` / `explore_more` / `get_started` / `learn_more` | Match CTA language to user intent |

### Combining flags and experiments

Both can be wired in a single modifier call:

```swift
.aiAnalytics(flagRegistry: flags, experimentEngine: experiments)
```

---

## Real-Time UI Adaptation

Events tracked via `viewModel.trackEvent()` or `viewModel.trackEvents()` automatically schedule a debounced pipeline run. The UI adapts without any manual `loadInsights()` calls.

### How it works

```
Event tracked
    │
    ▼  (cancels any pending timer)
scheduleAdaptation()  ←  2 s debounce
    │
    ▼  (fires once after the quiet period)
loadInsights()
    │
    ▼
viewState = .ready(config, prediction)  →  SwiftUI re-renders
    │
    ▼
flagRegistry.updatePrediction(prediction)    →  flag states refresh
experimentEngine.updatePrediction(prediction) →  variant assignments refresh
    │
    ▼
configurationStream.yield(config)  →  reactive consumers notified
```

Rapid event bursts (e.g., a user tapping through a flow) produce **one** pipeline run after the 2 s quiet period, not one run per event.

### AsyncStream for reactive consumers

```swift
Task {
    for await config in viewModel.configurationStream {
        updateWidget(with: config)
        updateWatchComplication(greeting: config.greeting)
    }
}
```

`configurationStream` is an `AsyncStream<UIConfiguration>` that yields after every successful prediction. The stream finishes when `clearAllEvents()` is called.

### Custom debounce interval

Pass a custom interval when constructing the ViewModel manually:

```swift
let viewModel = HomeViewModel(
    analyticsManager: ...,
    featureBuilder: ...,
    aiEngine: ...,
    personalizationEngine: ...,
    adaptationDebounceInterval: .seconds(5)  // slower for battery-sensitive scenarios
)
```

---

## Use Cases & Scenarios

### E-commerce: Personalized Home Screen

Every user sees the same home screen by default — power buyers are bored, newcomers are overwhelmed.

```swift
AIAnalytics.logEvent("product_viewed", parameters: ["category": "shoes"])
AIAnalytics.logEvent("filter_applied", parameters: ["type": "price"])
AIAnalytics.logScreenView("ProductDetailScreen")
```

Based on accumulated behavior, AIAnalyticsKit adapts the UI automatically:

| Segment | What changes |
|---|---|
| **Power User** | Advanced sorting, bulk actions, early-access badges (`showAdvancedFeatures: true`) |
| **Explorer** | "Discover" tab, cross-category recommendations |
| **At-Risk** | "We Missed You" banner, one-tap re-engagement offers |
| **Casual** | Clean, minimal layout — no feature overload |

---

### Productivity: Progressive Feature Discovery

Your app has 30 features but most users only find 3 of them.

```swift
AIAnalytics.logEvent("document_created")
AIAnalytics.logEvent("template_used")
AIAnalytics.logEvent("analysis_run")   // auto-inferred as .analysis
```

`UIConfiguration.showAdvancedFeatures` is `true` for Power and Explorer users, `false` for Casual and At-Risk — no conditional logic needed in your views. `recommendedActions` also adapt per segment: Power Users see "Batch Export", Explorers see "Try Adapter Mode".

---

### Health & Fitness: Churn Prevention

Users install, engage for a week, then abandon — without a signal you could have acted on.

```swift
AIAnalytics.logEvent("workout_started")
AIAnalytics.logEvent("goal_skipped")
AIAnalytics.logEvent("network_error_occurred")   // raises errorRate
```

When `errorRate` crosses 0.30, the library classifies the user as At-Risk and shifts the UI greeting to "We missed you!" with re-engagement actions. You can also branch on the prediction directly:

```swift
if case .ready(_, let prediction) = viewModel.viewState,
   prediction.userType == .atRisk {
    showChurnPreventionModal()
}
```

---

### Privacy-First Apps (Medical / Legal / Enterprise)

Your users cannot have behavioral data leave the device — compliance forbids it.

AIAnalyticsKit runs **entirely on-device** via Apple's Neural Engine. There are no network calls, no analytics backend, and no third-party SDKs. `HomeView` renders a "Predicted entirely on-device" badge automatically, giving users visible proof of the privacy guarantee.

---

### Custom Personalization Logic

The default 4-segment model doesn't fit your business (subscription tier, A/B cohort, locale).

Every layer of the pipeline is swappable via protocols:

```swift
final class MyPersonalizationEngine: PersonalizationEngineProtocol {
    func configure(for prediction: UserPrediction) -> UIConfiguration {
        // Drive UI from subscription tier, experiment group, or any signal
    }
}
```

Inject it at setup:

```swift
let viewModel = HomeViewModel(
    analyticsManager: ...,
    featureBuilder: ...,
    aiEngine: ...,
    personalizationEngine: MyPersonalizationEngine()
)
```

The same protocol seams (`AIEngine`, `EventStore`, `FeatureBuilding`) work as test doubles in unit tests.

---

### Scenario Summary

| Scenario                  | Segments Used    | Key Benefit                                  |
|---------------------------|------------------|----------------------------------------------|
| E-commerce home screen    | All 4            | Relevant product surface per behavior        |
| Feature discovery         | Power, Explorer  | Progressive disclosure of advanced tools     |
| Churn prevention          | At-Risk          | Detect declining users, trigger re-engagement|
| Privacy-sensitive apps    | —                | Zero data egress, fully on-device            |
| Custom logic              | —                | Full protocol-based DI, every layer swappable|

---

## Advanced Integration

### Manual event tracking with debounced refresh

`AIAnalytics.logEvent()` is fire-and-forget — it persists events and the debounce timer takes care of refreshing the UI after a 2 s quiet period. Use `viewModel.trackEvent()` when you want to participate in the same debounce pipeline:

```swift
@Environment(HomeViewModel.self) private var viewModel

Task {
    await viewModel.trackEvent(
        name: "analysis_started",
        category: .analysis,
        properties: ["type": "deep_scan"]
    )
    // Pipeline runs automatically after the debounce period — no loadInsights() needed
}
```

To run the pipeline immediately (e.g., on an explicit Refresh button tap):

```swift
Task { await viewModel.loadInsights() }
```

### Batch tracking

```swift
let events: [AnalyticsEvent] = [
    AnalyticsEvent(name: "app_opened",    category: .navigation,   properties: ["screen": "home"]),
    AnalyticsEvent(name: "scan_started",  category: .analysis),
    AnalyticsEvent(name: "item_selected", category: .interaction,  properties: ["id": "42"]),
]
await viewModel.trackEvents(events)
// Debounce fires once 2 s after the batch completes
```

### Manual setup (without `.aiAnalytics()`)

For apps that need explicit control over the object graph:

```swift
@main
struct MyApp: App {
    @State private var viewModel = AIAnalytics.makeHomeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .modelContainer(AIAnalytics.modelContainer)
        }
    }
}
```

---

## Public API Reference

### `AIAnalytics` — Static Facade

The primary entry point. Works like Firebase Analytics — call from any file or actor without referencing a ViewModel.

```swift
AIAnalytics.logEvent(_ name: String, parameters: [String: Any] = [:])
AIAnalytics.logScreenView(_ screenName: String, screenClass: String? = nil)

// AI-driven feature flags
AIAnalytics.isFeatureEnabled(_ key: String) async -> Bool

// AI-driven A/B testing
AIAnalytics.experimentVariant(for key: String) async -> ExperimentAssignment?

// Advanced access
AIAnalytics.modelContainer      // @MainActor — ModelContainer for SwiftData
AIAnalytics.makeHomeViewModel() // @MainActor — fully wired HomeViewModel

// Shared registries (set once before first use)
AIAnalytics.flagRegistry: FeatureFlagRegistry?
AIAnalytics.experimentEngine: ExperimentEngine?
```

---

### `View.aiAnalytics()` — Scene Modifier

```swift
// Basic — event tracking and adaptive UI only
ContentView()
    .aiAnalytics()

// With feature flags and A/B testing
ContentView()
    .aiAnalytics(flagRegistry: flags, experimentEngine: experiments)
```

Injects into the SwiftUI environment:
- `.modelContainer(AIAnalytics.modelContainer)` — persistent SwiftData store
- `.environment(HomeViewModel)` — AI insights pipeline, event tracking, flags, and experiments

Idempotent — safe to call multiple times.

---

### `HomeViewModel`

`@Observable @MainActor` class. Access via `@Environment(HomeViewModel.self)`.

**State**

```swift
var viewState: HomeViewState           // .idle | .loading | .ready(config, prediction) | .failure(message)
var eventCount: Int                    // total persisted events
var recentEvents: [AnalyticsEvent]     // all events, newest first
var currentFeatures: UserFeatures?     // last extracted feature vector
var configurationStream: AsyncStream<UIConfiguration>  // yields after every successful prediction
```

**Actions**

```swift
func loadInsights() async                              // run full pipeline immediately
func trackEvent(name:category:properties:) async       // persist one event + schedule debounced refresh
func trackEvents(_ events: [AnalyticsEvent]) async     // persist batch + schedule debounced refresh
func trackSampleEvents() async                         // log 5 built-in sample events
func clearAllEvents() async                            // delete all data, reset state, finish stream
```

---

### `FeatureFlag` · `FeatureFlagRegistry`

```swift
// Define a flag
public struct FeatureFlag: Sendable {
    public let key: String
    public let enabledForUserTypes: Set<UserType>
    public let minimumConfidence: Double          // default: 0.0

    public func isEnabled(for prediction: UserPrediction) -> Bool
}

// Manage and query flags
public actor FeatureFlagRegistry {
    public func register(_ flag: FeatureFlag)
    public func register(_ flags: [FeatureFlag])
    public func isEnabled(_ key: String) -> Bool   // false if no prediction yet
}
```

Built-in key constants in `FeatureFlagKey`: `batchProcessing`, `exportReport`, `advancedFilters`, `reEngagement`.

---

### `Experiment` · `ExperimentEngine` · `ExperimentAssignment`

```swift
// Define an experiment
public struct Experiment: Sendable {
    public let key: String
    public let variantsByUserType: [UserType: String]
    public let controlVariant: String               // default: "control"
}

// Manage experiments and resolve assignments
public actor ExperimentEngine {
    public func register(_ experiment: Experiment)
    public func assignment(for experimentKey: String) async -> ExperimentAssignment?
}

// Assignment result
public struct ExperimentAssignment: Sendable {
    public let experimentKey: String
    public let variant: String
    public let userType: UserType
    public let confidence: Double
    public let assignedAt: Date
}
```

---

### `AnalyticsEvent`

```swift
public struct AnalyticsEvent: Sendable, Identifiable {
    public let id: UUID
    public let name: String                            // max 256 characters
    public let category: EventCategory                 // default: .interaction
    public let properties: [String: String]            // keys ≤ 128 chars, values ≤ 512 chars
    public let timestamp: Date

    public enum EventCategory: String, Sendable, CaseIterable {
        case navigation    // screen transitions
        case interaction   // taps, selections, gestures
        case analysis      // compute-heavy operations
        case error         // failures, timeouts, crashes
    }
}
```

---

### `ClassificationConfig`

Single source of truth for all thresholds and confidence values. Reference these in your own UI logic to stay in sync with the engine.

```swift
public enum ClassificationConfig {
    // Heuristic classification thresholds
    static let atRiskErrorRate: Double       // 0.30
    static let powerUserMinEvents: Int       // 50
    static let powerUserMinAnalyses: Int     // 10
    static let explorerMinScreens: Int       // 5

    // Prediction confidence values
    static let foundationModelConfidence: Double    // 0.85
    static let heuristicFallbackConfidence: Double  // 0.60
    static let coreMLModelConfidence: Double        // 0.75
}
```

---

### `UserFeatures`

6-dimension feature vector produced by `FeatureBuilder` from raw events.

```swift
public struct UserFeatures: Sendable {
    public let totalEvents: Int
    public let uniqueScreens: Int           // distinct "screen" values in navigation events
    public let averageSessionDuration: TimeInterval
    public let errorRate: Double            // errorEvents / totalEvents (0.0 – 1.0)
    public let analysisCount: Int
    public let daysSinceFirstEvent: Int

    public static let empty: UserFeatures
}
```

---

### `UserType` · `UserPrediction`

```swift
public enum UserType: String, Sendable, CaseIterable, Identifiable {
    case power    = "Power User"
    case casual   = "Casual User"
    case explorer = "Explorer"
    case atRisk   = "At-Risk"

    public var icon: String             // SF Symbol name
    public var typeDescription: String  // human-readable description
}

public struct UserPrediction: Sendable {
    public let userType: UserType
    public let confidence: Double  // 0.0 – 1.0, clamped automatically
    public let generatedAt: Date
}
```

---

### `UIConfiguration`

Personalization payload produced by `PersonalizationEngine` and consumed by your views.

```swift
public struct UIConfiguration: Sendable {
    public let greeting: String
    public let accentColor: Color
    public let showAdvancedFeatures: Bool
    public let recommendedActions: [RecommendedAction]

    public struct RecommendedAction: Sendable, Identifiable {
        public let title: String
        public let subtitle: String
        public let icon: String   // SF Symbol name
    }

    public static let `default`: UIConfiguration
}
```

---

### `HomeViewState`

```swift
public enum HomeViewState: Sendable {
    case idle
    case loading
    case ready(UIConfiguration, UserPrediction)
    case failure(String)   // user-friendly message; full error logged via OSLog

    public var isLoading: Bool
    public var configuration: UIConfiguration?
    public var prediction: UserPrediction?
    public var errorMessage: String?
}
```

---

### Reusable UI Components

```swift
CardContainer { /* any SwiftUI content */ }           // material card surface with shadow
SectionHeader(icon: "chart.bar.fill", title: "…")     // icon + uppercase section label
ErrorBanner(message: "…")                             // inline orange error banner
```

---

## User Classification

### Segments

| Type           | Icon | Description                                   |
|----------------|:----:|-----------------------------------------------|
| **Power User** | ⚡   | Highly engaged, frequent and deep interactions |
| **Casual User**| 🌿   | Occasional, surface-level sessions             |
| **Explorer**   | 🧭   | Actively discovering new features and screens  |
| **At-Risk**    | ⚠️   | Declining engagement or elevated error rate    |

### Classification Rules

Rules are evaluated in priority order. All thresholds are defined in `ClassificationConfig`.

```
1.  errorRate > 0.30                              →  At-Risk
2.  totalEvents > 50 AND analysisCount > 10       →  Power User
3.  uniqueScreens > 5                             →  Explorer
4.  (none of the above)                           →  Casual User
```

> `uniqueScreens` is derived from the `"screen"` key in `.navigation` event properties.
> Always include it for accurate Explorer detection:
> `AIAnalytics.logEvent("screen_viewed", parameters: ["screen": "dashboard"])`

### Personalization Map

| User Type    | Accent | Advanced Features | Recommended Actions               |
|--------------|--------|:-----------------:|-----------------------------------|
| Power User   | Purple | ✅                | Batch Analysis · Export Report    |
| Casual User  | Blue   | ❌                | Quick Scan · Getting Started      |
| Explorer     | Teal   | ✅                | Try Adapter Mode · Custom Filters |
| At-Risk      | Orange | ❌                | What's New · Quick Help           |

---

## Architecture

### Data Flow

```
AIAnalytics.logEvent() / viewModel.trackEvent()
        │
        ▼
AnalyticsManager (shared actor)
        │
        ▼
SwiftDataEventStore (@ModelActor)     ← persistent SQLite, survives process restarts
        │
        ▼  (debounced 2 s after last event, or immediate via loadInsights())
FeatureBuilder.buildFeatures(from:)
        │   └─ UserFeatures (6-dimension vector)
        ▼
FoundationPredictionEngine.predict(from:)
        │   └─ SystemLanguageModel(.general) — falls back to deterministic heuristics
        ▼
PersonalizationEngine.configure(for:)
        │   └─ UIConfiguration (greeting · color · actions)
        ▼
HomeView / your SwiftUI views
        │
        ├─► FeatureFlagRegistry.updatePrediction()   →  isEnabled() refreshes
        ├─► ExperimentEngine.updatePrediction()      →  assignment() refreshes
        └─► configurationStream.yield(config)        →  AsyncStream consumers notified
```

### Module Layout

```
Sources/AIAnalyticsKit/
├── AIAnalytics.swift                  ← static facade (logEvent, isFeatureEnabled, experimentVariant)
├── SwiftUI+AIAnalytics.swift          ← .aiAnalytics() view modifier (+ flagRegistry/experimentEngine overload)
├── AI/
│   ├── AIEngine.swift                 ← prediction protocol
│   ├── ClassificationConfig.swift     ← shared thresholds and confidence values
│   ├── FoundationPredictionEngine.swift
│   ├── CoreMLPredictionEngine.swift
│   ├── UserPrediction.swift
│   └── UserType.swift
├── Analytics/
│   ├── AnalyticsEvent.swift
│   ├── AnalyticsManager.swift         ← actor; thread-safe event ingestion (shared singleton)
│   └── AnalyticsTracking.swift        ← protocol for swapping backends
├── Storage/
│   ├── EventStore.swift               ← persistence protocol
│   ├── SwiftDataEventStore.swift      ← @ModelActor SwiftData implementation
│   └── AnalyticsEventModel.swift      ← SwiftData model ↔ domain mapping
├── Features/
│   ├── UserFeatures.swift
│   └── FeatureBuilder.swift           ← events → 6-dimension feature vector
├── FeatureFlags/
│   ├── FeatureFlag.swift              ← flag definition and isEnabled(for:) predicate
│   ├── FeatureFlagKey.swift           ← built-in key constants
│   └── FeatureFlagRegistry.swift      ← actor registry; auto-updated after each prediction
├── Experiments/
│   ├── Experiment.swift               ← experiment definition (key → variant map)
│   ├── ExperimentAssignment.swift     ← resolved variant result
│   ├── ExperimentEngine.swift         ← actor engine; stable assignment + exposure tracking
│   └── CohortIdentity.swift           ← write-once UserDefaults UUID for stable bucketing
├── Personalization/
│   ├── UIConfiguration.swift
│   └── PersonalizationEngine.swift    ← prediction → UIConfiguration
├── Presentation/
│   ├── HomeView.swift                 ← ready-to-use SwiftUI component
│   ├── HomeViewModel.swift            ← @Observable @MainActor orchestrator + debounce + AsyncStream
│   ├── HomeViewState.swift
│   ├── CardContainer.swift
│   ├── SectionHeader.swift
│   └── ErrorBanner.swift
└── Container/
    └── AIAnalyticsContainer.swift     ← composition root; sharedAnalyticsManager; all factory methods
```

---

## Key Design Patterns

**Firebase-style static API** — `AIAnalytics.logEvent()` works from any file or actor without referencing a ViewModel. Fire-and-forget with no `await` required at call sites.

**Swift 6 strict concurrency** — `AnalyticsManager`, `SwiftDataEventStore`, `FeatureFlagRegistry`, and `ExperimentEngine` are all actors. All cross-actor boundaries are explicit. `.swiftLanguageMode(.v6)` is enforced in `Package.swift`.

**`@ModelActor` for SwiftData** — database access happens on a dedicated actor, keeping the main thread free for UI work.

**Explicit view state** — `HomeViewState` is a value-type enum. No ambiguous `isLoading + data` flag combinations.

**Protocol seams everywhere** — `AIEngine`, `EventStore`, `FeatureBuilding`, `PersonalizationEngineProtocol`. Swap any layer with a custom or test implementation by injecting into `HomeViewModel.init`.

**Debounced real-time adaptation** — `trackEvent()` / `trackEvents()` schedule a 2 s debounced `loadInsights()`. Rapid event bursts produce one pipeline run, not one per event. The interval is configurable.

**AsyncStream output** — `HomeViewModel.configurationStream` is an `AsyncStream<UIConfiguration>` that yields after every successful prediction. Useful for widgets, watch complications, or any non-SwiftUI consumer.

**Shared `AnalyticsManager`** — `AIAnalytics.logEvent()` and `HomeViewModel` share the same `AnalyticsManager` instance (`AIAnalyticsContainer.sharedAnalyticsManager`), so static fire-and-forget events are always visible to the AI pipeline.

**Graceful degradation** — SwiftData persistent store failure falls back to an in-memory store. Foundation Models unavailability falls back to deterministic heuristics. The app remains functional in both cases.

---

## Demo App

`Examples/AIAnalyticsKitDemo/` is a standalone Xcode project — open `AIAnalyticsKitDemo.xcodeproj` directly. No workspace needed.

```bash
xcodebuild \
  -project Examples/AIAnalyticsKitDemo/AIAnalyticsKitDemo.xcodeproj \
  -scheme AIAnalyticsKitDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

| Screen                | What it demonstrates                                                                        |
|-----------------------|---------------------------------------------------------------------------------------------|
| **Onboarding**        | 3-page swipeable intro with privacy messaging                                               |
| **Insights**          | Live `HomeView` — adaptive greeting, accent color, and recommended actions                  |
| **Events**            | Category breakdown, quick-log buttons, behavior simulators                                  |
| **Feature Vector**    | Animated progress bars per `UserFeatures` dimension, classification threshold legend        |
| **AI Engine**         | Foundation Models info, confidence gauge, feature attribution, privacy guarantees           |
| **Personalization**   | Live feature flag ON/OFF states, A/B experiment variant assignments, real-time adaptation   |
| **User Types**        | Expandable cards for all 4 types — personalization preview and classification rules         |
| **Settings**          | Engine info, live event count, clear data with confirmation                                 |

---

## Contributing

Contributions are welcome. Please follow these steps:

1. Fork the repository and create a feature branch from `main`
2. Make your changes with Swift 6 strict concurrency (`-strict-concurrency=complete`)
3. Ensure `swift build` and `swift test` pass cleanly
4. Open a pull request with a clear description of the change and its motivation

For significant changes, open an issue first to discuss the approach.

---

## License

MIT © 2025 — See [LICENSE](LICENSE)
