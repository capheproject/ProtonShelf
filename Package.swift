// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ProtonShelf",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "ProtonShelf", path: "Sources/ProtonShelf", swiftSettings: [.swiftLanguageMode(.v5)])
    ]
)
