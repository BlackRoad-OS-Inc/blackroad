// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BlackRoad",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BlackRoad", targets: ["BlackRoad"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BlackRoad",
            path: "Sources/BlackRoad",
            resources: [.process("Resources")]
        ),
    ]
)
