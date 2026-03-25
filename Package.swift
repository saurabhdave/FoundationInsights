// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIAnalyticsKit",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
    ],
    products: [
        .library(
            name: "AIAnalyticsKit",
            targets: ["AIAnalyticsKit"]
        ),
    ],
    targets: [
        .target(
            name: "AIAnalyticsKit",
            path: "Sources/AIAnalyticsKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
