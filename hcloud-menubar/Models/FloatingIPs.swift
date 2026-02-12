import Foundation

class FloatingIP: Resource {
    var ip: String?

    override init(fromDict dict: NSDictionary, as resType: String) {
        super.init(fromDict: dict, as: resType)
        if let ip = dict["ip"] as? String { self.ip = ip }
    }
}

class FloatingIPs: ObservableObject {
    @Published var items: [FloatingIP] = []
    @Published var loaded: Bool = false

    func removeItems() {
        items.removeAll()
    }

    func addItems(items: NSArray) {
        for item in items {
            guard let itemDict = item as? NSDictionary else { continue }
            self.items.append(FloatingIP(fromDict: itemDict, as: "floating_ip"))
        }
        loaded = true
    }

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        removeItems()

        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "floating_ips",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            startDataTask(request: safeResourceRequest,
                          dataCompletion: handleResponse,
                          jsonContainer: "floating_ips",
                          addItemsHandler: addItems)
        }
    }
}
