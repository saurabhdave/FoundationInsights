<div align="center">

# 🧠 AIAnalyticsKit

**On-device user behavior analytics and AI personalization powered by Apple's Foundation Models framework.**

Classify users, build feature vectors, and deliver personalized UI —
entirely on-device, zero network latency, zero data egress.

<br/>

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-34C759?style=flat-square)](https://swift.org/package-manager/)
[![Foundation Models](https://img.shields.io/badge/Foundation%20Models-✦-6E40C9?style=flat-square)](https://developer.apple.com/documentation/foundationmodels)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

</div>

---

## ✦ Why AIAnalyticsKit?

Most analytics and personalization pipelines ship user data to a remote server for processing — introducing latency, privacy risk, and an internet dependency. AIAnalyticsKit runs the entire pipeline on the device's Neural Engine:

| | Traditional Pipeline | AIAnalyticsKit |
|---|:---:|:---:|
| Network required | ✅ | ❌ |
| User data leaves device | ✅ | ❌ |
| Inference latency | 500 ms – 2 s | **< 200 ms** |
| Works offline | ❌ | ✅ |
| Personalized UI | ❌ | ✅ |

---

## ✦ Features

<table>
<tr>
<td width="50%">

**⚡ On-Device AI Prediction**
Uses `SystemLanguageModel` to classify users as Power, Casual, Explorer, or At-Risk. Falls back to a heuristic when the model is unavailable.

</td>
<td width="50%">

**🎯 Feature Engineering**
Extracts a rich feature vector (event count, unique screens, error rate, session depth) from raw analytics events.

</td>
</tr>
<tr>
<td>

**🛡️ SwiftData Persistence**
Actor-isolated `@ModelActor` store. Analytics events survive app restarts and are available for batch analysis.

</td>
<td>

**🎨 Adaptive UI**
`PersonalizationEngine` maps predictions to greeting, accent color, feature visibility, and recommended actions.

</td>
</tr>
</table>

---

## ✦ Architecture

```
User Action
    ↓
AnalyticsManager          (actor, Swift 6)
    ↓
SwiftDataEventStore       (@ModelActor persistence)
    ↓
FeatureBuilder            (event → feature vector)
    ↓
FoundationPredictionEngine  (SystemLanguageModel)
    ↓
PersonalizationEngine     (prediction → UIConfiguration)
    ↓
HomeView                  (SwiftUI, @Observable)
```

### SPM Target

```
AIAnalyticsKit/
├── Sources/
│   └── AIAnalyticsKit/
│       ├── AI/
│       ├── Analytics/
│       ├── Storage/
│       ├── Features/
│       ├── Personalization/
│       ├── Presentation/
│       └── Container/
└── Package.swift
```

---

## ✦ Requirements

| | Minimum |
|---|---|
| 📱 iOS | **26.0** |
| 🔨 Xcode | **26.0** |
| 🐦 Swift | **6.0** |

---

## ✦ Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/AIAnalyticsKit", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["AIAnalyticsKit"]
    )
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the repo URL.

---

## ✦ Quick Start

### Step 1 — Wire up the app entry point

```swift
import SwiftUI
import AIAnalyticsKit

@main
struct MyApp: App {

    @State private var homeViewModel = AIAnalyticsContainer.makeHomeViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(homeViewModel)
                .modelContainer(AIAnalyticsContainer.modelContainer)
        }
    }
}
```

### Step 2 — Track events

```swift
// Track a single event
await analyticsManager.track(
    AnalyticsEvent(name: "screen_viewed", category: .navigation, properties: ["screen": "dashboard"])
)

// Track a batch
await analyticsManager.trackBatch(events)
```

### Step 3 — Let the pipeline run

`HomeView` automatically runs the full pipeline on `.task {}`:
- Fetches all events from SwiftData
- Builds the feature vector
- Runs on-device AI prediction
- Maps to a personalized `UIConfiguration`
- Renders the adaptive UI

---

## ✦ User Types

| Type | Trigger | UI Treatment |
|---|---|---|
| **Power User** | High event count + deep analysis | Purple accent, advanced features unlocked |
| **Casual User** | Low engagement | Blue accent, simplified UI |
| **Explorer** | High unique screen count | Teal accent, discovery-focused |
| **At-Risk** | High error rate | Orange accent, re-engagement actions |

---

## ✦ License

MIT © 2025
