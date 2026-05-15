import Foundation

@MainActor
public class DSPCPUUsageDashboardItem: @preconcurrency DSPDashboardItem {
    public init() {}
    public let title: String = "CPU"
    public let widgetItem: DSPOptions.Widget.Item = .cpuUsage
    private var text: String = ""
    public func startMonitoring() {}
    public func stopMonitoring() {}
    public func update() {
        text = DSPDevice.current.localizedCPUUsage
    }
    public var fetcher: DSPMetricsFetcher {
        .text { [weak self] in
            self?.text ?? ""
        }
    }
}
