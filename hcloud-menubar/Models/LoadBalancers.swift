import Foundation

class LoadBalancer: Resource {
    var ipv4: String?
    var ipv6: String?

    override init(fromDict dict: NSDictionary, as resType: String) {
        super.init(fromDict: dict, as: resType)

        if let public_net = dict["public_net"] as? NSDictionary {
            if let ipv4 = public_net["ipv4"] as? NSDictionary {
                if let ip = ipv4["ip"] as? String {
                    self.ipv4 = ip
                }
            }
            if let ipv6 = public_net["ipv6"] as? NSDictionary {
                if let ip = ipv6["ip"] as? String {
                    self.ipv6 = ip
                }
            }
        }
    }
}

class LoadBalancers: ObservableObject {
    @Published var items: [LoadBalancer] = []
    @Published var loaded: Bool = false

    func removeItems() {
        items.removeAll()
    }

    func addItems(items: NSArray) {
        for item in items {
            guard let itemDict = item as? NSDictionary else { continue }
            self.items.append(LoadBalancer(fromDict: itemDict, as: "load_balancer"))
        }
        loaded = true
    }

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        removeItems()

        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "load_balancers",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            startDataTask(request: safeResourceRequest,
                          dataCompletion: handleResponse,
                          jsonContainer: "load_balancers",
                          addItemsHandler: addItems)
        }
    }
}
