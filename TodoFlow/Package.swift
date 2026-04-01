// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TodoFlow",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TodoFlow",
            path: "Sources/TodoFlow"
        )
    ]
)
