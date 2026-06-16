import Foundation

struct FloatingIP: HCloudResource {
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

class FloatingIPs: ObservableObject {
    @Published var items: [FloatingIP] = []
    @Published var loaded: Bool = false

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "floating_ips",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [FloatingIP] = decodeResourceList(from: data, container: "floating_ips", resType: "floating_ip")
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
