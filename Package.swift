// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DependencyContainer",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(name: "DependencyContainer",
                 targets: ["DependencyContainer"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DependencyContainer",
                dependencies: [])
    ]
)
