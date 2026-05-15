import Foundation

@MainActor
internal struct DSPWidgetVisibilityDebugItem: DSPDebugItem {
    public init(title: String = "Memory Widget") {
        self.title = title
    }

    private let title: String

    var debugItemTitle: String { title }

    var action: DSPDebugItemAction {
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
