import UIKit
import DebugSPObjC

@MainActor
internal struct DSPCrashLogDebugItem: DSPDebugItem {
    public init(title: String = "Crash Log") {
        self.title = title
    }

    let title: String

    var debugItemTitle: String { title }

    var action: DSPDebugItemAction {
        .didSelect { controller in
            await dspPresentDebugController(from: controller) {
                DSPGlobalsDebugFactory.crashLogViewController()
            }
        }
    }
}
