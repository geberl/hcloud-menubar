import Foundation

struct Volume: HCloudResource {
    static let endpoint = "volumes"
    static let resourceType = "volume"

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

typealias Volumes = ResourceList<Volume>
