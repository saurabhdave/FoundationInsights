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
xcodebuild -project Examples/AIAnalyticsKitDemo/AIAnalyticsKitDemo.xcodeproj \
  -scheme AIAnalyticsKitDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

## Architecture

**AIAnalyticsKit** is an on-device user behavior analytics and AI personalization library using Apple's Foundation Models framework (iOS 26+). It classifies users entirely on-device via the Neural Engine — no network calls, no data egress.

### One Target

- **AIAnalyticsKit** (library) — the main product consumed by apps

### Key Data Flow

```
User Action
  ↓
AnalyticsManager.track(_:) / trackBatch(_:)
  ↓
SwiftDataEventStore (persistence)
  ↓
FeatureBuilder.buildFeatures(from:)
  ↓
FoundationPredictionEngine.predict(from:)
  ↓
PersonalizationEngine.configure(for:)
  ↓
HomeView (renders UIConfiguration + UserPrediction)
```

### Module Structure

```
Sources/AIAnalyticsKit/
├── AI/                        ← Prediction protocols + engines
│   ├── AIEngine.swift
│   ├── FoundationPredictionEngine.swift
│   ├── CoreMLPredictionEngine.swift
│   ├── UserPrediction.swift
│   └── UserType.swift
├── Analytics/                 ← Event tracking
│   ├── AnalyticsTracking.swift
│   ├── AnalyticsEvent.swift
│   └── AnalyticsManager.swift
├── Storage/                   ← SwiftData persistence
│   ├── EventStore.swift
│   ├── AnalyticsEventModel.swift
│   └── SwiftDataEventStore.swift
├── Features/                  ← Feature vector extraction
│   ├── UserFeatures.swift
│   └── FeatureBuilder.swift
├── Personalization/           ← UI configuration from prediction
│   ├── UIConfiguration.swift
│   └── PersonalizationEngine.swift
├── Presentation/              ← SwiftUI views + ViewModel
│   ├── HomeView.swift
│   ├── HomeViewModel.swift
│   ├── HomeViewState.swift
│   ├── CardContainer.swift
│   ├── SectionHeader.swift
│   └── ErrorBanner.swift
└── Container/
    └── AIAnalyticsContainer.swift   ← Composition root / DI factory
```

### Key Patterns

**Actor isolation**: `AnalyticsManager` and `SwiftDataEventStore` are actors for thread-safe concurrency. Swift 6 strict concurrency is enforced.

**Protocol-based DI**: `AIEngine`, `EventStore`, `FeatureBuilding`, `PersonalizationEngineProtocol` — swap implementations for testing.

**SwiftData persistence**: `@ModelActor SwiftDataEventStore` uses background-safe database access. `AnalyticsEventModel` maps to/from the domain `AnalyticsEvent`.

**Explicit view state**: `HomeViewState` enum (`idle / loading / ready / failure`) drives all UI transitions.

**Foundation Models prediction**: `FoundationPredictionEngine` uses `SystemLanguageModel(useCase: .general)` with a heuristic fallback when the model is unavailable (simulator). Heuristic thresholds: `errorRate > 0.3` → At-Risk, `totalEvents > 50 && analysisCount > 10` → Power, `uniqueScreens > 5` → Explorer, else Casual.

**`AIAnalyticsContainer` is `@MainActor`** — call `makeHomeViewModel()` and access `modelContainer` from the main actor only.

> **Known issue**: `FoundationPredictionEngine` logger subsystem is still `"com.app.FoundationInsightsDemo"` — a leftover from the old package name. Update to match the new bundle ID when integrating.

### Public API

- `AIAnalyticsContainer.makeHomeViewModel()` → `HomeViewModel` (factory entry point)
- `AIAnalyticsContainer.modelContainer` → `ModelContainer` (inject into SwiftUI `.modelContainer()`)
- `HomeView` → ready-to-use SwiftUI view (requires `HomeViewModel` in environment)
- `HomeViewModel` → `@Observable @MainActor` class for `@Environment` injection
- `UserType` / `UserPrediction` → domain types (public)

### Swift Version & Platform

- Swift 6.0 (strict concurrency, `.swiftLanguageMode(.v6)`)
- iOS 26.0 minimum, macOS 26.0 minimum
- No external dependencies — only Apple frameworks: `FoundationModels`, `SwiftData`, `SwiftUI`, `OSLog`

### Sample App

`Examples/AIAnalyticsKitDemo/` is a standalone Xcode project that imports AIAnalyticsKit as a local SPM dependency (`relativePath = "../.."`). Open `AIAnalyticsKitDemo.xcodeproj` directly — no workspace needed.

- Works in the iOS Simulator (Foundation Models `.general` use case)
- `AIAnalyticsContainer` wires the full object graph at launch
