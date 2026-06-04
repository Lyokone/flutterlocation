// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "location",
    platforms: [
        .iOS("11.0"),
        .macOS("10.11")
    ],
    products: [
        .library(name: "location", targets: ["location"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "location",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
			publicHeadersPath: "include/location",
            cSettings: [
				.headerSearchPath("include/location")
			]
        )
    ]
)
