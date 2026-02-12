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

    func testToken() async -> Bool {
        let resourceRequest = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                              resourceSuffix: "datacenters",
                                              timeout: AppSettings.shared.timeoutSeconds,
                                              token: token)

        if let safeResourceRequest = resourceRequest {
            return await withCheckedContinuation { continuation in
                let urlSession = URLSession(configuration: URLSessionConfiguration.default)

                let task = urlSession.dataTask(with: safeResourceRequest) { _, response, error in
                    guard error == nil else {
                        logApi.error("testToken error: \(String(describing: error))")
                        continuation.resume(returning: false)
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        logApi.error("testToken did not return a valid response")
                        continuation.resume(returning: false)
                        return
                    }

                    logApi.debug("testToken http response code \(httpResponse.statusCode)")

                    let success = httpResponse.statusCode == 200
                    continuation.resume(returning: success)
                }

                task.resume()
            }
        }
        return false
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
            permissions: 0,
            refreshOnStartup: true,
            customApiBaseUrl: "https://api.hetzner.cloud/v1",
            customHetznerConsoleBaseUrl: "https://console.hetzner.cloud"
        )
    }
}
