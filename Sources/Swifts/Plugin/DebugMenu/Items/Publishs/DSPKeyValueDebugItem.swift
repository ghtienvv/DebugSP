import Foundation

public struct DSPKeyValueDebugItem: DSPDebugItem {

    @MainActor
    public init(
        title: String,
        fetcher: @escaping @Sendable () async -> [DSPEnvelope]) {
        self.title = title
        self.action = .didSelect(operation: { @MainActor parent in
            let vc = DSPEnvelopePreviewTableVC(fetcher: fetcher)
            parent.navigationController?.pushViewController(vc, animated: true)
            return .success()
        })
    }

    let title: String
    public var debugItemTitle: String { title }
    public let action: DSPDebugItemAction
}
