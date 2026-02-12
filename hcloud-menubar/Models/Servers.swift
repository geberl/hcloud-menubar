import Foundation

class Server: Resource {
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

    func sshDisabled() -> Bool {
        labels.contains { $0.key == labelSSHDisable && LabelBoolsPositive.contains($0.value) }
    }

    func sshUser() -> String {
        if let safeSSHUser = labels[labelSSHUser] {
            // Can only contain [a-z0-9A-Z]) with dashes (-), underscores (_), dots (.)
            // So no spaces or escape characters, nothing to sanitize here
            return safeSSHUser
        }
        return DefaultSSHUser
    }

    func sshHost() -> String {
        if let safeSSHHost = labels[labelSSHHost] {
            // Can only contain [a-z0-9A-Z]) with dashes (-), underscores (_), dots (.)
            // So no spaces or escape characters, nothing to sanitize here
            return safeSSHHost
        }
        if let safeIPv4 = ipv4 {
            return safeIPv4
        }
        return "ERROR-no-ipv4-or-label-found"
    }

    func sshPort() -> String {
        if let safeSSHPort = labels[labelSSHPort] {
            if let portNumber = Int(safeSSHPort), (1 ... 65535).contains(portNumber) {
                return safeSSHPort
            }
            return DefaultSSHPort
        }
        return DefaultSSHPort
    }
}

class Servers: ObservableObject {
    @Published var items: [Server] = []
    @Published var loaded: Bool = false

    func removeItems() {
        items.removeAll()
    }

    func addItems(items: NSArray) {
        for item in items {
            guard let itemDict = item as? NSDictionary else { continue }
            self.items.append(Server(fromDict: itemDict, as: "server"))
        }
        loaded = true
    }

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        removeItems()

        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "servers",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            startDataTask(request: safeResourceRequest,
                          dataCompletion: handleResponse,
                          jsonContainer: "servers",
                          addItemsHandler: addItems)
        }
    }
}
