# DebugSP

DebugSP is an in-app debugging toolkit for iOS applications.

It combines a Swift-first integration layer with an Objective-C runtime inspection engine to help you inspect UI, explore object graphs, review app state, monitor network activity, and surface lightweight diagnostics directly inside a running app.

![DebugSP Demo](YOUR_GIF_LINK_HERE)

> Replace `YOUR_GIF_LINK_HERE` with the final demo GIF URL.

## Table of Contents

- [Overview](#overview)
- [Why DebugSP](#why-debugsp)
- [Technology](#technology)
- [Installation](#installation)
- [Usage](#usage)
- [Built-in Features](#built-in-features)
- [Feature Deep Dives](#feature-deep-dives)
- [Customization](#customization)
- [How to Open DebugSP](#how-to-open-debugsp)
- [License](#license)

## Overview

DebugSP is designed for teams that want faster feedback while debugging UIKit and SwiftUI applications on real devices or simulators.

Instead of switching constantly between Xcode tools, logs, view debugger, network proxies, and ad-hoc debug screens, DebugSP brings the most useful runtime inspection tools into the app itself:

- a floating launcher
- an in-app debug menu
- a configurable dashboard / memory widget
- runtime UI inspection tools
- network history
- keychain and crash-log access
- app and device diagnostics

## Why DebugSP

DebugSP is useful when you need to:

- inspect UI structure without leaving the app
- validate spacing, alignment, and layout issues visually
- understand which view controller / object is active at runtime
- inspect current app, device, and environment information
- browse recorded network activity during testing
- review local keychain and crash-log related data
- expose custom debug actions for QA, developers, or internal builds

It is especially helpful for:

- feature QA builds
- internal staging builds
- UI debugging on real devices
- investigating production-like states in non-production environments

## Technology

DebugSP is built as a hybrid runtime toolkit.

| Area | What it uses | Why it matters |
| --- | --- | --- |
| Public integration | Swift + SwiftUI modifiers + UIKit entry points | Easy adoption in both UIKit and SwiftUI apps |
| Runtime inspection | Objective-C runtime / reflection | Lets DebugSP inspect object graphs, metadata, and live UI structures |
| UI debugging | Overlay windows + in-app navigation | Tools stay available while the app is running |
| View exploration | Hierarchy tree + snapshot visualization | Lets you analyze structure and rendering from different angles |
| Network tooling | Runtime interception / observer pipeline | Captures request history directly inside the app |
| Packaging | Swift Package Manager | Simple dependency management for app teams |

## Installation

### Swift Package Manager

Add this repository to your project using Swift Package Manager.

In Xcode:

`File > Add Package Dependencies...`

Then add the repository URL for this project.

## Usage

### UIKit

```swift
#if DEBUG
DebugSP.install(
	windowScene: windowScene,
	items: [
		DSPGroupDebugItem(title: "Info", items: [
			DSPAppInfoDebugItem(),
			DSPDeviceInfoDebugItem(),
		]),
		DSPClearCacheDebugItem(),
		DSPUserDefaultsResetDebugItem(),
	],
	dashboardItems: [
		DSPCPUUsageDashboardItem(),
		DSPMemoryUsageDashboardItem(),
		DSPNetworkUsageDashboardItem(),
		DSPFPSDashboardItem(),
	]
)
#endif
```

### SwiftUI

```swift
import SwiftUI
import DebugSP

struct HomeView: View {
	var body: some View {
		ContentView()
			.debugSP(
				debuggerItems: [
					DSPGroupDebugItem(title: "Info", items: [
						DSPAppInfoDebugItem(),
						DSPDeviceInfoDebugItem(),
					]),
					DSPClearCacheDebugItem(),
				],
				dashboardItems: [
					DSPCPUUsageDashboardItem(),
					DSPCPUGraphDashboardItem(),
					DSPGPUMemoryUsageDashboardItem(),
					DSPMemoryUsageDashboardItem(),
					DSPNetworkUsageDashboardItem(),
					DSPFPSDashboardItem(),
					DSPThermalStateDashboardItem(),
				],
				options: [
					.debugSP(.init()),
					.widget(.init())
				]
			)
	}
}
```

## Built-in Features

### Snapshot

Snapshot tools help you understand how a screen is rendered at a specific moment.

From a technology point of view, this feature captures the current view tree and transforms it into a visual representation that can be explored separately from the live screen. This is useful when the UI is dense, layered, animated, or difficult to reason about from code alone.

Use Snapshot when you want to:

- inspect rendered layers and nested views
- understand overlapping UI
- reason about spacing and composition visually
- debug complex container layouts

Read more: [Snapshot Deep Dive](docs/snapshot.md)

### Hierarchy

Hierarchy view focuses on structural understanding.

Instead of looking at the screen as pixels, it shows the parent-child relationships between views, helping you trace where a view lives, how deep it is nested, and which component owns it.

Use Hierarchy when you want to:

- inspect the current `UIView` tree
- identify the selected view and its ancestors
- debug container composition
- understand why a view is clipped, misplaced, or unexpectedly nested

Read more: [Hierarchy Deep Dive](docs/hierarchy.md)

### UI Debug

UI Debug is the runtime inspection entry point for working directly with live views.

It lets you select elements on screen, inspect them, and move into more advanced visualization flows such as hierarchy exploration. This is useful when debugging touch targets, overlays, hidden views, and layout mismatches.

### UI Measurement

UI Measurement is focused on spacing and size validation.

It provides an overlay-based measurement workflow so you can compare edges, distances, and dimensions directly inside the running app. This is especially useful for design QA, layout review, and pixel-accurate verification on device.

### Object Explorer

The object explorer is powered by runtime reflection and metadata inspection.

It helps you inspect properties, ivars, methods, sections, and related runtime information for the currently selected object. This is useful when you need to understand what a live object contains without pausing execution and drilling manually through LLDB.

### App Info

App Info exposes runtime information about the current application build.

Typical use cases include checking:

- app name
- version and build number
- bundle metadata
- file-system related app information

This is useful for QA, release verification, and internal test builds.

### Device Info

Device Info surfaces runtime information about the current device and environment.

Depending on the data source, this can include hardware and process-oriented values such as memory, CPU-related context, power mode, thermal state, and other device characteristics that help explain performance or layout behavior.

### Network History

Network History records in-app network activity so you can review requests and responses without switching to an external proxy tool.

This is useful for:

- validating API payloads
- checking headers and response bodies
- reviewing request timing and status
- debugging integration issues in QA and staging environments

### Keychain

The Keychain explorer helps inspect keychain items stored by the app.

This is useful when debugging:

- authentication state
- token persistence
- secure storage migrations
- environment-specific credential issues

### Crash Log

Crash Log tooling helps surface locally relevant crash-related data flows directly from the app environment.

This is useful when you want a faster internal path to inspect crash artifacts during testing, especially in builds where developers and QA need a shared diagnostic surface.

### Dashboard and Memory Widget

DebugSP can show a lightweight runtime dashboard / widget with live metrics.

Typical metrics include:

- CPU usage
- memory usage
- GPU memory usage
- FPS
- thermal state
- network usage
- custom interval tracking

This makes it easier to observe performance trends without opening external tools.

## Feature Deep Dives

- [Hierarchy](docs/hierarchy.md)
- [Snapshot](docs/snapshot.md)

## Customization

DebugSP supports custom debug items and custom dashboard items.

### Custom debug item

```swift
struct CustomDebugItem: DSPDebugItem {
	let debugItemTitle: String = "Custom item"

	var action: DSPDebugItemAction {
		.didSelect { _ in
			.success(message: "Done")
		}
	}
}
```

### Grouped debug item

```swift
let infoGroup = DSPGroupDebugItem(title: "Info", items: [
	DSPAppInfoDebugItem(),
	DSPDeviceInfoDebugItem(),
])
```

### Custom dashboard item

```swift
public final class CustomDashboardItem: DSPDashboardItem {
	public init() {}

	public func startMonitoring() {}
	public func stopMonitoring() {}

	public let fetcher: DSPMetricsFetcher = .text {
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm:ss"
		return formatter.string(from: Date())
	}

	public var title: String = "Date"
}
```

## How to Open DebugSP

### Open Debug Menu

Tap the floating bug button.

### Show Dashboard / Widget

Long press the floating bug button to access widget-related actions.

## License

DebugSP is released under the MIT License.

- Markdown version: [LICENSE.md](LICENSE.md)
- GitHub license tab source: [LICENSE](LICENSE)