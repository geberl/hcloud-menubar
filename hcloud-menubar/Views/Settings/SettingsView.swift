import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            ProjectsSettingsView()
                .tabItem {
                    Label("Projects", systemImage: "key")
                }
            LabelsSettingsView()
                .tabItem {
                    Label("Labels", systemImage: "tag")
                }
            DebugSettingsView()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: SettingsWindowWidth)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(AppSettings.shared)
    }
}
