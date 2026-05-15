import Foundation

protocol DSPHasDebugItems {
    var debugItems: [DSPAnyGroupDebugItem] { get }
}

public struct DSPGroupDebugItem: DSPDebugItem, DSPHasDebugItems {
    public init(title: String, items: [any DSPDebugItem]) {
        self.debugItemTitle = title
        self.debugItems = items.map(DSPAnyGroupDebugItem.init)
    }

    public var debugItemTitle: String
    public var action: DSPDebugItemAction {
        .didSelect { controller in
            let vc = DSPInAppDebuggerVC(
                title: self.debugItemTitle,
                debuggerItems: self.debugItems,
                options: [],
                showsDefaultSection: false
            )
            controller.navigationController?.pushViewController(vc, animated: true)
            return .success()
        }
    }
    let debugItems: [DSPAnyGroupDebugItem]
}

struct DSPAnyGroupDebugItem: @preconcurrency Hashable, Identifiable, DSPDebugItem,
    DSPHasDebugItems, DSPDebugItemPresentation
{
    let id: String
    let debugItemTitle: String
    let action: DSPDebugItemAction
    let debugItems: [DSPAnyGroupDebugItem]
    let debugItemSectionTitle: String?
    let debugItemSystemImageName: String?

    init(_ item: any DSPDebugItem) {
        let presentation = item as? any DSPDebugItemPresentation
        id = UUID().uuidString
        debugItemTitle = item.debugItemTitle
        action = item.action
        debugItemSectionTitle = presentation?.debugItemSectionTitle
        debugItemSystemImageName = presentation?.debugItemSystemImageName
        if let grouped = item as? (any DSPHasDebugItems) {
            debugItems = grouped.debugItems.map(DSPAnyGroupDebugItem.init)
        } else {
            debugItems = []
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DSPAnyGroupDebugItem, rhs: DSPAnyGroupDebugItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension Array where Element == DSPAnyGroupDebugItem {
    func flatten() -> [DSPAnyGroupDebugItem] {
        var result: [DSPAnyGroupDebugItem] = []
        for element in self {
            if element.debugItems.isEmpty {
                result.append(element)
            } else {
                result.append(element)
                result.append(contentsOf: element.debugItems.flatten())
            }
        }
        return result
    }
}
