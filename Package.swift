// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AreYouSleeping",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AreYouSleeping", targets: ["AreYouSleeping"]),
    ],
    targets: [
        .target(
            name: "AreYouSleeping",
            path: "AreYouSleeping",
            resources: [.process("Info.plist")]
        ),
    ]
)
