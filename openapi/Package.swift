// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "openapi",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
  products: [
    .executable(name: "App", targets: ["App"])
  ],
  dependencies: [
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.11.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    // OpenAPI
    .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.3.0"),
    .package(url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.0.0"),
    // Database
    .package(url: "https://github.com/lovetodream/oracle-nio.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "APIService",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
      ],
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
      ]
    ),
    .executableTarget(
      name: "App",
      dependencies: [
        .target(name: "APIService"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Hummingbird", package: "hummingbird"),
        // OpenAPI
        .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
        // Database
        .product(name: "OracleNIO", package: "oracle-nio"),
      ],
      path: "Sources/App"
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
