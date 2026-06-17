import os.log
import SwiftData
import SwiftUI

private let logSubsystem = Bundle.main.bundleIdentifier ?? "se.eberl.hcloud-menubar"

let logGeneral = Logger(subsystem: logSubsystem, category: "general")
let logApi = Logger(subsystem: logSubsystem, category: "api")
let logJson = Logger(subsystem: logSubsystem, category: "json")
let logUi = Logger(subsystem: logSubsystem, category: "ui")

@main
struct hcloudMenubarApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Project.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(container)
        }

        MenuBarExtra {
            ContentView()
                .modelContainer(container)
        } label: {
            Label {
                Text("HCloud Menubar")
            } icon: {
                Image("MenuBarIcon")
                    .renderingMode(.template)
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
