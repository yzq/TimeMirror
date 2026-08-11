// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimeMirrorCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TimeMirrorCore", targets: ["TimeMirrorCore"])
    ],
    targets: [
        .target(name: "TimeMirrorCore"),
        .testTarget(name: "TimeMirrorCoreTests", dependencies: ["TimeMirrorCore"])
    ]
)
