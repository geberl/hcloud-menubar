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
        // Tokens used to be persisted in plaintext by SwiftData. Before opening the store, wipe any
        // legacy store file once so those plaintext bytes are gone from disk; tokens now live only
        // in the Keychain and projects are re-entered after the upgrade.
        purgeLegacyPlaintextTokenStoreIfNeeded()

        do {
            container = try ModelContainer(for: Project.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        sweepStaleSSHCommandFiles()
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .modelContainer(container)
                .environment(AppSettings.shared)
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

        // Per–Load Balancer metrics window. `WindowGroup(for:)` reuses the window for an identical
        // target, so re-opening the same Load Balancer focuses its window instead of duplicating it.
        WindowGroup(id: "lb-metrics", for: LoadBalancerMetricsTarget.self) { $target in
            if let target {
                LoadBalancerMetricsView(target: target)
            }
        }
        .windowResizability(.contentSize)
    }
}
