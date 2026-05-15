import UIKit

@MainActor
func dspPresentDebugController(
    from controller: UIViewController,
    builder: () -> UIViewController
) async -> DSPDebugSPResult {
    let presenter = controller.navigationController ?? controller
    let viewController = builder()
    viewController.modalPresentationStyle = .pageSheet

    if #available(iOS 15, *) {
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        viewController.sheetPresentationController?.selectedDetentIdentifier = .medium
        viewController.sheetPresentationController?.prefersGrabberVisible = true
    }

    presenter.present(viewController, animated: true)

    return .success()
}