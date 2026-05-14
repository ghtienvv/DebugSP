import Foundation

@MainActor
public struct DSPWidgetVisibilityDebugItem: DSPDebugItem {
    public init(title: String = "Show Widget") {
        self.title = title
    }

    private let title: String

    public var debugItemTitle: String { title }

    public var action: DSPDebugItemAction {
        .toggle(
            current: {
                DSPInAppDebuggerWindow.isWidgetVisible
            },
            operation: { isOn in
                DSPInAppDebuggerWindow.setWidgetVisible(isOn)
                return .success()
            }
        )
    }
}
