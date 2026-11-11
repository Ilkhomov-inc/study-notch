// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StudyNook",
    platforms: [.macOS(.v15)],
    targets: [
        // Timer logic without UI, so it can be tested on its own.
        .target(
            name: "StudyNookCore",
            path: "Sources/StudyNookCore"
        ),
        // The app itself: notch panel, SwiftUI views, Canvas scenes.
        .executableTarget(
            name: "StudyNook",
            dependencies: ["StudyNookCore"],
            path: "Sources/StudyNook"
        ),
        .testTarget(
            name: "StudyNookTests",
            dependencies: ["StudyNookCore"],
            path: "Tests/StudyNookTests"
        ),
    ]
)
