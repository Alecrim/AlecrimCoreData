// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "AlecrimCoreData",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .watchOS(.v3),
        .tvOS(.v10)
    ],
    products: [
        .library(name: "AlecrimCoreData", targets: ["AlecrimCoreData"])
    ],
    targets: [
        .target(name: "AlecrimCoreData", path: "Sources")
    ]
)
