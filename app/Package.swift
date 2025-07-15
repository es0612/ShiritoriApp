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
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.2"),
    ],
    targets: [
        .target(
            name: "ShiritoriCore",
            dependencies: [],
            path: "Sources/ShiritoriCore"
        ),
        .testTarget(
            name: "ShiritoriCoreTests",
            dependencies: [
                "ShiritoriCore",
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "Tests/ShiritoriCoreTests"
        ),
    ]
)