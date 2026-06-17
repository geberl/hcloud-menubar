import Foundation
import SwiftData
import SwiftUI

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
