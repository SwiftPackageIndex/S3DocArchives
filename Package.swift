// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "spi-s3-check",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.2"),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.9.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "s3-check",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "SotoS3", package: "soto"),
            ]),
        .testTarget(
            name: "S3CheckTests",
            dependencies: ["s3-check"]),
    ]
)
