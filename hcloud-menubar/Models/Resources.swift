import Foundation

/// Shared shape for every Hetzner Cloud resource the app lists.
///
/// Conformers are `Codable` structs whose API-backed fields are all optional, so the
/// synthesized decoder uses `decodeIfPresent` and never throws on a missing/null field.
/// `resType` and `jsonData` are not part of the API payload; they are populated after
/// decoding by `decodeResourceList(from:container:resType:)`.
protocol HCloudResource: Codable, Identifiable {
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
