import Combine
import SwiftUI

internal class DSPFloatingVC: UIViewController {
    class View: UIView, DSPTouchThrowing {}
    private let launchView: DSPLaunchView
    private let widgetView: DSPWidgetView
    private var debuggerItems: [any DSPDebugItem]
    private var dashboardItems: [any DSPDashboardItem]
    private var cancellables: Set<AnyCancellable> = []
    private var options: [DSPOptions]
    private var widgetConfiguration: DSPOptions.Widget?

    init(
        debuggerItems: [any DSPDebugItem],
        dashboardItems: [any DSPDashboardItem],
        options: [DSPOptions]
    ) {
        self.debuggerItems = debuggerItems
        self.dashboardItems = dashboardItems
        self.options = options
        self.widgetConfiguration = options.widgetConfiguration
        self.widgetView = .init(
            dashboardItems: dashboardItems,
            configuration: options.widgetConfiguration
        )

        launchView = .init(
            image: options.launchIconConfiguration?.image
        )

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        view = View(frame: .null)

        view.addSubview(launchView)
        view.addSubview(widgetView)

        launchView.isHidden = true
        widgetView.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        widgetView.onRequestClose = { [weak self] in
            self?.setWidgetVisible(false)
        }

        bug: do {
            let gesture = DSPFloatingItemGestureRecognizer(groundView: self.view)
            launchView.addGestureRecognizer(gesture)

            let initialPosition =
                options.launchIconConfiguration?.initialPosition ?? .bottomTrailing

            gesture.moveInitialPosition(initialPosition)

            let longPress = UILongPressGestureRecognizer()
            longPress.publisher(for: \.state).filter({ $0 == .began })
                .sink { [weak self] _ in
                    self?.presentMenu()
                }
                .store(in: &cancellables)
            launchView.addGestureRecognizer(longPress)

            launchView.addAction(
                .init(handler: { [weak self] _ in
                    guard let self = self else { return }
                    let vc = DSPInAppDebuggerVC(
                        debuggerItems: self.debuggerItems,
                        options: self.options
                    )
                    let nc = UINavigationController(rootViewController: vc)
                    nc.modalPresentationStyle = .fullScreen
                    if #available(iOS 15, *) {
                        nc.modalPresentationStyle = .pageSheet
                        nc.sheetPresentationController?.selectedDetentIdentifier = .medium
                        nc.sheetPresentationController?.detents = [.medium(), .large()]
                        nc.popoverPresentationController?.sourceView = self.launchView
                        self.present(nc, animated: true, completion: nil)
                    } else {
                        let ac = DSPCustomActivityVC(controller: nc)
                        ac.popoverPresentationController?.sourceView = self.launchView
                        self.present(ac, animated: true, completion: nil)
                    }
                })
            )
        }

        widget: do {
            let gesture = DSPFloatingItemGestureRecognizer(groundView: self.view)
            gesture.shouldReceiveTouch = { touch, targetView in
                guard let widgetView = targetView as? DSPWidgetView else { return true }
                return widgetView.shouldBeginDragging(with: touch)
            }
            widgetView.addGestureRecognizer(gesture)
            gesture.moveInitialPosition(.topLeading)
        }

        applyWidgetVisibility(isInitial: true)
        launchView.isHidden = false
    }

    func updateConfiguration(
        debuggerItems: [any DSPDebugItem],
        dashboardItems: [any DSPDashboardItem],
        options: [DSPOptions]
    ) {
        self.debuggerItems = debuggerItems
        self.dashboardItems = dashboardItems
        self.options = options
        self.widgetConfiguration = options.widgetConfiguration

        launchView.updateImage(options.launchIconConfiguration?.image)
        widgetView.update(dashboardItems: dashboardItems, configuration: widgetConfiguration)
        applyWidgetVisibility(isInitial: false)
    }

    var isWidgetVisible: Bool {
        !widgetView.isHidden
    }

    func setWidgetVisible(_ isVisible: Bool) {
        if isVisible {
            widgetView.show()
        } else {
            widgetView.hide()
        }
    }

    private func applyWidgetVisibility(isInitial: Bool) {
        guard let widgetConfiguration, widgetConfiguration.isEnabled else {
            setWidgetVisible(false)
            return
        }

        if let isVisible = widgetConfiguration.isVisible {
            setWidgetVisible(isVisible)
            return
        }

        guard isInitial else {
            return
        }

        setWidgetVisible(widgetConfiguration.showsOnLaunch)
    }

    private func presentMenu() {
        let sheet = UIAlertController(title: "Debug", message: nil, preferredStyle: .alert)
        sheet.addAction(
            .init(
                title: .hideUntilNextLaunch,
                style: .destructive,
                handler: { [weak self] _ in
                    self?.launchView.isHidden = true
                    self?.setWidgetVisible(false)
                }
            )
        )
        guard widgetConfiguration?.isEnabled == true else {
            sheet.addAction(.init(title: .cancel, style: .cancel, handler: nil))
            present(sheet, animated: true, completion: nil)
            return
        }

        if widgetView.isHidden {
            sheet.addAction(
                .init(
                    title: .showWidget,
                    style: .default,
                    handler: { [weak self] _ in
                        self?.setWidgetVisible(true)
                    }
                )
            )
        } else {
            sheet.addAction(
                .init(
                    title: .hideWidget,
                    style: .destructive,
                    handler: { [weak self] _ in
                        self?.setWidgetVisible(false)
                    }
                )
            )
        }
        sheet.addAction(.init(title: .cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
}
