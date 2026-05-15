import UIKit

@MainActor
public enum DSPUIMeasurement {
    public enum Mode: String, CaseIterable, Sendable {
        case manual
        case selection

        public var title: String {
            switch self {
            case .manual:
                return "Manual Guides"
            case .selection:
                return "Element Measurement"
            }
        }

        public var detailText: String {
            switch self {
            case .manual:
                return "Drag horizontal and vertical guides to verify alignment and margins."
            case .selection:
                return "Tap once to select a view, then tap again to compare spacing."
            }
        }
    }

    public static var isActive: Bool {
        DSPUIMeasurementWindowManager.mode != nil
    }

    public static var currentMode: Mode? {
        DSPUIMeasurementWindowManager.mode
    }

    public static func activate(mode: Mode) {
        DSPUIMeasurementWindowManager.activate(mode: mode)
    }

    public static func deactivate() {
        DSPUIMeasurementWindowManager.deactivate()
    }

    public static func toggle(mode: Mode = .selection) {
        if currentMode == mode {
            deactivate()
        } else {
            activate(mode: mode)
        }
    }
}

@MainActor
protocol DSPUIMeasurementOverlay: AnyObject {
    var attachedWindow: UIWindow? { get set }
}

@MainActor
enum DSPUIMeasurementWindowManager {
    static var mode: DSPUIMeasurement.Mode?

    private static var overlayWindow: DSPUIMeasurementWindow?

    static func activate(mode: DSPUIMeasurement.Mode) {
        guard let appWindow = targetApplicationWindow() else { return }

        let overlayWindow = ensureOverlayWindow(for: appWindow)
        overlayWindow.overlayViewController.apply(mode: mode, attachedWindow: appWindow)
        overlayWindow.frame = appWindow.bounds
        overlayWindow.isHidden = false
        self.mode = mode
    }

    static func deactivate() {
        mode = nil
        overlayWindow?.overlayViewController.clear()
        overlayWindow?.isHidden = true
    }

    private static func ensureOverlayWindow(for appWindow: UIWindow) -> DSPUIMeasurementWindow {
        if overlayWindow?.windowScene !== appWindow.windowScene {
            overlayWindow?.isHidden = true
            overlayWindow = nil
        }

        if let overlayWindow {
            return overlayWindow
        }

        let window = if let windowScene = appWindow.windowScene {
            DSPUIMeasurementWindow(windowScene: windowScene)
        } else {
            DSPUIMeasurementWindow(frame: appWindow.bounds)
        }
        window.isHidden = false
        window.frame = appWindow.bounds
        window.overlayViewController.view.frame = window.bounds
        overlayWindow = window
        return window
    }

    static func targetApplicationWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let windows = scenes.flatMap(\.windows)
            .filter { window in
                guard !window.isHidden, window.alpha > 0 else { return false }
                guard !(window is DSPInAppDebuggerWindow), !(window is DSPUIMeasurementWindow) else {
                    return false
                }

                let className = String(describing: type(of: window))
                return className != "UITextEffectsWindow"
                    && className != "UIRemoteKeyboardWindow"
            }

        return windows.first(where: \.isKeyWindow) ?? windows.first
    }
}

@MainActor
final class DSPUIMeasurementWindow: UIWindow {
    let overlayViewController = DSPUIMeasurementViewController()

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var windowLevel: UIWindow.Level {
        get { .normal + 1 }
        set {}
    }

    private func sharedInit() {
        backgroundColor = .clear
        rootViewController = overlayViewController
        isHidden = true
    }
}

@MainActor
final class DSPUIMeasurementViewController: UIViewController {
    private var currentOverlayView: (UIView & DSPUIMeasurementOverlay)?

    override func loadView() {
        view = UIView(frame: .zero)
        view.backgroundColor = .clear
    }

    func apply(mode: DSPUIMeasurement.Mode, attachedWindow: UIWindow) {
        currentOverlayView?.removeFromSuperview()
        currentOverlayView?.attachedWindow = nil

        let overlayView: UIView & DSPUIMeasurementOverlay
        switch mode {
        case .manual:
            overlayView = DSPUIMeasurementManualView()
        case .selection:
            overlayView = DSPUIMeasurementSelectionView()
        }

        overlayView.attachedWindow = attachedWindow
        overlayView.frame = view.bounds
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlayView)
        currentOverlayView = overlayView
    }

    func clear() {
        currentOverlayView?.attachedWindow = nil
        currentOverlayView?.removeFromSuperview()
        currentOverlayView = nil
    }
}
