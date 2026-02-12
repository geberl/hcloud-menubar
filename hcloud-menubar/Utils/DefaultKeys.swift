import Foundation
import SwiftData
import SwiftUI

enum ProjectSeeder {
    static func seedDefaultProjects(into context: ModelContext) {
        let defaultProjects = [
            Project(id: UUID(),
                    projectId: 123,
                    name: "Production",
                    token: "foo",
                    permissions: 0,
                    refreshOnStartup: false,
                    customApiBaseUrl: DefaultApiBaseUrl,
                    customHetznerConsoleBaseUrl: DefaultHetznerConsoleBaseUrl),
            Project(id: UUID(),
                    projectId: 456,
                    name: "Staging",
                    token: "bar",
                    permissions: 1,
                    refreshOnStartup: false,
                    customApiBaseUrl: "https://api.hetzner-staging.cloud/v1",
                    customHetznerConsoleBaseUrl: "https://console.hetzner-staging.com/"),
        ]

        for project in defaultProjects {
            context.insert(project)
        }

        do {
            try context.save()
            logGeneral.info("Seeded \(defaultProjects.count) default projects")
        } catch {
            logGeneral.error("Failed to seed default projects: \(error)")
        }
    }
}

@Observable
final class AppSettings: @unchecked Sendable {
    // @Observable makes the class reference-mutable, which normally conflicts with Sendable
    // @unchecked Sendable tells the compiler "trust me, I'm handling concurrency correctly"
    // Since it's a singleton accessed via shared, and SwiftUI's @Observable handles observation safely, this is appropriate

    static let shared = AppSettings()

    var appTerminal: String {
        didSet { UserDefaults.standard.set(appTerminal, forKey: AppSettingsTerminal) }
    }

    var appEditor: String {
        didSet { UserDefaults.standard.set(appEditor, forKey: AppSettingsEditor) }
    }

    var timeoutSeconds: Double {
        didSet { UserDefaults.standard.set(timeoutSeconds, forKey: AppSettingsTimeout) }
    }

    private init() {
        appTerminal = UserDefaults.standard.string(forKey: AppSettingsTerminal) ?? TerminalDefault
        appEditor = UserDefaults.standard.string(forKey: AppSettingsEditor) ?? EditorDefault
        timeoutSeconds = UserDefaults.standard.object(forKey: AppSettingsTimeout) as? Double ?? TimeoutDefault
    }

    func resetToDefaults() {
        appTerminal = TerminalDefault
        appEditor = EditorDefault
        timeoutSeconds = TimeoutDefault
    }
}
