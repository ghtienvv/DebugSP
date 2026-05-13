import Foundation

public struct DSPExitDebugItem: DSPDebugItem {
    public init() {
        self.action = .didSelect(operation: { _ in
            exit(0)
        })
    }

    public var debugItemTitle: String { "exit" }
    public let action: DSPDebugItemAction
}
