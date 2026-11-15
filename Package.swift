// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZoomMicStatus",
    platforms: [.macOS(.v15)],
    targets: [
        // Pure logic, no AppKit: everything here is unit-tested.
        .target(name: "ZoomMicStatusCore"),
        .executableTarget(
            name: "ZoomMicStatus",
            dependencies: ["ZoomMicStatusCore"]
        ),
        .testTarget(
            name: "ZoomMicStatusCoreTests",
            dependencies: ["ZoomMicStatusCore"]
        ),
    ]
)
