import Foundation

public protocol DSPDashboardItem {
    var title: String { get }
    var widgetItem: DSPOptions.Widget.Item { get }
    func startMonitoring()
    func stopMonitoring()
    func update()
    var fetcher: DSPMetricsFetcher { get }
}

public extension DSPDashboardItem {
    var widgetItem: DSPOptions.Widget.Item {
        .custom(title)
    }
}
