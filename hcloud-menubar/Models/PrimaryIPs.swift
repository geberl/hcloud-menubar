import Foundation

class PrimaryIP: Resource {
    var ip: String?

    override init(fromDict dict: NSDictionary, as resType: String) {
        super.init(fromDict: dict, as: resType)
        if let ip = dict["ip"] as? String { self.ip = ip }
    }
}

class PrimaryIPs: ObservableObject {
    @Published var items: [PrimaryIP] = []
    @Published var loaded: Bool = false

    func removeItems() {
        items.removeAll()
    }

    func addItems(items: NSArray) {
        for item in items {
            guard let itemDict = item as? NSDictionary else { continue }
            self.items.append(PrimaryIP(fromDict: itemDict, as: "primary_ip"))
        }
        loaded = true
    }

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        removeItems()

        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "primary_ips",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            startDataTask(request: safeResourceRequest,
                          dataCompletion: handleResponse,
                          jsonContainer: "primary_ips",
                          addItemsHandler: addItems)
        }
    }
}
