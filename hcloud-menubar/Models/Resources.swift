import Foundation

/// Shared shape for every Hetzner Cloud resource the app lists.
///
/// Conformers are `Codable` structs whose API-backed fields are all optional, so the
/// synthesized decoder uses `decodeIfPresent` and never throws on a missing/null field.
/// `resType` and `jsonData` are not part of the API payload; they are populated after
/// decoding by `decodeResourceList(from:)`.
protocol HCloudResource: Codable, Identifiable, Sendable {
    /// API path suffix, which is also the JSON container key (e.g. "servers").
    static var endpoint: String { get }
    /// Singular type tag (e.g. "server"), stored on each item as `resType`.
    static var resourceType: String { get }

    var id: Int? { get }
    var name: String? { get }
    var created: String? { get }
    var labels: [String: String]? { get }

    /// Resource type tag (e.g. "server"), used when dumping JSON to a temp file.
    var resType: String? { get set }
    /// The raw, pretty-printed JSON for this single item, used by "Show JSON".
    var jsonData: Data? { get set }
}

extension HCloudResource {
    func hidden() -> Bool {
        (labels ?? [:]).contains { $0.key == labelHide && LabelBoolsPositive.contains($0.value) }
    }
}

/// Why a resource load failed, mapped from the network/HTTP outcome. Carries enough detail for
/// the menu (and, later, the settings token test) to tell the user *what* went wrong rather than
/// showing a single opaque failure.
///
/// The mapping from concrete network responses onto these cases is wired up in a later step; for
/// now this is the payload type for `LoadState.failed`.
enum HCloudError: Error, Equatable {
    case auth // HTTP 401 — token missing, invalid, or lacking permissions
    case rateLimited // HTTP 429
    case server // HTTP 5xx
    case network // timeout or no connectivity
    case decoding // HTTP 200 but the body wasn't the expected shape
    case unexpected(Int) // any other HTTP status code

    /// Short line shown in the menu when a load fails.
    var menuDescription: String {
        switch self {
        case .auth: "Unauthorized"
        case .rateLimited: "Rate limited — try later"
        case .server: "Server error — try later"
        case .network: "Network error — retry"
        case .decoding: "Unexpected response"
        case let .unexpected(code): "Request failed (HTTP \(code))"
        }
    }
}

/// Lifecycle of a `ResourceList` load, replacing the old `loaded: Bool` so the menu can tell
/// "never loaded", "loading", "loaded", and "failed" apart instead of collapsing them all into a
/// permanent "Not Loaded".
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(HCloudError)
}

/// Hetzner's `public_net` block, shared by servers and load balancers.
struct PublicNet: Codable {
    struct IPField: Codable {
        let ip: String?
    }

    let ipv4: IPField?
    let ipv6: IPField?
}

/// Generic, observable collection of a single Hetzner Cloud resource type.
///
/// All resource lists differ only by their element type, so each concrete list is just a
/// `typealias` over this class (e.g. `typealias Servers = ResourceList<Server>`). The API
/// endpoint and type tag are read from the element type's static metadata.
///
/// The class is `@MainActor`-isolated, so the network fetch/decode runs off the main actor
/// (inside the non-isolated `loadResources`) while the `@Published` mutations are compiler-
/// guaranteed to happen back on the main actor.
@MainActor
class ResourceList<T: HCloudResource>: ObservableObject {
    @Published var items: [T] = []
    @Published var loadState: LoadState = .idle

    func reload(customApiBaseUrl: String, token: String) {
        loadState = .loading
        items.removeAll()

        let timeout = AppSettings.shared.timeoutSeconds

        Task {
            switch await loadResources(customApiBaseUrl: customApiBaseUrl,
                                       resourceSuffix: T.endpoint,
                                       timeout: timeout,
                                       token: token) as Result<[T], HCloudError>
            {
            case let .success(decoded):
                items = decoded
                loadState = .loaded
            case let .failure(error):
                loadState = .failed(error)
            }
        }
    }
}
