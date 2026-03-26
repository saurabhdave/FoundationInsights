<div align="center">

<br/>

<img src="https://img.shields.io/badge/AIAnalyticsKit-1.0-6E40C9?style=for-the-badge&logoColor=white" alt="AIAnalyticsKit"/>

### On-device user behavior analytics and AI personalization
### powered by Apple's Foundation Models framework

*Classify users · Extract features · Personalize UI — entirely on the Neural Engine*

<br/>

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![macOS](https://img.shields.io/badge/macOS-26.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/macos/)
[![SPM](https://img.shields.io/badge/SPM-compatible-34C759?style=flat-square)](https://swift.org/package-manager/)
[![Foundation Models](https://img.shields.io/badge/Foundation%20Models-✦-6E40C9?style=flat-square)](https://developer.apple.com/documentation/foundationmodels)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

</div>

---

## Overview

AIAnalyticsKit is a Swift 6 library that brings AI-powered user classification and adaptive UI personalization entirely on-device. It tracks user behavior events, extracts a feature vector, feeds it into Apple's Foundation Models framework, and delivers a tailored `UIConfiguration` — all without a network request.

```
Track events  →  Build features  →  Predict user type  →  Adapt your UI
     ↓                ↓                    ↓                    ↓
SwiftData        6-dimension           Foundation           Greeting ·
persistence      feature vector        Models on            Accent color ·
                                       Neural Engine        Recommended
                                                            actions
```

---

## Why AIAnalyticsKit?

Traditional personalization pipelines ship user data to a remote server. AIAnalyticsKit keeps everything on-device:

|                        | Traditional Pipeline | AIAnalyticsKit     |
|------------------------|:--------------------:|:------------------:|
| Network required       | ✅                   | ❌                 |
| User data leaves device| ✅                   | ❌                 |
| Inference latency      | 500 ms – 2 s         | **< 200 ms**       |
| Works offline          | ❌                   | ✅                 |
| Privacy compliant      | Conditional          | ✅ by design       |
| Personalized UI        | ❌                   | ✅                 |

---

## Features

**⚡ On-Device AI Prediction**
Uses `SystemLanguageModel(useCase: .general)` to classify users as Power, Casual, Explorer, or At-Risk. Automatically falls back to a deterministic heuristic when the model is unavailable (e.g. iOS Simulator).

**📊 Automatic Feature Engineering**
`FeatureBuilder` extracts a 6-dimension feature vector from raw events: total events, unique screens, analysis count, error rate, session depth, and days active.

**🛡️ SwiftData Persistence**
`@ModelActor SwiftDataEventStore` provides background-safe, actor-isolated storage. Events survive app restarts and accumulate across sessions.

**🎨 Adaptive UI Personalization**
`PersonalizationEngine` maps each prediction to a concrete `UIConfiguration`: greeting text, accent color, advanced feature visibility, and personalized recommended actions.

**🔒 Zero Data Egress**
No network calls. No third-party SDKs. The SwiftData store is sandboxed to the app container.

**🧩 Protocol-Based DI**
Every layer is backed by a protocol (`AIEngine`, `EventStore`, `FeatureBuilding`, `PersonalizationEngineProtocol`). Swap in test doubles without changing any call sites.

---

## Requirements

| Requirement   | Minimum   |
|---------------|-----------|
| iOS           | **26.0**  |
| macOS         | **26.0**  |
| Xcode         | **26.0**  |
| Swift         | **6.0**   |

No external dependencies — only Apple frameworks: `FoundationModels`, `SwiftData`, `SwiftUI`, `OSLog`.

---

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/saurabhdave/FoundationInsights", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["AIAnalyticsKit"]
    )
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the repository URL.

---

## Quick Start

### 1 · Wire the entry point

`AIAnalyticsContainer` is `@MainActor` — call it from your `App` struct.

```swift
import SwiftUI
import AIAnalyticsKit

@main
struct MyApp: App {

    @State private var viewModel = AIAnalyticsContainer.makeHomeViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(viewModel)
                .modelContainer(AIAnalyticsContainer.modelContainer)
        }
    }
}
```

### 2 · Track events

```swift
// Single event
await viewModel.trackEvent(
    name: "screen_viewed",
    category: .navigation,
    properties: ["screen": "dashboard"]
)

// Batch of events
let events: [AnalyticsEvent] = [
    AnalyticsEvent(name: "app_opened",    category: .navigation,   properties: ["screen": "home"]),
    AnalyticsEvent(name: "scan_started",  category: .analysis),
    AnalyticsEvent(name: "item_selected", category: .interaction,  properties: ["id": "42"]),
]
await viewModel.trackEvents(events)
```

### 3 · Run the prediction pipeline

```swift
// Fetches events → builds features → predicts → personalizes
await viewModel.loadInsights()

// Read the result
switch viewModel.viewState {
case .ready(let config, let prediction):
    print(prediction.userType.rawValue)  // "Power User"
    print(config.greeting)               // "Welcome back, power user"
    print(config.accentColor)            // Color.purple
case .failure(let message):
    print(message)
default:
    break
}
```

### 4 · Use the ready-made view (optional)

`HomeView` runs the pipeline automatically on `.task {}` and renders the adaptive UI:

```swift
NavigationStack {
    HomeView()
}
.environment(viewModel)
```

---

## Public API

### `AIAnalyticsContainer`

Composition root. All factory methods are `@MainActor`.

```swift
// Create the fully-wired view model
let viewModel = AIAnalyticsContainer.makeHomeViewModel()

// SwiftData model container (inject into .modelContainer())
let container = AIAnalyticsContainer.modelContainer
```

---

### `HomeViewModel`

`@Observable @MainActor` class. The primary integration point.

#### State

```swift
var viewState: HomeViewState     // idle | loading | ready(config, prediction) | failure(message)
var eventCount: Int              // total persisted events
var recentEvents: [AnalyticsEvent]   // all events, newest first, updated after each pipeline run
var currentFeatures: UserFeatures?   // last extracted feature vector, nil before first run
```

#### Actions

```swift
// Full pipeline: fetch → features → predict → personalize
func loadInsights() async

// Track one event then refresh the pipeline
func trackEvent(name: String, category: AnalyticsEvent.EventCategory, properties: [String: String] = [:]) async

// Track a batch of events then refresh the pipeline
func trackEvents(_ events: [AnalyticsEvent]) async

// Insert 5 built-in sample events (useful for testing)
func trackSampleEvents() async

// Delete all persisted events and reset to idle
func clearAllEvents() async
```

---

### `AnalyticsEvent`

```swift
public struct AnalyticsEvent: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: EventCategory
    public let properties: [String: String]
    public let timestamp: Date

    public enum EventCategory: String, Sendable, CaseIterable {
        case navigation    // screen transitions
        case interaction   // taps, selections, gestures
        case analysis      // compute-heavy operations
        case error         // failures, timeouts, crashes
    }

    public init(
        name: String,
        category: EventCategory,
        properties: [String: String] = [:],
        timestamp: Date = .now
    )
}
```

---

### `UserFeatures`

The 6-dimension feature vector produced by `FeatureBuilder`.

```swift
public struct UserFeatures: Sendable {
    public let totalEvents: Int            // total event count
    public let uniqueScreens: Int          // distinct "screen" property values in navigation events
    public let averageSessionDuration: TimeInterval
    public let errorRate: Double           // errorCount / totalEvents  (0.0 – 1.0)
    public let analysisCount: Int          // number of .analysis category events
    public let daysSinceFirstEvent: Int

    public static let empty: UserFeatures  // zero-value placeholder
}
```

---

### `UserType`

```swift
public enum UserType: String, Sendable, CaseIterable, Identifiable {
    case power    = "Power User"
    case casual   = "Casual User"
    case explorer = "Explorer"
    case atRisk   = "At-Risk"

    public var icon: String            // SF Symbol name
    public var typeDescription: String // human-readable description
}
```

---

### `UserPrediction`

```swift
public struct UserPrediction: Sendable {
    public let userType: UserType
    public let confidence: Double   // 0.0 – 1.0, auto-clamped
    public let generatedAt: Date
}
```

---

### `UIConfiguration`

The personalization payload produced by `PersonalizationEngine`.

```swift
public struct UIConfiguration: Sendable {
    public let greeting: String
    public let accentColor: Color
    public let showAdvancedFeatures: Bool
    public let recommendedActions: [RecommendedAction]

    public struct RecommendedAction: Sendable, Identifiable {
        public let id: UUID
        public let title: String
        public let subtitle: String
        public let icon: String       // SF Symbol name
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
    case failure(String)

    public var isLoading: Bool
    public var configuration: UIConfiguration?
    public var prediction: UserPrediction?
    public var errorMessage: String?
}
```

---

### Reusable UI Components

These components follow the same design language as `HomeView` and are available for use in your own views.

```swift
// Card surface — rounded corners, blur material, shadow
CardContainer { /* any SwiftUI content */ }

// ICON + LABEL section header with uppercase tracking
SectionHeader(icon: "chart.bar.fill", title: "Analytics Status")

// Orange-tinted inline error banner
ErrorBanner(message: "Prediction failed — try refreshing.")
```

---

## User Classification

### User Types

| Type | Icon | Description |
|---|:---:|---|
| **Power User** | ⚡ | Highly engaged, frequent deep interactions |
| **Casual User** | 🌿 | Occasional, surface-level sessions |
| **Explorer** | 🧭 | Actively discovering new features and screens |
| **At-Risk** | ⚠️ | Declining engagement, high error rate |

### Classification Rules

The heuristic engine (active when Foundation Models is unavailable) and the AI prompt both use these thresholds, evaluated in priority order:

```
1. errorRate > 0.30                          → At-Risk
2. totalEvents > 50 AND analysisCount > 10   → Power User
3. uniqueScreens > 5                         → Explorer
4. (none of the above)                       → Casual User
```

> **Note:** `uniqueScreens` is derived from the `"screen"` key in `.navigation` event properties. Always include it: `properties: ["screen": "dashboard"]`.

### Personalization Map

| User Type    | Accent   | Advanced Features | Recommended Actions                  |
|--------------|----------|:-----------------:|--------------------------------------|
| Power User   | Purple   | ✅                | Batch Analysis · Export Report       |
| Casual User  | Blue     | ❌                | Quick Scan · Getting Started         |
| Explorer     | Teal     | ✅                | Try Adapter Mode · Custom Filters    |
| At-Risk      | Orange   | ❌                | What's New · Quick Help              |

---

## Architecture

### Pipeline

```
User Action
    │
    ▼
HomeViewModel.trackEvent / trackEvents
    │
    ▼
AnalyticsManager (actor)
    │
    ▼
SwiftDataEventStore (@ModelActor)   ← persistent SwiftData store
    │
    ▼
HomeViewModel.loadInsights()
    │
    ├── FeatureBuilder.buildFeatures(from:)
    │       └── UserFeatures (6-dim vector)
    │
    ├── FoundationPredictionEngine.predict(from:)
    │       └── SystemLanguageModel(.general) or heuristic fallback
    │
    └── PersonalizationEngine.configure(for:)
            └── UIConfiguration (greeting · color · actions)
```

### Module Layout

```
Sources/AIAnalyticsKit/
├── AI/                  AIEngine protocol · FoundationPredictionEngine
│                        CoreMLPredictionEngine · UserType · UserPrediction
├── Analytics/           AnalyticsEvent · AnalyticsManager · AnalyticsTracking
├── Storage/             EventStore protocol · SwiftDataEventStore · AnalyticsEventModel
├── Features/            UserFeatures · FeatureBuilder
├── Personalization/     UIConfiguration · PersonalizationEngine
├── Presentation/        HomeView · HomeViewModel · HomeViewState
│                        CardContainer · SectionHeader · ErrorBanner
└── Container/           AIAnalyticsContainer  ← composition root / DI factory
```

---

## Demo App

`Examples/AIAnalyticsKitDemo/` is a standalone Xcode project showcasing every API surface. Open `AIAnalyticsKitDemo.xcodeproj` directly — no workspace needed.

```
xcodebuild -project Examples/AIAnalyticsKitDemo/AIAnalyticsKitDemo.xcodeproj \
           -scheme AIAnalyticsKitDemo \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build
```

### Screens

| Screen | What it shows |
|---|---|
| **Onboarding** | 3-page swipeable intro with animated gradients and privacy messaging |
| **Insights** | Live `HomeView` — adaptive greeting, accent color, recommended actions |
| **Events** | Category breakdown, per-type quick-track buttons, one-tap behavior simulators (Power / Explorer / At-Risk / Reset), scrollable event history |
| **Feature Vector** | Animated progress bars for each `UserFeatures` dimension, color-coded status, classification threshold legend |
| **AI Engine** | Foundation Models engine info, confidence gauge, feature attribution rows, privacy guarantees |
| **User Types** | Expandable cards for all 4 types — personalization preview, classification trigger, current prediction highlighted |
| **Settings** | Engine + privacy info, live event count, destructive clear with confirmation, replay onboarding |

---

## Key Design Patterns

**Swift 6 strict concurrency** — `AnalyticsManager` and `SwiftDataEventStore` are actors. All cross-actor boundaries are explicit. `.swiftLanguageMode(.v6)` is enforced in `Package.swift`.

**`@ModelActor` for SwiftData** — database access happens on a dedicated actor, preventing main-thread blocking.

**Explicit view state** — `HomeViewState` is a value-type enum. No ambiguous `isLoading + data` flag combinations.

**Protocol seams everywhere** — `AIEngine`, `EventStore`, `FeatureBuilding`, `PersonalizationEngineProtocol`. Replace any layer with a test double by passing it to `HomeViewModel.init`.

---

## License

MIT © 2025 · See [LICENSE](LICENSE)
