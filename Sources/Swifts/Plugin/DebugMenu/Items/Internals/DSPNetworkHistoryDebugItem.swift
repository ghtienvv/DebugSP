import UIKit
import DebugSPObjC

@MainActor
internal struct DSPNetworkHistoryDebugItem: DSPDebugItem {
    public init(title: String = "Network History") {
        self.title = title
    }

    let title: String

    var debugItemTitle: String { title }

    var action: DSPDebugItemAction {
        .didSelect { controller in
            await dspPresentDebugController(from: controller) {
                DSPGlobalsDebugFactory.networkHistoryViewController()
            }
        }
    }
}
