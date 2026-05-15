import Foundation

@MainActor
public struct DSPDeviceInfoDebugItem: DSPDebugItem {

    public init() {}

    public var debugItemTitle: String = "Device Info"

    public var action: DSPDebugItemAction = .didSelect { @MainActor parent in
        let controller = DSPEnvelopePreviewTableVC {
            [
                "Name": DSPDevice.current.name,
                "Battery level": DSPDevice.current.localizedBatteryLevel,
                "Battery state": DSPDevice.current.localizedBatteryState,
                "Model": DSPDevice.current.localizedModel,
                "System name": DSPDevice.current.systemName,
                "System version": DSPDevice.current.systemVersion,
                "Jailbreak?": DSPDevice.current.isJailbreaked ? "YES" : "NO",
                "System uptime": DSPDevice.current.localizedSystemUptime,
                "Uptime": DSPDevice.current.localizedUptime,
                "LowPower mode?": DSPDevice.current.isLowPowerModeEnabled ? "YES" : "NO",
                "Processor": DSPDevice.current.processor,
                "Physical Memory": DSPDevice.current.localizedPhysicalMemory,
                "Disk usage": DSPDevice.current.localizedDiskUsage,
            ]
            .map({ DSPEnvelope(key: $0.key, value: $0.value) }).sorted(by: { $0.key < $1.key })
        }
        await parent.navigationController?.pushViewController(controller, animated: true)
        return .success()
    }

}
