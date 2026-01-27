// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "elementary-swift",
  platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
  products: [
    .executable(name: "App", targets: ["App"])
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0", traits: [.defaults, "CommandLineArguments"]),
    // Database dependencies
    .package(url: "https://github.com/lovetodream/oracle-nio.git", branch: "main"),
    // Elementary
    .package(url: "https://github.com/elementary-swift/elementary.git", from: "0.6.0"),
    .package(url: "https://github.com/hummingbird-community/hummingbird-elementary.git", from: "0.3.0"),
    // Styling
    .package(url: "https://github.com/kicsipixel/SwiftKaze.git", from: "0.1.0"),
  ],
  targets: [
    .executableTarget(
      name: "App",
      dependencies: [
        .product(name: "Configuration", package: "swift-configuration"),
        .product(name: "Hummingbird", package: "hummingbird"),
        // Database dependencies
        .product(name: "OracleNIO", package: "oracle-nio"),
        // Elementary
        .product(name: "Elementary", package: "elementary"),
        .product(name: "HummingbirdElementary", package: "hummingbird-elementary"),
        // Styling
        .product(name: "SwiftKaze", package: "SwiftKaze"),
      ],
      path: "Sources/App",
      resources: [.process("Resources")]
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
