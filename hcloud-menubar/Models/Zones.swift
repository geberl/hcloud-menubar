import Foundation

struct Zone: HCloudResource {
    static let endpoint = "zones"
    static let resourceType = "zone"

    var id: Int?
    var name: String?
    let created: String?
    let labels: [String: String]?

    var resType: String?
    var jsonData: Data?

    enum CodingKeys: String, CodingKey {
        case id, name, created, labels
    }
}

typealias Zones = ResourceList<Zone>
