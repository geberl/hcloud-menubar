import Foundation

struct FloatingIP: HCloudResource {
    static let endpoint = "floating_ips"
    static let resourceType = "floating_ip"

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

typealias FloatingIPs = ResourceList<FloatingIP>
