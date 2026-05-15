import Foundation

@MainActor
public class DSPCPUGraphDashboardItem: @preconcurrency DSPDashboardItem {
    public init() {}
    public let title: String = "CPU"
    public let widgetItem: DSPOptions.Widget.Item = .cpuGraph
    private var data: [Double] = []
    public func startMonitoring() {}
    public func stopMonitoring() {}

    public func update() {
        let metrics = DSPDevice.current.cpuUsage()
        data.append(Double(metrics * 100.0))
    }
    public var fetcher: DSPMetricsFetcher {
        .graph { [weak self] in
            self?.data ?? []
        }
    }
}
