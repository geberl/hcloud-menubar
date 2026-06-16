import SwiftUI

struct FloatingIPsView: View {
    var project: Project
    @EnvironmentObject var floatingIPs: FloatingIPs

    var body: some View {
        Menu {
            switch floatingIPs.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if floatingIPs.items.count > 0 {
                    ForEach(floatingIPs.items) { floatingIP in
                        FloatingIPMenuItem(project: project, floatingIP: floatingIP)
                    }
                } else {
                    Button("No Floating IPs", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("View Floating IPs", action: { openFloatingIPs() })
            Divider()
            Button("Reload", action: { reloadFloatingIPs() })
        } label: {
            Label("Floating IPs", systemImage: "point.3.connected.trianglepath.dotted")
                .labelStyle(.titleAndIcon)
        }
    }

    func reloadFloatingIPs() {
        floatingIPs.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openFloatingIPs() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "floatingips"))
    }
}

struct FloatingIPMenuItem: View {
    var project: Project
    var floatingIP: FloatingIP

    var body: some View {
        if !floatingIP.hidden() {
            Menu {
                if let safeID = floatingIP.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = floatingIP.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                if let safeIP = floatingIP.ip {
                    Button("Copy IP", action: { copyToClipboard(content: safeIP) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: floatingIP) })
                Divider()
                Button("View Floating IP", action: { openFloatingIPs() })
            } label: {
                Label(getTitle(), systemImage: "point.3.connected.trianglepath.dotted")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = floatingIP.name {
            if let safeValue = floatingIP.ip {
                "\(safeName) (\(safeValue))"
            } else {
                safeName
            }
        } else {
            "Unknown"
        }
    }

    func openFloatingIPs() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "floatingips"))
    }
}
