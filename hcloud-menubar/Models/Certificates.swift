import Foundation

struct Certificate: HCloudResource {
    static let endpoint = "certificates"
    static let resourceType = "certificate"

    var id: Int?
    var name: String?
    var created: String?
    var labels: [String: String]?

    /// The PEM-encoded public key / certificate chain.
    var certificate: String?
    /// "uploaded" for a self-managed certificate, "managed" for a Hetzner-managed one.
    var type: String?
    /// Domains the certificate is valid for.
    var domainNames: [String]?
    /// Expiry timestamp (RFC3339), used to surface "expires" info in the menu.
    var notValidAfter: String?
    var fingerprint: String?

    var resType: String?
    var jsonData: Data?

    enum CodingKeys: String, CodingKey {
        case id, name, created, labels, certificate, type, fingerprint
        case domainNames = "domain_names"
        case notValidAfter = "not_valid_after"
    }

    /// The PEM public key with any literal `\n` sequences turned into real newlines, so it
    /// pastes as a valid multi-line PEM block. Decoded JSON already uses real newlines; the
    /// replacement is a safety net for sources that escape them as two characters.
    var publicKey: String? {
        certificate?.replacingOccurrences(of: "\\n", with: "\n")
    }
}

typealias Certificates = ResourceList<Certificate>
