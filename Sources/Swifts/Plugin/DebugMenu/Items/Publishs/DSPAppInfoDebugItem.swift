import Foundation

public struct DSPAppInfoDebugItem: DSPDebugItem {
    public init() {}
    public var debugItemTitle: String = "App Info"

    public var action: DSPDebugItemAction = .didSelect { @MainActor parent in
        let controller = DSPEnvelopePreviewTableVC {
            [
                "App Name": DSPApplication.current.appName,
                "Version": DSPApplication.current.version,
                "Build": DSPApplication.current.build,
                "Bundle ID": DSPApplication.current.bundleIdentifier,
                "App Size": DSPApplication.current.size,
                "Locale": DSPApplication.current.locale,
                "Localization": DSPApplication.current.preferredLocalizations,
                "TestFlight?": DSPApplication.current.isTestFlight ? "YES" : "NO",
            ]
            .map({ DSPEnvelope.init(key: $0.key, value: $0.value) })
            .sorted(by: { $0.key < $1.key })
        }
        await parent.navigationController?.pushViewController(controller, animated: true)
        return .success()
    }

}
