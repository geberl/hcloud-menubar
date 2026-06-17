import Foundation

struct Server: HCloudResource {
    static let endpoint = "servers"
    static let resourceType = "server"

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

    /// SSH user for this server, or `nil` if it fails validation.
    ///
    /// The value comes from a user-set label (or the default) and is interpolated into an
    /// executable `ssh …` command string, so it is validated against an allowlist rather than
    /// trusted: anything outside `[A-Za-z0-9._-]` (spaces, shell metacharacters, escapes) is
    /// rejected so the caller refuses to launch.
    func sshUser() -> String? {
        let user = labels?[labelSSHUser] ?? DefaultSSHUser
        return isAllowlistedSSHPrincipal(user) ? user : nil
    }

    /// SSH host for this server (label override, otherwise the public IPv4), or `nil` if it
    /// fails validation.
    ///
    /// Like ``sshUser()`` this ends up in a command string, so it is validated rather than
    /// trusted — a label host must be an allowlisted hostname/IPv4 or a literal IPv6, and the
    /// API-provided IPv4 fallback must parse as a real IPv4 address. Defends against a
    /// compromised or MITM'd API response as much as against a careless label.
    func sshHost() -> String? {
        if let labelHost = labels?[labelSSHHost] {
            return (isAllowlistedSSHPrincipal(labelHost) || isValidIPv6(labelHost)) ? labelHost : nil
        }
        if let safeIPv4 = ipv4, isValidIPv4(safeIPv4) {
            return safeIPv4
        }
        return nil
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

typealias Servers = ResourceList<Server>

// MARK: - SSH input validation

/// True if `value` is a non-empty string of only `[A-Za-z0-9._-]` — the allowlist for an SSH
/// user or hostname before it is interpolated into a command string.
private func isAllowlistedSSHPrincipal(_ value: String) -> Bool {
    !value.isEmpty && value.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil
}

/// True if `value` parses as a literal IPv4 address.
private func isValidIPv4(_ value: String) -> Bool {
    var addr = in_addr()
    return value.withCString { inet_pton(AF_INET, $0, &addr) == 1 }
}

/// True if `value` parses as a literal IPv6 address.
private func isValidIPv6(_ value: String) -> Bool {
    var addr = in6_addr()
    return value.withCString { inet_pton(AF_INET6, $0, &addr) == 1 }
}
