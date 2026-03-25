// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SDOnDeviceAIAnalytics",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SDOnDeviceAIAnalytics",
            targets: ["SDOnDeviceAIAnalytics"]
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
            name: "SDOnDeviceAIAnalytics",
            path: "Sources/SDOnDeviceAIAnalytics",
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
