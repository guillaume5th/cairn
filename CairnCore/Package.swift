// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CairnCore",
    platforms: [.macOS(.v27)],
    products: [
        .library(name: "CairnCore", targets: ["CairnCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", from: "10.10.2"),
    ],
    targets: [
        .target(name: "CairnCore", dependencies: ["FeedKit"]),
        .testTarget(
            name: "CairnCoreTests",
            dependencies: ["CairnCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
