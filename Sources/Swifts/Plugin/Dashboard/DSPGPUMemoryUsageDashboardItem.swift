import Foundation

@MainActor
public class DSPGPUMemoryUsageDashboardItem: @preconcurrency DSPDashboardItem {
    public init() {}
    public let title: String = "GPU MEM"
    public let widgetItem: DSPOptions.Widget.Item = .gpuMemoryUsage
    private var text: String = ""
    public func startMonitoring() {}
    public func stopMonitoring() {}

    public func update() {
        text = DSPDevice.current.localizedGPUMemory
    }

    public var fetcher: DSPMetricsFetcher {
        .text { [weak self] in
            self?.text ?? ""
        }
    }
}
