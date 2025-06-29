// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "s3-compatibility",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.14.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        // Database dependencies
        .package(url: "https://github.com/lovetodream/oracle-nio.git", branch: "main"),
        // Soto
        .package(url: "https://github.com/soto-project/soto.git", from: "7.7.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                // Database dependencies
                .product(name: "OracleNIO", package: "oracle-nio"),
                // Soto
                .product(name: "SotoS3", package: "soto")
            ],
            path: "Sources/App",
            resources: [.process("Credentials")]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .byName(name: "App"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            path: "Tests/AppTests"
        ),
    ]
)
