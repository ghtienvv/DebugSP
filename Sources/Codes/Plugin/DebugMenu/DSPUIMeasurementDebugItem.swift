import UIKit

@MainActor
public struct DSPUIMeasurementDebugItem: DSPDebugItem {
    public init(title: String = "UI Measurement") {
        self.title = title
    }

    private let title: String

    public var debugItemTitle: String { title }

    public var action: DSPDebugItemAction {
        .toggle(
            current: {
                DSPUIMeasurement.currentMode == .manual
            },
            operation: { isOn in
                if isOn {
                    DSPUIMeasurement.activate(mode: .manual)
                } else if DSPUIMeasurement.currentMode == .manual {
                    DSPUIMeasurement.deactivate()
                }
                return .success()
            }
        )
    }
}
