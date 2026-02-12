import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Project.name, order: .forward) private var projects: [Project]

    var body: some View {
        ForEach(projects) { project in
            ProjectView(project: project)
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
