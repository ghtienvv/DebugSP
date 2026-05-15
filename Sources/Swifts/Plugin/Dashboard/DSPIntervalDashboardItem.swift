import Combine
import Foundation

public class DSPIntervalDashboardItem: DSPDashboardItem {
    public init(title: String, name: String) {
        self.title = title
        self.widgetItem = .interval(name)
        self.name = Notification.Name(name)
    }

    public let title: String
    public let widgetItem: DSPOptions.Widget.Item
    private let name: Notification.Name
    var intervals: [TimeInterval] = []
    private var cancellables: Set<AnyCancellable> = []

    public func startMonitoring() {
        NotificationCenter.default.publisher(for: name)
            .sink { notification in
                if let interval = notification.userInfo?[DSPIntervalTracker.intervalKey]
                    as? TimeInterval
                {
                    self.intervals.append(interval)
                }
            }
            .store(in: &cancellables)
    }

    public func stopMonitoring() {
        cancellables = []
    }

    public func update() {

    }

    public var fetcher: DSPMetricsFetcher {
        .interval { [weak self] in
            guard let self = self else { return [] }
            return self.intervals
        }
    }
}

public class DSPIntervalTracker {
    public enum SignpostType {
        case begin
        case end
    }
    static let intervalKey: String = "dev.appdebug.intervalTracker.interval"

    public init(name: String) {
        notificationName = .init(name)
    }

    let notificationName: Notification.Name
    var beginDate: Date?

    public func track(_ type: SignpostType) {
        switch type {
        case .begin:
            beginDate = Date()
        case .end:
            guard let beginDate = beginDate else { return }
            let interval = Date().timeIntervalSince(beginDate)
            NotificationCenter.default.post(
                Notification(
                    name: notificationName,
                    object: nil,
                    userInfo: [DSPIntervalTracker.intervalKey: interval]
                )
            )
        }
    }
}
