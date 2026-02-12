import SwiftUI

struct ProjectDetailView: View {
    @Bindable var project: Project
    @State private var isTokenVisible = false
    @State private var isTesting = false
    @State private var testResult: Bool?

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $project.name)
                Text("Usually the project name as shown in the Hetzner Console.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("But can be anything.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 15)
            }

            Section {
                TextField("Project ID", text: Binding(
                    get: { String(project.projectId) },
                    set: { project.projectId = Int($0) ?? 0 }
                ))
                Text("Numeric Hetzner Cloud project ID. Used to generate links.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 15)
            }

            Section {
                HStack {
                    if isTokenVisible {
                        TextField("API Token", text: $project.token)
                    } else {
                        SecureField("API Token", text: $project.token)
                    }

                    Button(action: { isTokenVisible.toggle() }) {
                        Image(systemName: isTokenVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(isTokenVisible ? "Hide token" : "Show token")
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate and manage your tokens in the Hetzner Console at")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Security → API tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 15)
            }

            Section {
                Picker("Permissions", selection: $project.permissions) {
                    ForEach(PermissionsValues.sorted(by: >), id: \.key) { number, name in
                        Text(name).tag(number)
                    }
                }
                Text("Note token permissions. For now read-only is enough.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 15)
            }

            Section {
                LabeledContent("On Startup") {
                    Toggle("Refresh", isOn: $project.refreshOnStartup)
                }
                .padding(.bottom, 4)
                Text("Fetch all of the project's resources when the app starts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 15)
            }

            Section {
                LabeledContent("API Base URL") {
                    HStack {
                        TextField("", text: $project.customApiBaseUrl)
                        Button("Reset") {
                            project.customApiBaseUrl = DefaultApiBaseUrl
                        }
                    }
                }
                Text("Only change if you know what you're doing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 15)
            }

            Section {
                LabeledContent("Console URL") {
                    HStack {
                        TextField("", text: $project.customHetznerConsoleBaseUrl)
                        Button("Reset") {
                            project.customHetznerConsoleBaseUrl = DefaultHetznerConsoleBaseUrl
                        }
                    }
                }
                Text("Only change if you know what you're doing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 15)
            }

            Section {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: testResult == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(testResult == true ? .green : .red)
                        Text(testResult == true ? "Connection successful" : "Connection failed")
                            .font(.caption)
                    }
                    .opacity(testResult == nil ? 0 : 1)

                    Button(action: {
                        Task {
                            isTesting = true
                            testResult = nil
                            let success = await project.testToken()
                            testResult = success
                            isTesting = false
                        }
                    }) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text(isTesting ? "Testing..." : "Test Settings")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTesting)
                }
            }
        }
        .onAppear {
            isTesting = false
            testResult = nil
        }
        .padding()
        .frame(width: 425)
    }
}

#Preview {
    ProjectDetailViewPreview()
}

private struct ProjectDetailViewPreview: View {
    @State private var project = Project.preview

    var body: some View {
        ProjectDetailView(project: project())
            .padding()
            .modelContainer(for: Project.self, inMemory: true)
    }
}
