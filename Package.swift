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
                "DebugSPObjC",
            ],
            path: "Sources/Swifts"
        ),
        .target(
            name: "DebugSPObjC",
            dependencies: [],
            path: "Sources/ObjC/UIDebugs",
            publicHeadersPath: "Root",
            cSettings: [
                .headerSearchPath("Dependencies/DSP"),
                .headerSearchPath("Dependencies/DSP/Core"),
                .headerSearchPath("Dependencies/DSP/Core/Controllers"),
                .headerSearchPath("Dependencies/DSP/Core/Views"),
                .headerSearchPath("Dependencies/DSP/Core/Views/Cells"),
                .headerSearchPath("Dependencies/DSP/Core/Views/Carousel"),
                .headerSearchPath("Dependencies/DSP/Editing"),
                .headerSearchPath("Dependencies/DSP/Editing/ArgumentInputViews"),
                .headerSearchPath("Dependencies/DSP/Interfaces"),
                .headerSearchPath("Dependencies/DSP/Interfaces/Tabs"),
                .headerSearchPath("Dependencies/DSP/Interfaces/Bookmarks"),
                .headerSearchPath("Dependencies/DSP/States"),
                .headerSearchPath("Dependencies/DSP/States/DatabaseBrowser"),
                .headerSearchPath("Dependencies/DSP/States/Globals"),
                .headerSearchPath("Dependencies/DSP/States/FileBrowser"),
                .headerSearchPath("Dependencies/DSP/States/Keychain"),
                .headerSearchPath("Dependencies/DSP/States/RuntimeBrowser"),
                .headerSearchPath("Dependencies/DSP/States/RuntimeBrowser/DataSources"),
                .headerSearchPath("Dependencies/DSP/States/SystemLog"),
                .headerSearchPath("Dependencies/DSP/Manager"),
                .headerSearchPath("Dependencies/DSP/Manager/Private"),
                .headerSearchPath("Dependencies/DSP/Network"),
                .headerSearchPath("Dependencies/DSP/Network/OSCache"),
                .headerSearchPath("Dependencies/DSP/Network/PonyDebugger"),
                .headerSearchPath("Dependencies/DSP/Entities"),
                .headerSearchPath("Dependencies/DSP/Entities/Sections"),
                .headerSearchPath("Dependencies/DSP/Entities/Sections/Shortcuts"),
                .headerSearchPath("Dependencies/DSP/Toolbar"),
                .headerSearchPath("Dependencies/DSP/Utility"),
                .headerSearchPath("Dependencies/DSP/Utility/Categories"),
                .headerSearchPath("Dependencies/DSP/Utility/Categories/Private"),
                .headerSearchPath("Dependencies/DSP/Utility/Keyboard"),
                .headerSearchPath("Dependencies/DSP/Utility/Runtime"),
                .headerSearchPath("Dependencies/DSP/Utility/Runtime/Objc"),
                .headerSearchPath("Dependencies/DSP/Utility/Runtime/Objc/Reflection"),
                .headerSearchPath("Dependencies/DSP/ViewHierarchy"),
                .headerSearchPath("Dependencies/DSP/ViewHierarchy/TreeExplorer"),
                .headerSearchPath("Dependencies/DSP/ViewHierarchy/SnapshotExplorer"),
                .headerSearchPath("Dependencies/DSP/ViewHierarchy/SnapshotExplorer/Scene"),
            ],
            linkerSettings: [
                .linkedFramework("SceneKit"),
                .linkedFramework("Security")
            ]
        ),
        .testTarget(
            name: "DebugSPTests",
            dependencies: ["DebugSP"])
    ],
    cxxLanguageStandard: .cxx17
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
