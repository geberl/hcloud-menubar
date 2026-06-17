import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var projectId: Int
    var name: String
    var token: String
    var permissions: Int
    var refreshOnStartup: Bool
    var customApiBaseUrl: String
    var customHetznerConsoleBaseUrl: String
    var working: Bool? // true = working, false = error 401, nil = not yet checked

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
        self.token = token
        self.permissions = permissions
        self.refreshOnStartup = refreshOnStartup
        self.customApiBaseUrl = customApiBaseUrl
        self.customHetznerConsoleBaseUrl = customHetznerConsoleBaseUrl
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
            token: "preview_token",
            permissions: PermissionReadOnly,
            refreshOnStartup: true,
            customApiBaseUrl: "https://api.hetzner.cloud/v1",
            customHetznerConsoleBaseUrl: "https://console.hetzner.cloud"
        )
    }
}
