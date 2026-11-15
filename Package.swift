// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZoomMicStatus",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        // Pure logic, no AppKit: everything here is unit-tested.
        .target(name: "ZoomMicStatusCore"),
        .executableTarget(
            name: "ZoomMicStatus",
            dependencies: [
                "ZoomMicStatusCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ]
        ),
        .testTarget(
            name: "ZoomMicStatusCoreTests",
            dependencies: ["ZoomMicStatusCore"]
        ),
    ]
)
