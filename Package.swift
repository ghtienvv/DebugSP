// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DebugSP",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "DebugSP",
            targets: ["DebugSP"]
        )
    ],
    targets: [
        .target(
            name: "DebugSP",
            dependencies: [
            ],
            path: "Sources/Codes"
        ),
        .testTarget(
            name: "DebugSPTests",
            dependencies: ["DebugSP"])
    ]
)

package.targets.forEach {
    $0.swiftSettings = [
        .existentialAny,
        .define("RELEASE", .when(configuration: .release))
      ]
}

extension SwiftSetting {
  static let existentialAny: Self = .enableUpcomingFeature("ExistentialAny")
}
