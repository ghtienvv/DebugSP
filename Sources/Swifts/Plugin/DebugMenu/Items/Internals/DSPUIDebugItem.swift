import UIKit
import DebugSPObjC

@MainActor
internal struct DSPUIDebugItem: DSPDebugItem {
    init(title: String = "UI Debug") {
        self.title = title
    }

    let title: String

    var debugItemTitle: String { title }

    var action: DSPDebugItemAction {
        .didSelect { controller in
            controller.dismiss(animated: true) {
                DSPUIDebugManager.shared.showMenu()
            }
            return .success()
        }
    }
}
