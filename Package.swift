// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Store",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Store",
            targets: ["Store"]
        ),
    ],
    targets: [
        .target(
            name: "Store",
            path: "Store",
            exclude: [
                "StoreApp.swift",
                "Assets.xcassets",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
