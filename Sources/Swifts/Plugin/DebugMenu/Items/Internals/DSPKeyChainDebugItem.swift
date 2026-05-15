import UIKit
import DebugSPObjC

@MainActor
internal struct DSPKeyChainDebugItem: DSPDebugItem {
    public init(title: String = "KeyChain") {
        self.title = title
    }

    let title: String

    var debugItemTitle: String { title }

    var action: DSPDebugItemAction {
        .didSelect { controller in
            await dspPresentDebugController(from: controller) {
                DSPGlobalsDebugFactory.keychainViewController()
            }
        }
    }
}
