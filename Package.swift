// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Analytics",
            targets: ["Analytics"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "12.14.0"
        )
    ],
    targets: [
        .target(
            name: "Analytics",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["Analytics"]
        )
    ]
)
