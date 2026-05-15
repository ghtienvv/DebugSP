import UIKit

@MainActor
public protocol DSPDebugItem {
    var debugItemTitle: String { get }
    var action: DSPDebugItemAction { get }
}

@MainActor
public protocol DSPDebugItemPresentation {
    var debugItemSectionTitle: String? { get }
    var debugItemSystemImageName: String? { get }
}

public extension DSPDebugItemPresentation {
    var debugItemSectionTitle: String? { nil }
    var debugItemSystemImageName: String? { nil }
}

public enum DSPDebugItemAction {
    case didSelect(
        operation: (_ controller: UIViewController) async -> DSPDebugSPResult
    )
    case execute(_ operation: () async -> DSPDebugSPResult)
    case toggle(
        current: () -> Bool,
        operation: (_ isOn: Bool) async -> DSPDebugSPResult
    )
    case slider(
        current: () -> Double,
        valueLabelText: (Double) -> String,
        range: ClosedRange<Double>,
        operation: (_ value: Double) async -> DSPDebugSPResult
    )
}
