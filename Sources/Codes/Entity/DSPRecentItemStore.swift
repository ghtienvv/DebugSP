import Foundation

struct DSPRecentItemStore {
    let key: String = "dev.debugSP.recent-item-names"
    let items: [DSPAnyDebugItem]
    let maxCount: Int = 3

    @MainActor
    func get() -> [DSPAnyDebugItem] {
        let titles = UserDefaults.standard.stringArray(forKey: key)?.prefix(maxCount) ?? []
        return titles.compactMap({ title in items.first(where: { $0.debugItemTitle == title }) })
            .map(DSPAnyDebugItem.init)
    }

    func insert(_ item: DSPAnyDebugItem) {
        var titles = UserDefaults.standard.stringArray(forKey: key) ?? []
        titles.removeAll(where: { $0 == item.debugItemTitle })
        titles.insert(item.debugItemTitle, at: 0)
        UserDefaults.standard.set(titles.prefix(maxCount).map({ $0 }), forKey: key)
    }
}
