import Foundation

@MainActor
public class DSPMemoryUsageDashboardItem: @preconcurrency DSPDashboardItem {
    public init() {}
    public let title: String = "MEM"
    public let widgetItem: DSPOptions.Widget.Item = .memoryUsage
    private var text: String = ""
    public func startMonitoring() {}
    public func stopMonitoring() {}
    
    public func update() {
        text = DSPDevice.current.localizedMemoryUsage
    }
    public var fetcher: DSPMetricsFetcher {
        .text { [weak self] in
            self?.text ?? ""
        }
    }
}
