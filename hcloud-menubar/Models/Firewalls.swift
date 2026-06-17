import Foundation

struct Firewall: HCloudResource {
    static let endpoint = "firewalls"
    static let resourceType = "firewall"

    var id: Int?
    var name: String?
    var created: String?
    var labels: [String: String]?

    var resType: String?
    var jsonData: Data?

    enum CodingKeys: String, CodingKey {
        case id, name, created, labels
    }
}

typealias Firewalls = ResourceList<Firewall>
