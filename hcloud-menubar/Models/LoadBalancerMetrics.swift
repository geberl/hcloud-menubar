import Foundation

// MARK: - Decoded samples

/// One point of a metric time series: a timestamp and its numeric value.
struct MetricSample: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

// MARK: - API response shape
//
// `GET /load_balancers/{id}/metrics` returns:
//   { "metrics": { "start", "end", "step",
//                  "time_series": { "<name>": { "values": [[<unix-seconds>, "<value>"], …] } } } }
// Each value pair is a heterogeneous array: element 0 is a number (unix seconds, possibly
// fractional), element 1 is the value as a *string*.

struct LBMetricsResponse: Decodable {
    let metrics: Metrics

    struct Metrics: Decodable {
        let start: String
        let end: String
        let step: Double
        let timeSeries: [String: Series]

        enum CodingKeys: String, CodingKey {
            case start, end, step
            case timeSeries = "time_series"
        }
    }

    struct Series: Decodable {
        let values: [MetricPair]
    }

    /// A single `[timestamp, "value"]` entry, decoded from the heterogeneous JSON array.
    struct MetricPair: Decodable {
        let date: Date
        let value: Double

        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let timestamp = try container.decode(Double.self)
            let raw = try container.decode(String.self)
            date = Date(timeIntervalSince1970: timestamp)
            value = Double(raw) ?? 0
        }
    }
}

// MARK: - Toolbar picker options

/// How often the window re-fetches metrics when auto-refresh is on. Raw value is the interval
/// in seconds.
enum RefreshRate: Int, CaseIterable, Identifiable {
    case s10 = 10
    case s30 = 30
    case m1 = 60
    case m5 = 300
    case m15 = 900
    case h1 = 3600

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .s10: "10 seconds"
        case .s30: "30 seconds"
        case .m1: "1 minute"
        case .m5: "5 minutes"
        case .m15: "15 minutes"
        case .h1: "1 hour"
        }
    }
}

/// Span of time displayed in the chart. Raw value is the length of the window in seconds.
enum DisplayRange: Int, CaseIterable, Identifiable {
    case hour1 = 3600
    case hours12 = 43200
    case hours24 = 86400
    case week1 = 604800
    case days30 = 2592000

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .hour1: "Last hour"
        case .hours12: "Last 12 hours"
        case .hours24: "Last 24 hours"
        case .week1: "Last week"
        case .days30: "Last 30 days"
        }
    }

    /// Resolution requested from the API, chosen to keep the number of returned points sane for
    /// the span (~60–170 points each).
    var step: Int {
        switch self {
        case .hour1: 60 // 1 min
        case .hours12: 300 // 5 min
        case .hours24: 600 // 10 min
        case .week1: 3600 // 1 hour
        case .days30: 21600 // 6 hours
        }
    }
}

// MARK: - Window view model

/// Observable backing for one metrics window. Mirrors the `ResourceList` pattern: `@MainActor`
/// isolated with `@Published` state, while the network fetch/decode runs off the main actor inside
/// `loadLoadBalancerMetrics`.
@MainActor
final class LoadBalancerMetricsModel: ObservableObject {
    /// Decoded series keyed by metric type (e.g. `requests_per_second`).
    @Published var series: [String: [MetricSample]] = [:]
    @Published var loadState: LoadState = .idle
    @Published var lastRefreshed: Date?
    /// When the next auto-refresh is scheduled; `nil` when auto-refresh is off.
    @Published var nextRefresh: Date?

    /// Whether a fetch is currently in flight, used to drive the toolbar spinner.
    var isRefreshing: Bool { loadState == .loading }

    @Published var rate: RefreshRate = .s30 {
        didSet { if autoRefresh { restartAutoRefresh() } }
    }

    @Published var autoRefresh: Bool = false {
        didSet { restartAutoRefresh() }
    }

    @Published var range: DisplayRange = .hour1 {
        didSet { refresh() }
    }

    private let customApiBaseUrl: String
    private let loadBalancerId: Int
    private let token: String

    private var autoRefreshTask: Task<Void, Never>?

    init(customApiBaseUrl: String, loadBalancerId: Int, token: String) {
        self.customApiBaseUrl = customApiBaseUrl
        self.loadBalancerId = loadBalancerId
        self.token = token
    }

    /// Fetch the current window of metrics once.
    func refresh() {
        loadState = .loading

        let timeout = AppSettings.shared.timeoutSeconds
        let rangeSeconds = range.rawValue
        let step = range.step

        Task {
            switch await loadLoadBalancerMetrics(customApiBaseUrl: customApiBaseUrl,
                                                 loadBalancerId: loadBalancerId,
                                                 rangeSeconds: rangeSeconds,
                                                 step: step,
                                                 timeout: timeout,
                                                 token: token)
            {
            case let .success(decoded):
                series = decoded
                loadState = .loaded
                lastRefreshed = Date()
            case let .failure(error):
                series = [:]
                loadState = .failed(error)
            }
        }
    }

    /// (Re)build the periodic refresh loop to match `autoRefresh`/`rate`. Cancels any existing loop
    /// first so changing the rate doesn't leave two loops running.
    private func restartAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil

        guard autoRefresh else {
            nextRefresh = nil
            return
        }

        let interval = rate.rawValue
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.nextRefresh = Date().addingTimeInterval(Double(interval))
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled { break }
                self?.refresh()
            }
        }
    }

    /// Stop the periodic refresh loop. Call when the window closes.
    func stop() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
        nextRefresh = nil
    }
}
