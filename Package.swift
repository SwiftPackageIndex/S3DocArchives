// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "spi-s3-check",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "s3-check", targets: ["S3Check"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.2"),
        .package(url: "https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server",
                 from: "2.71.0"),
    ],
    targets: [
        .executableTarget(
            name: "S3Check",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "S3DocArchives", package: "SwiftPackageIndex-Server"),
            ]),
        .testTarget(
            name: "S3CheckTests",
            dependencies: ["S3Check"]),
    ]
)
