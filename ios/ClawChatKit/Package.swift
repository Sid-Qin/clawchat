// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClawChatKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ClawChatKit", targets: ["ClawChatKit"]),
    ],
    targets: [
        .target(
            name: "ClawChatKit",
            path: "Sources/ClawChatKit"
        ),
        .testTarget(
            name: "ClawChatKitTests",
            dependencies: ["ClawChatKit"],
            path: "Tests/ClawChatKitTests"
        ),
    ]
)
