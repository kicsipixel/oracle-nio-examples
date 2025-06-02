// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BasicAuth",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
  products: [
    .executable(name: "App", targets: ["App"])
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.14.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    // Database dependencies
    .package(url: "https://github.com/lovetodream/oracle-nio.git", branch: "main"),
    // Authentication
    .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.0.2"),
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Hummingbird", package: "hummingbird"),
        // Database dependencies
        .product(name: "OracleNIO", package: "oracle-nio"),
        // Authentication
        .product(name: "HummingbirdBcrypt", package: "hummingbird-auth"),
        .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
        .product(name: "HummingbirdBasicAuth", package: "hummingbird-auth"),
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
