// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "schwifty-resources",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SchwiftyResources",
            targets: ["SchwiftyResources"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SchwiftyResources",
            dependencies: [],
            path: "Sources/SchwiftyResources"
        ),
        .testTarget(
            name: "SchwiftyResourcesTests",
            dependencies: ["SchwiftyResources"]
        ),
    ]
)
