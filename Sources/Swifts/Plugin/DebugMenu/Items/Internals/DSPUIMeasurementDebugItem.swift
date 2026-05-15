import UIKit

@MainActor
internal struct DSPUIMeasurementDebugItem: DSPDebugItem {
    public init(title: String = "UI Measurement") {
        self.title = title
    }

    private let title: String

    var debugItemTitle: String { title }

    var action: DSPDebugItemAction {
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
