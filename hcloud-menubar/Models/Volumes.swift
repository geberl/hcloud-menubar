import Foundation

class Volume: Resource {}

class Volumes: ObservableObject {
    @Published var items: [Volume] = []
    @Published var loaded: Bool = false

    func removeItems() {
        items.removeAll()
    }

    func addItems(items: NSArray) {
        for item in items {
            guard let itemDict = item as? NSDictionary else { continue }
            self.items.append(Volume(fromDict: itemDict, as: "volume"))
        }
        loaded = true
    }

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        removeItems()

        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "volumes",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            startDataTask(request: safeResourceRequest,
                          dataCompletion: handleResponse,
                          jsonContainer: "volumes",
                          addItemsHandler: addItems)
        }
    }
}
