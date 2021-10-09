// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AndroidNDK",
    products: [
        .library(name: "AndroidNDK", targets: ["AndroidNDK", "CAndroidNDK"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "CAndroidNDK", linkerSettings: [.linkedLibrary("android"), .linkedLibrary("log")]),
        .target(name: "AndroidNDK", dependencies: ["CAndroidNDK"]),
        .testTarget(name: "AndroidNDKTests", dependencies: ["AndroidNDK"]),
    ]
)
