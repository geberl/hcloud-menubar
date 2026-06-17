import SwiftUI

struct FirewallsView: View {
    var project: Project
    @EnvironmentObject var firewalls: Firewalls

    var body: some View {
        Menu {
            switch firewalls.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if firewalls.items.count > 0 {
                    ForEach(firewalls.items) { firewall in
                        FirewallMenuItem(project: project, firewall: firewall)
                    }
                } else {
                    Button("No Firewalls", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("New Firewall", action: { newFirewall() })
            Button("View Firewalls", action: { openFirewalls() })
            Divider()
            Button("Reload", action: { reloadFirewalls() })
        } label: {
            Label("Firewalls", systemImage: "lock.fill")
                .labelStyle(.titleAndIcon)
        }
    }

    func newFirewall() {
        openWebsite(webUrl: generateCreateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                      projectId: project.projectId,
                                                      resourceName: "firewalls"))
    }

    func openFirewalls() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "firewalls"))
    }

    func reloadFirewalls() {
        firewalls.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }
}

struct FirewallMenuItem: View {
    var project: Project
    var firewall: Firewall

    var body: some View {
        if !firewall.hidden() {
            Menu {
                if let safeID = firewall.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = firewall.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: firewall) })
                Divider()
                Button("View Firewall", action: { openFirewall(firewallId: firewall.id) })
            } label: {
                Label(getTitle(), systemImage: "lock.fill")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = firewall.name {
            safeName
        } else {
            "Unknown"
        }
    }

    func openFirewall(firewallId: Int?) {
        openWebsite(webUrl: generateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                projectId: project.projectId,
                                                resourceName: "firewalls",
                                                resourceId: firewallId))
    }
}
