// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Formatter",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.58.0")
    ],
    targets: [.target(name: "Formatter", path: "")]
)
