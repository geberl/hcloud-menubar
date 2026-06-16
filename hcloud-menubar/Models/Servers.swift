import Foundation

struct Server: HCloudResource {
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

    func sshDisabled() -> Bool {
        (labels ?? [:]).contains { $0.key == labelSSHDisable && LabelBoolsPositive.contains($0.value) }
    }

    func sshUser() -> String {
        if let safeSSHUser = labels?[labelSSHUser] {
            // Can only contain [a-z0-9A-Z]) with dashes (-), underscores (_), dots (.)
            // So no spaces or escape characters, nothing to sanitize here
            return safeSSHUser
        }
        return DefaultSSHUser
    }

    func sshHost() -> String {
        if let safeSSHHost = labels?[labelSSHHost] {
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
        if let safeSSHPort = labels?[labelSSHPort] {
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

    func reload(customApiBaseUrl: String, token: String) {
        loaded = false
        items.removeAll()

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "servers",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return }

        startDataTask(request: request) { data in
            let decoded: [Server] = decodeResourceList(from: data, container: "servers", resType: "server")
            DispatchQueue.main.async {
                self.items = decoded
                self.loaded = true
            }
        }
    }
}
