// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SaunaBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SaunaBar",
            path: "Sources/SaunaBar"
        ),
        .testTarget(
            name: "SaunaBarTests",
            dependencies: ["SaunaBar"],
            path: "Tests/SaunaBarTests"
        ),
    ]
)
