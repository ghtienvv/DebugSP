import UIKit

public struct DSPCaseSelectableDebugItem<T: CaseIterable & RawRepresentable>: DSPDebugItem
where T.RawValue: Equatable {

    public init(currentValue: T, didSelected: @escaping (T) -> Void) {
        self.action = .didSelect { controller in
            let vc = DSPCaseSelectableTableController<T>(
                currentValue: currentValue,
                didSelected: didSelected
            )
            controller.navigationController?.pushViewController(vc, animated: true)
            return .success()
        }
    }
    public var debugItemTitle: String { String(describing: T.self) }
    public let action: DSPDebugItemAction
}
