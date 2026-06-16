import Foundation

struct LoadBalancer: HCloudResource {
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

class LoadBalancers: ObservableObject {
    @Published var items: [LoadBalancer] = []
    @Published var loaded: Bool = false

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "load_balancers",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [LoadBalancer] = decodeResourceList(from: data, container: "load_balancers", resType: "load_balancer")
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
