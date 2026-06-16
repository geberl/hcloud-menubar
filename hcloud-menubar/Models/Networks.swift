import Foundation

struct Network: HCloudResource {
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

class Networks: ObservableObject {
    @Published var items: [Network] = []
    @Published var loaded: Bool = false

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "networks",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [Network] = decodeResourceList(from: data, container: "networks", resType: "network")
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
