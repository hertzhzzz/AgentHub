// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AgentHub",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AgentHub", targets: ["AgentHub"])
    ],
    targets: [
        .executableTarget(
            name: "AgentHub",
            path: "Sources/AgentHub",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AgentHubTests",
            dependencies: ["AgentHub"],
            path: "Tests/AgentHubTests"
        ),
    ]
)
