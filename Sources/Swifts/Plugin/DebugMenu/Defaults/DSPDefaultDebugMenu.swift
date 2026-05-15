import Foundation
import UIKit

@MainActor
enum DSPDefaultDebugMenu {
    static let sectionTitle = "Default"

    static func visibleItems() -> [any DSPDebugItem] {
        DSPDefaultDebugTool.allCases.compactMap { tool in
            guard DSPDefaultDebugToolStore.isVisible(tool) else { return nil }
            return DSPDefaultMenuItem(tool.makeDebugItem())
        }
    }
}

@MainActor
enum DSPDefaultDebugTool: String, CaseIterable {
    case uiMeasurement
    case uiDebug
    case keyChain
    case crashLog
    case networkHistory
    case memoryWidget

    var title: String {
        switch self {
        case .uiMeasurement:
            return "UI Measurement"
        case .uiDebug:
            return "UI Debug"
        case .keyChain:
            return "KeyChain"
        case .crashLog:
            return "Crash Log"
        case .networkHistory:
            return "Network History"
        case .memoryWidget:
            return "Memory Widget"
        }
    }

    func makeDebugItem() -> any DSPDebugItem {
        switch self {
        case .uiMeasurement:
            return DSPDefaultSelectableDebugItem(title: title) { controller in
                controller.dismiss(animated: true) {
                    DSPUIMeasurement.activate(mode: .manual)
                }
                return DSPDebugSPResult.success()
            }
        case .uiDebug:
            return DSPUIDebugItem()
        case .keyChain:
            return DSPKeyChainDebugItem()
        case .crashLog:
            return DSPCrashLogDebugItem()
        case .networkHistory:
            return DSPNetworkHistoryDebugItem()
        case .memoryWidget:
            return DSPWidgetVisibilityDebugItem()
        }
    }
}

@MainActor
private struct DSPDefaultMenuItem: DSPDebugItem, DSPDebugItemPresentation {
    private let wrappedItem: any DSPDebugItem

    init(_ wrappedItem: any DSPDebugItem) {
        self.wrappedItem = wrappedItem
    }

    var debugItemTitle: String {
        wrappedItem.debugItemTitle
    }

    var action: DSPDebugItemAction {
        wrappedItem.action
    }

    var debugItemSectionTitle: String? {
        DSPDefaultDebugMenu.sectionTitle
    }

    var debugItemSystemImageName: String? {
        nil
    }
}

@MainActor
private struct DSPDefaultActionDebugItem: DSPDebugItem {
    let title: String
    let execute: () async -> DSPDebugSPResult

    var debugItemTitle: String {
        title
    }

    var action: DSPDebugItemAction {
        .execute(execute)
    }
}

@MainActor
private struct DSPDefaultSelectableDebugItem: DSPDebugItem {
    let title: String
    let execute: (_ controller: UIViewController) async -> DSPDebugSPResult

    var debugItemTitle: String {
        title
    }

    var action: DSPDebugItemAction {
        .didSelect { controller in
            await execute(controller)
        }
    }
}
