// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BadgeThing",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BadgeThing",
            path: "Sources/BadgeThing"
        )
    ]
)
