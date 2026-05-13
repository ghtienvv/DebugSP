import Foundation

public struct DSPToggleDebugItem: DSPDebugItem {
    public init(title: String, current: @escaping () -> Bool, onChange: @escaping (Bool) -> Void) {
        self.title = title
        self.action = .toggle(
            current: current,
            operation: { (isOn) in
                onChange(isOn)
                return .success()
            }
        )
    }

    let title: String
    public var debugItemTitle: String { title }
    public let action: DSPDebugItemAction
}
