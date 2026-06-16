import SwiftUI

struct NetworksView: View {
    var project: Project
    @EnvironmentObject var networks: Networks

    var body: some View {
        Menu {
            switch networks.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if networks.items.count > 0 {
                    ForEach(networks.items) { network in
                        NetworkMenuItem(project: project, network: network)
                    }
                } else {
                    Button("No Networks", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("View Networks", action: { openNetworks() })
            Divider()
            Button("Reload", action: { reloadNetworks() })
        } label: {
            Label("Networks", systemImage: "network")
                .labelStyle(.titleAndIcon)
        }
    }

    func reloadNetworks() {
        networks.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openNetworks() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "networks"))
    }
}

struct NetworkMenuItem: View {
    var project: Project
    var network: Network

    var body: some View {
        if !network.hidden() {
            Menu {
                if let safeID = network.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = network.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: network) })
                Divider()
                Button("View Network", action: { openNetworks() })
            } label: {
                Label(getTitle(), systemImage: "network")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = network.name {
            safeName
        } else {
            "Unknown"
        }
    }

    func openNetworks() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "networks"))
    }
}
