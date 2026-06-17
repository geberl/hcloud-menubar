import SwiftData
import SwiftUI

struct ProjectsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name, order: .forward) private var projects: [Project]
    @State private var selectedProject: Project?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack {
                List(selection: $selectedProject) {
                    ForEach(projects) { project in
                        Label(
                            project.name,
                            systemImage: project.customApiBaseUrl == DefaultApiBaseUrl ? "cloud.fill" : "cloud"
                        )
                        .tag(project)
                    }
                }

                HStack {
                    Button(action: addNewProject) {
                        Image(systemName: "plus")
                            .frame(width: 55, height: 18)
                    }
                    .buttonStyle(.bordered)
                    .help("Add project")
                    .accessibilityLabel("Add project")
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "minus")
                            .frame(width: 55, height: 18)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedProject == nil)
                    .help("Delete selected project")
                    .accessibilityLabel("Delete selected project")
                }
                .padding()
            }
            .frame(width: SettingsProjectsSidebarWidth)

            Divider()

            // Detail view
            if let index = projects.firstIndex(where: { $0.id == selectedProject?.id }) {
                ProjectDetailView(project: projects[index])
                    .id(projects[index].id)
            } else {
                Text("No Selection")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: SettingsWindowWidth, height: SettingsProjectsHeight)
        .confirmationDialog(
            "Are you sure you want to delete the Project \"\(selectedProject?.name ?? "")\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedProject()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func addNewProject() {
        let newProject = Project(
            id: UUID(),
            projectId: 0,
            name: "New Project",
            token: "",
            permissions: PermissionReadOnly,
            refreshOnStartup: false,
            customApiBaseUrl: DefaultApiBaseUrl,
            customHetznerConsoleBaseUrl: DefaultHetznerConsoleBaseUrl
        )
        modelContext.insert(newProject)

        do {
            try modelContext.save()
        } catch {
            logGeneral.error("Failed to save new project: \(error)")
        }

        // Select the newly created project
        selectedProject = newProject
    }

    private func deleteSelectedProject() {
        guard let selectedProject else { return }
        KeychainTokenStore.delete(for: selectedProject.id)
        modelContext.delete(selectedProject)

        do {
            try modelContext.save()
        } catch {
            logGeneral.error("Failed to delete project: \(error)")
        }

        // Clear selection after deletion
        self.selectedProject = nil
    }
}

#Preview {
    ProjectsSettingsView()
        .modelContainer(for: Project.self, inMemory: true)
}
