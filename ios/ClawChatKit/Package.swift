// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClawChatKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "ClawChatKit", targets: ["ClawChatKit"]),
    ],
    targets: [
        .target(
            name: "ClawChatKit",
            path: "Sources/ClawChatKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ClawChatKitTests",
            dependencies: ["ClawChatKit"],
            path: "Tests/ClawChatKitTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
