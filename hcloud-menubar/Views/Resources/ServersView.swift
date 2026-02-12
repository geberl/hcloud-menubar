import SwiftUI

struct ServersView: View {
    var project: Project
    @EnvironmentObject var servers: Servers

    var body: some View {
        Menu {
            if servers.loaded {
                if servers.items.count > 0 {
                    ForEach(servers.items) { server in
                        ServerMenuItem(project: project, server: server)
                    }
                } else {
                    Button("No Servers", action: {}).disabled(true)
                }
            } else {
                Button("Not Loaded", action: {}).disabled(true)
            }
            Divider()
            Button("New Server", action: { newServer() })
            Button("View Servers", action: { openServers() })
            Divider()
            Button("Reload", action: { reloadServers() })
        }
        label: {
            Label("Servers", systemImage: "server.rack")
                .labelStyle(.titleAndIcon)
        }
    }

    func newServer() {
        openWebsite(webUrl: generateCreateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                      projectId: project.projectId,
                                                      resourceName: "servers"))
    }

    func openServers() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "servers"))
    }

    func reloadServers() {
        servers.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }
}

struct ServerMenuItem: View {
    var project: Project
    var server: Server

    var body: some View {
        if !server.hidden() {
            Menu {
                Group {
                    if let safeID = server.id {
                        Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                    }
                    if let safeName = server.name {
                        Button("Copy Name", action: { copyToClipboard(content: safeName) })
                    }
                    if let safeIPv4 = server.ipv4 {
                        Button("Copy IPv4", action: { copyToClipboard(content: safeIPv4) })
                    }
                    if let safeIPv6 = server.ipv6 {
                        Button("Copy IPv6", action: { copyToClipboard(content: safeIPv6) })
                    }
                    Divider()
                    if !server.sshDisabled() {
                        Button("Start SSH Session", action: { startSSHSession(server: server) })
                    }
                    Button("Show JSON", action: { openJsonInEditor(resource: server) })
                    Divider()
                }
                Button("View Server", action: { openServer(serverId: server.id) })
            } label: {
                Label(getTitle(), systemImage: "server.rack")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = server.name {
            if let safeIPv4 = server.ipv4 {
                "\(safeName) (\(safeIPv4))"
            } else {
                safeName
            }
        } else {
            "Unknown"
        }
    }

    func startSSHSession(server: Server) {
        let appTerminal = AppSettings.shared.appTerminal

        if TerminalValuesOpenCommand.values.contains(appTerminal) {
            let command = "ssh \(server.sshUser())@\(server.sshHost()) -p \(server.sshPort())"
            startSshViaCommand(bundleIdentifier: appTerminal, command: command)
        } else {
            let sshConnectionString = "ssh://\(server.sshUser())@\(server.sshHost()):\(server.sshPort())"
            if let safeSshUrl = URL(string: sshConnectionString) {
                logUi.info("Server startSSHSession: Attempting to open '\(safeSshUrl)' with '\(appTerminal)'")
                openUrlInApp(url: safeSshUrl, app: appTerminal)
            } else {
                logUi.error("Server startSSHSession: Unable to create SSH URL from '\(sshConnectionString)'")
            }
        }
    }

    func openServer(serverId: Int?) {
        openWebsite(webUrl: generateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                projectId: project.projectId,
                                                resourceName: "servers",
                                                resourceId: serverId))
    }
}
