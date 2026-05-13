import UIKit

public struct DSPUserDefaultsResetDebugItem: DSPDebugItem {
    public init() {}

    public let debugItemTitle: String = "Reset UserDefaults"

    public let action: DSPDebugItemAction = .execute {
        let appDomain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
        exit(0)
    }
}
