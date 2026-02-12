import SwiftUI

struct PrimaryIPsView: View {
    var project: Project
    @EnvironmentObject var primaryIPs: PrimaryIPs

    var body: some View {
        Menu {
            if primaryIPs.loaded {
                if primaryIPs.items.count > 0 {
                    ForEach(primaryIPs.items) { primaryIP in
                        PrimaryIPMenuItem(project: project, primaryIP: primaryIP)
                    }
                } else {
                    Button("No Primary IPs", action: {}).disabled(true)
                }
            } else {
                Button("Not Loaded", action: {}).disabled(true)
            }
            Divider()
            Button("View Primary IPs", action: { openPrimaryIPs() })
            Divider()
            Button("Reload", action: { reloadPrimaryIPs() })
        } label: {
            Label("Primary IPs", systemImage: "app.connected.to.app.below.fill")
                .labelStyle(.titleAndIcon)
        }
    }

    func reloadPrimaryIPs() {
        primaryIPs.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openPrimaryIPs() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "servers/primaryips"))
    }
}

struct PrimaryIPMenuItem: View {
    var project: Project
    var primaryIP: PrimaryIP

    var body: some View {
        if !primaryIP.hidden() {
            Menu {
                if let safeID = primaryIP.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = primaryIP.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                if let safeIP = primaryIP.ip {
                    Button("Copy IP", action: { copyToClipboard(content: safeIP) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: primaryIP) })
                Divider()
                Button("View Primary IP", action: { openPrimaryIPs() })
            } label: {
                Label(getTitle(), systemImage: "app.connected.to.app.below.fill")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = primaryIP.name {
            if let safeValue = primaryIP.ip {
                "\(safeName) (\(safeValue))"
            } else {
                safeName
            }
        } else {
            "Unknown"
        }
    }

    func openPrimaryIPs() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "servers/primaryips"))
    }
}
