import AppKit
import SwiftUI

struct LoadBalancersView: View {
    var project: Project
    @EnvironmentObject var loadBalancers: LoadBalancers

    var body: some View {
        Menu {
            switch loadBalancers.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if loadBalancers.items.count > 0 {
                    ForEach(loadBalancers.items) { loadBalancer in
                        LoadBalancerMenuItem(project: project, loadBalancer: loadBalancer)
                    }
                } else {
                    Button("No Load Balancers", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("New Load Balancer", action: { newLoadBalancer() })
            Button("View Load Balancers", action: { openLoadBalancers() })
            Divider()
            Button("Reload", action: { reloadLoadBalancers() })
        } label: {
            Label("Load Balancers", systemImage: "arrow.triangle.branch")
                .labelStyle(.titleAndIcon)
        }
    }

    func newLoadBalancer() {
        openWebsite(webUrl: generateCreateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                      projectId: project.projectId,
                                                      resourceName: "loadbalancers"))
    }

    func reloadLoadBalancers() {
        loadBalancers.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openLoadBalancers() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "loadbalancers"))
    }
}

struct LoadBalancerMenuItem: View {
    var project: Project
    var loadBalancer: LoadBalancer
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if !loadBalancer.hidden() {
            Menu {
                if let safeID = loadBalancer.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = loadBalancer.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                if let safeIPv4 = loadBalancer.ipv4 {
                    Button("Copy IPv4", action: { copyToClipboard(content: safeIPv4) })
                }
                if let safeIPv6 = loadBalancer.ipv6 {
                    Button("Copy IPv6", action: { copyToClipboard(content: safeIPv6) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: loadBalancer) })
                if loadBalancer.id != nil {
                    Button("Show Metrics", action: { showMetrics() })
                }
                Divider()
                Button("View Load Balancer", action: { openLoadBalancer(loadBalancerId: loadBalancer.id) })
            } label: {
                Label(getTitle(), systemImage: "arrow.triangle.branch")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = loadBalancer.name {
            if let safeIPv4 = loadBalancer.ipv4 {
                "\(safeName) (\(safeIPv4))"
            } else {
                safeName
            }
        } else {
            "Unknown"
        }
    }

    /// Open the metrics window for this Load Balancer. The app is a menu-bar accessory
    /// (`LSUIElement`), so it must be activated explicitly for the new window to come to the front.
    func showMetrics() {
        guard let safeID = loadBalancer.id else { return }

        let target = LoadBalancerMetricsTarget(projectUUID: project.id,
                                               customApiBaseUrl: project.customApiBaseUrl,
                                               loadBalancerId: safeID,
                                               name: loadBalancer.name ?? "Load Balancer",
                                               created: loadBalancer.created)
        openWindow(id: "lb-metrics", value: target)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openLoadBalancer(loadBalancerId: Int?) {
        openWebsite(webUrl: generateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                projectId: project.projectId,
                                                resourceName: "loadbalancers",
                                                resourceId: loadBalancerId))
    }
}
