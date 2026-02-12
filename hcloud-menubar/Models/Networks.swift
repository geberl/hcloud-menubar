import Foundation

class Network: Resource {}

class Networks: ObservableObject {
    @Published var items: [Network] = []
    @Published var loaded: Bool = false

    func removeItems() {
        items.removeAll()
    }

    func addItems(items: NSArray) {
        for item in items {
            guard let itemDict = item as? NSDictionary else { continue }
            self.items.append(Network(fromDict: itemDict, as: "network"))
        }
        loaded = true
    }

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        removeItems()

        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "networks",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            startDataTask(request: safeResourceRequest,
                          dataCompletion: handleResponse,
                          jsonContainer: "networks",
                          addItemsHandler: addItems)
        }
    }
}
