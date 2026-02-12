import SwiftUI

struct LabelsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Introduction
            Text("Labels on resources control certain **HCloud Menubar** functionality.\nManage your labels via the **Hetzner Console**.")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            // All Resources Section
            VStack(alignment: .leading, spacing: 12) {
                Text("All Resources")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 6) {
                    LabelPill(key: labelHide, value: "true")
                    Text("Do not show this resource in any menus. Defaults to **show resource** if not set.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Servers Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Servers")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 6) {
                    LabelPill(key: labelSSHUser, value: "pi")
                    Text("Username to use when starting a ssh session to the server. Value must not contain spaces. Defaults to username **root** if not set.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    LabelPill(key: labelSSHHost, value: "example.com")
                    Text("Hostname to use when starting a ssh session to the server. Value must not contain spaces. Defaults to the server's public **IPv4** if not set.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    LabelPill(key: labelSSHPort, value: "2222")
                    Text("Port to use when starting a SSH session to the server. Value must be a number 1-65535. Defaults to **22** if not set.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(width: 450)
        .frame(height: 530)
    }
}

struct LabelPill: View {
    let key: String
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            // Key part - white text on red background
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.hcloudRed)

            // Value part - red text on white background
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.hcloudRed)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.hcloudRed, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    LabelsSettingsView()
}
