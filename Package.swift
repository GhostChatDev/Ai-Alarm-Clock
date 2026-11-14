// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadyByEightLogic",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(name: "ReadyByEightLogic", targets: ["ReadyByEightLogic"])
    ],
    targets: [
        .target(
            name: "ReadyByEightLogic",
            path: "ReadyByEight",
            sources: ["AlarmModels.swift"]
        ),
        .testTarget(
            name: "ReadyByEightLogicTests",
            dependencies: ["ReadyByEightLogic"],
            path: "Tests",
            sources: ["LogicTests.swift"]
        )
    ]
)
