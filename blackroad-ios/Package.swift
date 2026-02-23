// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BlackRoad",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BlackRoad",    targets: ["BlackRoad"]),
        .library(name: "BlackRoadMac", targets: ["BlackRoadMac"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BlackRoad",
            path: "Sources/BlackRoad",
            resources: [.process("Resources")]
        ),
        .target(
            name: "BlackRoadMac",
            path: "Sources/BlackRoadMac",
            swiftSettings: [.define("MACOS")]
        ),
    ]
)
