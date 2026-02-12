import SwiftUI

struct AboutSettingsView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private var buildDate: String {
        // Push in Info.plist manually.
        if let infoDict = Bundle.main.infoDictionary,
           let buildDateString = infoDict["BuildDate"] as? String
        {
            return buildDateString
        }
        return "Unknown"
    }

    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 128, height: 128)
                .cornerRadius(22) // macOS app icon corner radius
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            Text("HCloud Menubar")
                .font(.system(size: 24, weight: .semibold))

            VStack(spacing: 4) {
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text("Built on \(buildDate)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.up.forward.square")
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        Text("Source Code")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("View on GitHub") {
                            if let url = URL(string: "https://github.com/geberl/hcloud-menubar") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        Text("Contributors")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Show Graph") {
                            if let url = URL(string: "https://github.com/geberl/hcloud-menubar/graphs/contributors") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        Text("Documentation")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Open README") {
                            if let url = URL(string: "https://github.com/geberl/hcloud-menubar#readme") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        Text("License")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("MIT") {
                            if let url = URL(string: "https://github.com/geberl/hcloud-menubar/blob/main/LICENSE") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
                .padding(8)
            }
            .frame(maxWidth: 450)

            Spacer()

            Text("© 2026 Günther Eberl")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(height: 520)
    }
}

#Preview {
    AboutSettingsView()
}
