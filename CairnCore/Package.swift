// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CairnCore",
    platforms: [.macOS(.v27), .iOS(.v27)],
    products: [
        .library(name: "CairnCore", targets: ["CairnCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", from: "10.10.2"),
    ],
    targets: [
        // Readability.js 0.6.0 (Mozilla, Apache 2.0), from the npm package @mozilla/readability.
        .target(name: "CairnCore", dependencies: ["FeedKit"],
                exclude: ["Resources/Readability-LICENSE.md"], resources: [.copy("Resources/Readability.js")]),
        .testTarget(
            name: "CairnCoreTests",
            dependencies: ["CairnCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
