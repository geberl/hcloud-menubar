import Foundation

struct LoadBalancer: HCloudResource {
    static let endpoint = "load_balancers"
    static let resourceType = "load_balancer"

    var id: Int?
    var name: String?
    var created: String?
    var labels: [String: String]?
    var publicNet: PublicNet?

    var resType: String?
    var jsonData: Data?

    enum CodingKeys: String, CodingKey {
        case id, name, created, labels
        case publicNet = "public_net"
    }

    var ipv4: String? {
        publicNet?.ipv4?.ip
    }

    var ipv6: String? {
        publicNet?.ipv6?.ip
    }
}

typealias LoadBalancers = ResourceList<LoadBalancer>
