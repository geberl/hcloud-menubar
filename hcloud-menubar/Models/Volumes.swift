import Foundation

struct Volume: HCloudResource {
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

class Volumes: ObservableObject {
    @Published var items: [Volume] = []
    @Published var loaded: Bool = false

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "volumes",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [Volume] = decodeResourceList(from: data, container: "volumes", resType: "volume")
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
