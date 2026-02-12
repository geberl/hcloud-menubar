import SwiftUI

struct ProjectView: View {
    var project: Project
    @StateObject var servers = Servers()
    @StateObject var volumes = Volumes()
    @StateObject var loadBalancers = LoadBalancers()
    @StateObject var primaryIPs = PrimaryIPs()
    @StateObject var floatingIPs = FloatingIPs()
    @StateObject var networks = Networks()

    var body: some View {
        Menu {
            ServersView(project: project).environmentObject(servers)
            VolumesView(project: project).environmentObject(volumes)
            LoadBalancersView(project: project).environmentObject(loadBalancers)
            PrimaryIPsView(project: project).environmentObject(primaryIPs)
            FloatingIPsView(project: project).environmentObject(floatingIPs)
            NetworksView(project: project).environmentObject(networks)

            Divider()
            Button("Copy ID", action: { copyToClipboard(content: String(project.projectId)) })
            Button("View Project", action: { openProject() })
            Divider()
            Button("Reload", action: { reloadResources() })
        } label: {
            Label(project.name, systemImage: "note").labelStyle(.titleAndIcon)
        }
        .onAppear { reloadOnStartup() }
    }

    func reloadOnStartup() {
        if project.refreshOnStartup {
            reloadResources()
        }
    }

    func reloadResources() {
        servers.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        volumes.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        loadBalancers.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        primaryIPs.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        floatingIPs.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        networks.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openProject() {
        openWebsite(webUrl: projectURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                       projectId: project.projectId))
    }
}
