import Combine
import Foundation

@MainActor
public class DSPThermalStateDashboardItem: @preconcurrency DSPDashboardItem {
    public init() {}
    public let title: String = "Thermal"
    public let widgetItem: DSPOptions.Widget.Item = .thermalState
    var currentThermalState: ProcessInfo.ThermalState = .nominal

    private var cancellables: Set<AnyCancellable> = []

    public func startMonitoring() {
    }

    public func stopMonitoring() {
        cancellables = []
    }

    public func update() {
        currentThermalState = DSPDevice.current.thermalState
    }

    public var fetcher: DSPMetricsFetcher {
        .text { [weak self] in
            switch self?.currentThermalState {
            case .critical:
                return "critical"
            case .serious:
                return "serious"
            case .fair:
                return "fair"
            case .nominal:
                return "nominal"
            default:
                return "-"
            }
        }
    }
}
