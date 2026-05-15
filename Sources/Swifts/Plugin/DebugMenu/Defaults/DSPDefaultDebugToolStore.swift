import Foundation

enum DSPDefaultDebugToolStore {
    private static let key = "dev.debugSP.default-debug-tools"
    private static let defaultVisibleTools: [DSPDefaultDebugTool] = [.uiMeasurement]

    static func isVisible(_ tool: DSPDefaultDebugTool) -> Bool {
        visibleTools().contains(tool)
    }

    static func setVisible(_ isVisible: Bool, for tool: DSPDefaultDebugTool) {
        var tools = visibleTools()
        if isVisible {
            tools.insert(tool)
        } else {
            tools.remove(tool)
        }

        let orderedTools = DSPDefaultDebugTool.allCases.filter { tools.contains($0) }
        UserDefaults.standard.set(orderedTools.map(\.rawValue), forKey: key)
    }

    static func visibleTools() -> Set<DSPDefaultDebugTool> {
        let storedValues = UserDefaults.standard.stringArray(forKey: key)
        let rawValues = storedValues ?? defaultVisibleTools.map(\.rawValue)
        return Set(rawValues.compactMap(DSPDefaultDebugTool.init(rawValue:)))
    }
}