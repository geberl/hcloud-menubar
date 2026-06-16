import Foundation

/// Shared shape for every Hetzner Cloud resource the app lists.
///
/// Conformers are `Codable` structs whose API-backed fields are all optional, so the
/// synthesized decoder uses `decodeIfPresent` and never throws on a missing/null field.
/// `resType` and `jsonData` are not part of the API payload; they are populated after
/// decoding by `decodeResourceList(from:)`.
protocol HCloudResource: Codable, Identifiable {
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
class ResourceList<T: HCloudResource>: ObservableObject {
    @Published var items: [T] = []
    @Published var loaded: Bool = false

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: T.endpoint,
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [T] = decodeResourceList(from: data)
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
