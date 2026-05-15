import Foundation

public enum DSPMetricsFetcher {
    case text(_ fetcher: () -> String)
    case graph(_ fetcher: () -> [Double])
    case interval(_ fetcher: () -> [TimeInterval])
}
