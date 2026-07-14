// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
    name: "location",
    platforms: [
        .iOS("12.0"),
        .macOS("10.15"),
    ],
    products: [
        .library(name: "location", targets: ["location"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "location",
            dependencies: []
        ),
    ]
)
