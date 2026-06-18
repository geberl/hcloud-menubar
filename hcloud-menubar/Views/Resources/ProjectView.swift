import SwiftUI

struct ProjectView: View {
    var project: Project
    @StateObject var servers = Servers()
    @StateObject var volumes = Volumes()
    @StateObject var loadBalancers = LoadBalancers()
    @StateObject var primaryIPs = PrimaryIPs()
    @StateObject var floatingIPs = FloatingIPs()
    @StateObject var networks = Networks()
    @StateObject var firewalls = Firewalls()
    @StateObject var certificates = Certificates()
    @StateObject var zones = Zones()

    var body: some View {
        Menu {
            ServersView(project: project).environmentObject(servers)
            VolumesView(project: project).environmentObject(volumes)
            LoadBalancersView(project: project).environmentObject(loadBalancers)
            PrimaryIPsView(project: project).environmentObject(primaryIPs)
            FloatingIPsView(project: project).environmentObject(floatingIPs)
            FirewallsView(project: project).environmentObject(firewalls)
            CertificatesView(project: project).environmentObject(certificates)
            NetworksView(project: project).environmentObject(networks)
            ZonesView(project: project).environmentObject(zones)

            Divider()
            Button("Copy ID", action: { copyToClipboard(content: String(project.projectId)) })
            Button("View Project", action: { openProject() })
            Divider()
            Button("Reload", action: { reloadResources() })
        } label: {
            // A failing request swaps the icon for a warning triangle so a bad project is
            // visible at a glance without opening its submenu.
            Label(project.name,
                  systemImage: project.working == false ? "exclamationmark.triangle.fill" : "note")
                .labelStyle(.titleAndIcon)
        }
        .onAppear { reloadOnStartup() }
        // Reflect the outcome of every reload (project-level, per-resource, or startup) in
        // `project.working`, so the badge tracks ongoing request health, not just the startup probe.
        .onChange(of: loadsWorking) { _, newValue in
            if let newValue { project.working = newValue }
        }
    }

    /// Token validity derived from the resource loads: `false` as soon as any list fails, `true`
    /// once at least one has loaded successfully, `nil` while everything is still idle/loading.
    private var loadsWorking: Bool? {
        let states = [servers.loadState, volumes.loadState, loadBalancers.loadState,
                      primaryIPs.loadState, floatingIPs.loadState, networks.loadState,
                      firewalls.loadState, certificates.loadState, zones.loadState]

        if states.contains(where: { if case .failed = $0 { true } else { false } }) {
            return false
        }
        if states.contains(where: { if case .loaded = $0 { true } else { false } }) {
            return true
        }
        return nil
    }

    func reloadOnStartup() {
        if project.refreshOnStartup {
            // The reloads themselves drive `project.working` via `onChange(of: loadsWorking)`.
            reloadResources()
        } else {
            // Nothing auto-loads, so probe the token directly to populate the badge on startup.
            checkToken()
        }
    }

    /// Validates the project's token directly and reflects the result in `project.working`. Used
    /// when no resource reload runs on startup to drive the badge from.
    func checkToken() {
        Task {
            switch await project.testToken() {
            case .success: project.working = true
            case .failure: project.working = false
            }
        }
    }

    func reloadResources() {
        servers.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        volumes.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        loadBalancers.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        primaryIPs.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        floatingIPs.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        firewalls.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        certificates.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        networks.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
        zones.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openProject() {
        openWebsite(webUrl: projectURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                       projectId: project.projectId))
    }
}
