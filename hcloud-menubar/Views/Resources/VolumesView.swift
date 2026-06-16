import SwiftUI

struct VolumesView: View {
    var project: Project
    @EnvironmentObject var volumes: Volumes

    var body: some View {
        Menu {
            switch volumes.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if volumes.items.count > 0 {
                    ForEach(volumes.items) { volume in
                        VolumeMenuItem(project: project, volume: volume)
                    }
                } else {
                    Button("No Volumes", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("View Volumes", action: { openVolumes() })
            Divider()
            Button("Reload", action: { reloadVolumes() })
        }
        label: {
            Label("Volumes", systemImage: "cube")
                .labelStyle(.titleAndIcon)
        }
    }

    func reloadVolumes() {
        volumes.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }

    func openVolumes() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "volumes"))
    }
}

struct VolumeMenuItem: View {
    var project: Project
    var volume: Volume

    var body: some View {
        if !volume.hidden() {
            Menu {
                if let safeID = volume.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = volume.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: volume) })
                Divider()
                Button("View Volume", action: { openVolumes() })
            } label: {
                Label(getTitle(), systemImage: "cube")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = volume.name {
            safeName
        } else {
            "Unknown"
        }
    }

    func openVolumes() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "volumes"))
    }
}
