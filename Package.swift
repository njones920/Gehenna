// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GehennaEngine",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "GehennaEngine",
            targets: ["GehennaEngine"]),
        .executable(
            name: "gehenna",
            targets: ["GehennaCLI"]),
    ],
    targets: [
        .target(
            name: "GehennaEngine"),
        .executableTarget(
            name: "GehennaCLI",
            dependencies: ["GehennaEngine"]),
        .testTarget(
            name: "GehennaEngineTests",
            dependencies: ["GehennaEngine"]),
    ]
)
