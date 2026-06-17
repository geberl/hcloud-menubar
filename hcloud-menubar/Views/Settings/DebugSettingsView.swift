import ServiceManagement
import SwiftData
import SwiftUI

struct DebugSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name, order: .forward) private var projects: [Project]
    @State private var showingResetAlert = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        Text("Application Logs")
                            .font(.title3)
                    }

                    Text("HCloud Menubar uses macOS Unified Logging to log important events and errors. You can view these logs using Console.app.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    HStack {
                        Text("Log subsystem:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("se.eberl.hcloud-menubar")
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                        Spacer()
                    }

                    Button("Open Console.app") {
                        openConsoleApp()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(12)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text("Reset Settings")
                            .font(.title3)
                    }

                    Text("Reset all settings to their default values. Your projects and API tokens will be removed. This action cannot be undone.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    Button("Reset All Settings…") {
                        showingResetAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(12)
            }
            .alert("Reset All Settings?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllSettings()
                }
            } message: {
                Text("This will reset all settings to defaults and remove all projects and API tokens. This action cannot be undone.")
            }
        }
        .frame(width: SettingsDebugWidth)
        .frame(height: 380)
    }

    private func openConsoleApp() {
        let consoleURL = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        NSWorkspace.shared.open(consoleURL)
    }

    private func resetAllSettings() {
        // Delete all existing projects
        for project in projects {
            modelContext.delete(project)
        }

        // Save the deletions
        try? modelContext.save()

        // Reset app settings
        AppSettings.shared.resetToDefaults()

        // Unregister launch at login
        let service = SMAppService.mainApp
        do {
            try service.unregister()
        } catch {
            // Handle cases where registration fails (e.g., app is not in /Applications)
            print("Error: \(error.localizedDescription)")
        }

        logGeneral.info("All settings have been reset")
    }
}

#Preview {
    DebugSettingsView()
        .modelContainer(for: Project.self, inMemory: true)
}
