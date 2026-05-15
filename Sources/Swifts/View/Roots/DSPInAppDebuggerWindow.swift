import Combine
import SwiftUI

protocol DSPTouchThrowing {}

@available(iOSApplicationExtension, unavailable)
public class DSPInAppDebuggerWindow: UIWindow {
    internal static var windows: [DSPInAppDebuggerWindow] = []

    internal static var isWidgetVisible: Bool {
        activeController?.isWidgetVisible ?? false
    }

    internal static func setWidgetVisible(_ isVisible: Bool) {
        activeController?.setWidgetVisible(isVisible)
    }

    internal static func install(
        windowScene: UIWindowScene? = nil,
        debuggerItems: [any DSPDebugItem],
        dashboardItems: [any DSPDashboardItem],
        options: [DSPOptions]) {
        if let window = existingWindow(windowScene: windowScene) {
            window.apply(
                debuggerItems: debuggerItems,
                dashboardItems: dashboardItems,
                options: options
            )
            return
        }

        let window = windowScene.map(DSPInAppDebuggerWindow.init(windowScene:))
            ?? DSPInAppDebuggerWindow(frame: UIScreen.main.bounds)
        window.apply(
            debuggerItems: debuggerItems,
            dashboardItems: dashboardItems,
            options: options
        )

        window.frame.size.width += 1
        window.isHidden = false
        window.frame.size.width -= 1
        windows.append(window)
    }

    internal override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }

    internal override init(frame: CGRect) {
        super.init(frame: frame)
    }

    private static func existingWindow(
        windowScene: UIWindowScene?
    ) -> DSPInAppDebuggerWindow? {
        if let windowScene {
            return windows.first(where: { $0.windowScene == windowScene })
        }

        return windows.first
    }

    private static var activeController: DSPFloatingVC? {
        windows
            .first(where: { !$0.isHidden })?
            .rootViewController as? DSPFloatingVC
            ?? windows.first?.rootViewController as? DSPFloatingVC
    }

    private func apply(
        debuggerItems: [any DSPDebugItem],
        dashboardItems: [any DSPDashboardItem],
        options: [DSPOptions]
    ) {
        windowLevel = UIWindow.Level.statusBar + 1

        if let controller = rootViewController as? DSPFloatingVC {
            controller.updateConfiguration(
                debuggerItems: debuggerItems,
                dashboardItems: dashboardItems,
                options: options
            )
        } else {
            rootViewController = DSPFloatingVC(
                debuggerItems: debuggerItems,
                dashboardItems: dashboardItems,
                options: options
            )
        }

        if isHidden {
            isHidden = false
        }
    }

    internal required init?(coder: NSCoder) { fatalError() }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view is (any DSPTouchThrowing) {
            return nil
        } else {
            return view
        }
    }
}
