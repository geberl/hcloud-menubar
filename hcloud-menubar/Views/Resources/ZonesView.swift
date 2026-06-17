import SwiftUI

struct ZonesView: View {
    var project: Project
    @EnvironmentObject var zones: Zones

    var body: some View {
        Menu {
            switch zones.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if zones.items.count > 0 {
                    ForEach(zones.items) { zone in
                        ZoneMenuItem(project: project, zone: zone)
                    }
                } else {
                    Button("No Zones", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("View Zones", action: { openZones() })
            Divider()
            Button("Reload", action: { reloadZones() })
        } label: {
            Label("DNS", systemImage: "signpost.right.fill")
                .labelStyle(.titleAndIcon)
        }
    }

    func openZones() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "dns"))
    }

    func reloadZones() {
        zones.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }
}

struct ZoneMenuItem: View {
    var project: Project
    var zone: Zone

    var body: some View {
        Menu {
            if let safeID = zone.id {
                Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
            }
            if let safeName = zone.name {
                Button("Copy Name", action: { copyToClipboard(content: safeName) })
            }
            Divider()
            Button("Show JSON", action: { openJsonInEditor(resource: zone) })
            Divider()
            Button("View Zone", action: { openZone(zoneId: zone.id) })
        } label: {
            Label(getTitle(), systemImage: "signpost.right.fill")
                .labelStyle(.titleAndIcon)
        }
    }

    func getTitle() -> String {
        if let safeName = zone.name {
            safeName
        } else {
            "Unknown"
        }
    }

    func openZone(zoneId: Int?) {
        openWebsite(webUrl: generateResourceURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                projectId: project.projectId,
                                                resourceName: "dns",
                                                resourceId: zoneId))
    }
}
