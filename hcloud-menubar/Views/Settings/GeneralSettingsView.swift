import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var settings = settings

        VStack {
            Form {
                Section {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            updateLaunchAtLogin(enabled: newValue)
                        }
                } header: {
                    Text("Behavior")
                }

                Section {
                    Picker("Terminal", selection: $settings.appTerminal) {
                        ForEach(TerminalValues.sorted(by: <), id: \.key) { name, bundleId in
                            Text(name).tag(bundleId)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Editor", selection: $settings.appEditor) {
                        ForEach(EditorValues.sorted(by: <), id: \.key) { name, bundleId in
                            Text(name).tag(bundleId)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Applications")
                } footer: {
                    Text("Terminal is used when starting SSH sessions. Editor is used when showing resource JSON.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                Section {
                    HStack {
                        Text("API timeout")
                        Spacer()
                        TextField("", value: $settings.timeoutSeconds, formatter: NumberFormatter())
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Stepper("", value: $settings.timeoutSeconds, in: 1 ... 60)
                            .labelsHidden()
                        Text("seconds")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Network")
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            // Reload after tab switch, to not hang on old state when settings reset was triggered
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .frame(width: SettingsGeneralWidth)
        .frame(height: 400)
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            // Handle cases where registration fails (e.g., app is not in /Applications)
            print("Error: \(error.localizedDescription)")
            launchAtLogin = service.status == .enabled
        }
    }
}

#Preview {
    GeneralSettingsView()
}
