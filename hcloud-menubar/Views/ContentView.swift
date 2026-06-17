import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Project.name, order: .forward) private var projects: [Project]

    var body: some View {
        if projects.isEmpty {
            Text("No projects yet")
            SettingsLink(label: {
                Label("Add your first project…", systemImage: "plus")
            })
        } else {
            ForEach(projects) { project in
                ProjectView(project: project)
            }
        }
        Divider()
        Button("View Projects", action: { openProjects() })
        Divider()
        SettingsLink(label: {
            Label("Settings…", systemImage: "gearshape")
        })
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }

    func openProjects() {
        openWebsite(webUrl: projectsURL())
    }
}
