import SwiftUI

struct SettingsView: View {
    @State private var appSettings = AppSettings.shared

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .environment(appSettings)
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
        .frame(width: 625)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
