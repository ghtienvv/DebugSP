import Foundation
import UIKit

public enum DSPOptions {
    case debugSP(Menu)
    case widget(Widget)
    case launchIcon(LaunchIcon)

    public struct Menu {
        public init() {}
    }

    public struct Widget {
        public static let defaultFrame: CGRect = .init(x: 0, y: 0, width: 200, height: 200)

        public enum Item: Hashable, Sendable {
            case cpuUsage
            case cpuGraph
            case gpuMemoryUsage
            case memoryUsage
            case networkUsage
            case fps
            case thermalState
            case anyInterval
            case anyCustom
            case interval(String)
            case custom(String)

            public static let all: [Item] = [
                .cpuUsage,
                .gpuMemoryUsage,
                .memoryUsage,
                .networkUsage,
                .fps,
                .thermalState,
                .anyCustom,
            ]

            func matches(_ item: Item) -> Bool {
                switch (self, item) {
                case (.cpuUsage, .cpuUsage),
                    (.cpuGraph, .cpuGraph),
                    (.gpuMemoryUsage, .gpuMemoryUsage),
                    (.memoryUsage, .memoryUsage),
                    (.networkUsage, .networkUsage),
                    (.fps, .fps),
                    (.thermalState, .thermalState),
                    (.anyInterval, .interval),
                    (.anyCustom, .custom):
                    return true
                case let (.interval(lhs), .interval(rhs)):
                    return lhs == rhs
                case let (.custom(lhs), .custom(rhs)):
                    return lhs == rhs
                default:
                    return false
                }
            }
        }

        public var isEnabled: Bool
        public var isVisible: Bool?
        public var showsOnLaunch: Bool
        public var frame: CGRect
        public var backgroundColor: UIColor?
        public var borderColor: UIColor?
        public var borderWidth: CGFloat
        public var visibleItems: [Item]

        public init(
            isEnabled: Bool = true,
            isVisible: Bool? = nil,
            showsOnLaunch: Bool = false,
            frame: CGRect = Self.defaultFrame,
            backgroundColor: UIColor? = nil,
            borderColor: UIColor? = nil,
            borderWidth: CGFloat = 1,
            visibleItems: [Item] = Item.all
        ) {
            self.isEnabled = isEnabled
            self.isVisible = isVisible
            self.showsOnLaunch = showsOnLaunch
            self.frame = frame
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.visibleItems = visibleItems
        }
    }

    public struct LaunchIcon {
        public typealias Position = DSPFloatingItemGestureRecognizer.Edge

        let image: UIImage?
        let initialPosition: Position

        public init(
            image: UIImage? = nil,
            initialPosition: Position = .bottomTrailing
        ) {
            self.image = image
            self.initialPosition = initialPosition
        }
    }

    nonisolated(unsafe) public static var `default`: [DSPOptions] = [.debugSP(.init())]
}

extension Array where Element == DSPOptions {
    var debugSPConfiguration: DSPOptions.Menu {
        compactMap { option -> DSPOptions.Menu? in
            guard case .debugSP(let configuration) = option else { return nil }
            return configuration
        }
        .first ?? .init()
    }

    var widgetConfiguration: DSPOptions.Widget? {
        compactMap { option -> DSPOptions.Widget? in
            guard case .widget(let configuration) = option else { return nil }
            return configuration
        }
        .first
    }

    var launchIconConfiguration: DSPOptions.LaunchIcon? {
        compactMap { option -> DSPOptions.LaunchIcon? in
            guard case .launchIcon(let configuration) = option else { return nil }
            return configuration
        }
        .first
    }
}
