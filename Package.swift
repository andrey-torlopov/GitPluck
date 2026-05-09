// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GitPluck",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "GitPluck", targets: ["GitPluckCLI"])
    ],
    targets: [
        .target(name: "GitPluckCore"),
        .executableTarget(
            name: "GitPluckCLI",
            dependencies: ["GitPluckCore"]
        ),
        .testTarget(
            name: "GitPluckCoreTests",
            dependencies: ["GitPluckCore"]
        )
    ]
)
