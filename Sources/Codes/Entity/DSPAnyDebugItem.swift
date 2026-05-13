import Foundation

struct DSPAnyDebugItem: @preconcurrency Hashable, Identifiable, DSPDebugItem, @unchecked Sendable {
    let id: String
    let debugItemTitle: String
    let action: DSPDebugItemAction

    init(_ item: any DSPDebugItem) {
        id = UUID().uuidString
        debugItemTitle = item.debugItemTitle
        action = item.action
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DSPAnyDebugItem, rhs: DSPAnyDebugItem) -> Bool {
        lhs.id == rhs.id
    }
}
