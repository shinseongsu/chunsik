// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Chunsik",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "Chunsik",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "Sources/Chunsik",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
