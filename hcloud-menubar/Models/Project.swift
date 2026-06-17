import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var projectId: Int
    var name: String
    var permissions: Int
    var refreshOnStartup: Bool
    var customApiBaseUrl: String
    var customHetznerConsoleBaseUrl: String
    var working: Bool? // true = working, false = error 401, nil = not yet checked

    /// The Hetzner API token. Deliberately *not* a SwiftData attribute: the secret lives in the
    /// Keychain (keyed by `id`) and is read lazily on each access, written through on assignment.
    /// An empty string means no token is stored. Delete the Keychain item when the project is
    /// removed — see `ProjectsSettingsView.deleteSelectedProject()`.
    var token: String {
        get { KeychainTokenStore.read(for: id) }
        set { KeychainTokenStore.write(newValue, for: id) }
    }

    init(id: UUID = UUID(),
         projectId: Int,
         name: String,
         token: String,
         permissions: Int,
         refreshOnStartup: Bool,
         customApiBaseUrl: String,
         customHetznerConsoleBaseUrl: String)
    {
        self.id = id
        self.projectId = projectId
        self.name = name
        self.permissions = permissions
        self.refreshOnStartup = refreshOnStartup
        self.customApiBaseUrl = customApiBaseUrl
        self.customHetznerConsoleBaseUrl = customHetznerConsoleBaseUrl
        self.token = token // writes through to the Keychain
    }

    /// Validates the token against the lightweight `datacenters` endpoint, returning the mapped
    /// `HCloudError` on failure so the settings test button can explain *why* it failed.
    func testToken() async -> Result<Void, HCloudError> {
        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: "datacenters",
                                            timeout: AppSettings.shared.timeoutSeconds,
                                            token: token)
        else { return .failure(.network) }

        return await fetchData(request: request).map { _ in () }
    }
}

/// preview fixture for SwiftUI
extension Project {
    static func preview() -> Project {
        Project(
            id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!,
            projectId: 123_456,
            name: "Hetzner Demo Project",
            token: "",
            permissions: PermissionReadOnly,
            refreshOnStartup: true,
            customApiBaseUrl: "https://api.hetzner.cloud/v1",
            customHetznerConsoleBaseUrl: "https://console.hetzner.cloud"
        )
    }
}
