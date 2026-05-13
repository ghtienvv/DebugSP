import SwiftUI

@available(iOSApplicationExtension, unavailable)
public struct DebugSP: @unchecked Sendable {

    @MainActor
    public static func install(
        windowScene: UIWindowScene? = nil,
        items: [any DSPDebugItem] = [],
        dashboardItems: [any DSPDashboardItem] = [],
        options: [DSPOptions] = DSPOptions.default) {
        DSPInAppDebuggerWindow.install(
            windowScene: windowScene,
            debuggerItems: items,
            dashboardItems: dashboardItems,
            options: options,
        )
    }
}
