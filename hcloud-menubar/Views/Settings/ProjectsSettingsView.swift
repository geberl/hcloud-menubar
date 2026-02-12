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
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "minus")
                            .frame(width: 55, height: 18)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedProject == nil)
                }
                .padding()
            }
            .frame(width: 200)

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
        .frame(width: 625, height: 535)
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
            permissions: 0,
            refreshOnStartup: false,
            customApiBaseUrl: DefaultApiBaseUrl,
            customHetznerConsoleBaseUrl: DefaultHetznerConsoleBaseUrl
        )
        modelContext.insert(newProject)

        try? modelContext.save()

        // Select the newly created project
        selectedProject = newProject
    }

    private func deleteSelectedProject() {
        guard let selectedProject else { return }
        modelContext.delete(selectedProject)

        try? modelContext.save()

        // Clear selection after deletion
        self.selectedProject = nil
    }
}

#Preview {
    ProjectsSettingsView()
        .modelContainer(for: Project.self, inMemory: true)
}
