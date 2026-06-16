import Foundation

struct PrimaryIP: HCloudResource {
    static let endpoint = "primary_ips"
    static let resourceType = "primary_ip"

    var id: Int?
    var name: String?
    var created: String?
    var labels: [String: String]?
    var ip: String?

    var resType: String?
    var jsonData: Data?

    enum CodingKeys: String, CodingKey {
        case id, name, created, labels, ip
    }
}

typealias PrimaryIPs = ResourceList<PrimaryIP>
