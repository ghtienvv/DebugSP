import Foundation

struct DSPAnyDebugItem: @preconcurrency Hashable, Identifiable, DSPDebugItem, @unchecked Sendable {
    let id: String
    let debugItemTitle: String
    let action: DSPDebugItemAction
    let debugItemSectionTitle: String?
    let debugItemSystemImageName: String?

    init(_ item: any DSPDebugItem) {
        let presentation = item as? any DSPDebugItemPresentation
        id = UUID().uuidString
        debugItemTitle = item.debugItemTitle
        action = item.action
        debugItemSectionTitle = presentation?.debugItemSectionTitle
        debugItemSystemImageName = presentation?.debugItemSystemImageName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DSPAnyDebugItem, rhs: DSPAnyDebugItem) -> Bool {
        lhs.id == rhs.id
    }
}
