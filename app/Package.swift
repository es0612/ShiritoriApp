// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShiritoriCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ShiritoriCore",
            targets: ["ShiritoriCore"]
        ),
    ],
    dependencies: [
        // SwiftDataとSwiftUIはシステムフレームワークのため依存関係不要
    ],
    targets: [
        .target(
            name: "ShiritoriCore",
            dependencies: [],
            path: "Sources/ShiritoriCore"
        ),
        .testTarget(
            name: "ShiritoriCoreTests",
            dependencies: ["ShiritoriCore"],
            path: "Tests/ShiritoriCoreTests"
        ),
    ]
)