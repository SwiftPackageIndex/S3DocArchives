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
        // Replace the revision with a proper tag once we have one.
        .package(url: "https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server",
                 revision: "63c05a598b3602f8a682fe12d4f7d0e03ee62a04"),
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
