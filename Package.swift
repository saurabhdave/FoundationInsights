// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FoundationInsights",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .library(
            name: "FoundationInsights",
            targets: ["FoundationInsights"]
        ),
        // The extension is an executable product so downstream Xcode projects
        // can embed the built binary as a Background Assets App Extension.
        .executable(
            name: "AdapterDownloadExtension",
            targets: ["AdapterDownloadExtension"]
        ),
    ],
    targets: [
        .target(
            name: "FoundationInsights",
            path: "Sources/FoundationInsights",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "AdapterDownloadExtension",
            path: "Sources/AdapterDownloadExtension",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
