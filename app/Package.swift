// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShiritoriCore",
    // macOS は `swift test` を手元で速く回すためだけに入れている（配布対象は iOS）
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "ShiritoriCore", targets: ["ShiritoriCore"]),
    ],
    targets: [
        .target(
            name: "ShiritoriCore",
            path: "Sources/ShiritoriCore",
            // アプリが返事に使う言葉の辞書（words.json）
            resources: [.process("WordBank/Resources")]
        ),
        .testTarget(
            name: "ShiritoriCoreTests",
            dependencies: ["ShiritoriCore"],
            path: "Tests/ShiritoriCoreTests"
        ),
    ]
)
