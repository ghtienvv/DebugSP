import Foundation
import SwiftUI
import UIKit

@available(iOSApplicationExtension, unavailable)
private struct DSPDebugSPInstallerView: UIViewRepresentable {
    let debuggerItems: [any DSPDebugItem]
    let dashboardItems: [any DSPDashboardItem]
    let options: [DSPOptions]

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let windowScene = uiView.window?.windowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        DebugSP.install(
            windowScene: windowScene,
            items: debuggerItems,
            dashboardItems: dashboardItems,
            options: options
        )
    }
}

@available(iOSApplicationExtension, unavailable)
struct DSPDebugSPModifier: ViewModifier, @unchecked Sendable {
    internal init(
        debuggerItems: [any DSPDebugItem],
        dashboardItems: [any DSPDashboardItem],
        options: [DSPOptions]
    ) {
        self.debuggerItems = debuggerItems
        self.dashboardItems = dashboardItems
        self.options = options
    }

    let debuggerItems: [any DSPDebugItem]
    let dashboardItems: [any DSPDashboardItem]
    let options: [DSPOptions]

    func body(content: Content) -> some View {
        content.background(
            DSPDebugSPInstallerView(
                debuggerItems: debuggerItems,
                dashboardItems: dashboardItems,
                options: options
            )
            .frame(width: 0, height: 0)
        )
    }
}

@available(iOSApplicationExtension, unavailable)
public extension View {
    
    @ViewBuilder
    func debugSP(
        debuggerItems: [any DSPDebugItem] = [],
        dashboardItems: [any DSPDashboardItem] = [],
        options: [DSPOptions] = DSPOptions.default,
        enabled: Bool = true) -> some View {
        if enabled {
            modifier(
                DSPDebugSPModifier(
                    debuggerItems: debuggerItems,
                    dashboardItems: dashboardItems,
                    options: options
                )
            )
        } else {
            self
        }
    }
}
