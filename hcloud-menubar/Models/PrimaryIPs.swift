import Foundation

struct PrimaryIP: HCloudResource {
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

class PrimaryIPs: ObservableObject {
    @Published var items: [PrimaryIP] = []
    @Published var loaded: Bool = false

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "primary_ips",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [PrimaryIP] = decodeResourceList(from: data, container: "primary_ips", resType: "primary_ip")
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
