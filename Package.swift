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
        .executable(
            name: "gehenna-arena",
            targets: ["GehennaArena"]),
    ],
    targets: [
        .target(
            name: "GehennaEngine",
            resources: [
                .process("Content/Data")
            ]),
        .executableTarget(
            name: "GehennaCLI",
            dependencies: ["GehennaEngine"]),
        .executableTarget(
            name: "GehennaArena",
            dependencies: ["GehennaEngine"]),
        .testTarget(
            name: "GehennaEngineTests",
            dependencies: ["GehennaEngine"]),
    ]
)
