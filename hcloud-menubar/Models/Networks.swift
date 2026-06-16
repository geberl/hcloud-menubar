import Foundation

struct Network: HCloudResource {
    static let endpoint = "networks"
    static let resourceType = "network"

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

typealias Networks = ResourceList<Network>
