import Foundation

// MARK: Common

func baseURL(customHetznerConsoleBaseUrl: String) -> String {
    if customHetznerConsoleBaseUrl != "" {
        return customHetznerConsoleBaseUrl
    }
    return DefaultHetznerConsoleBaseUrl
}

// MARK: Projects

func projectsURL() -> URL? {
    let baseURL = baseURL(customHetznerConsoleBaseUrl: "")
    let urlString = String(format: "\(baseURL)/projects/")
    return URL(string: urlString)
}

func projectURL(customHetznerConsoleBaseUrl: String, projectId: Int?) -> URL? {
    let baseURL = baseURL(customHetznerConsoleBaseUrl: customHetznerConsoleBaseUrl)

    if let safeProjectId = projectId {
        let urlString = String(format: "\(baseURL)/projects/%d", safeProjectId)
        return URL(string: urlString)
    }
    return nil
}

// MARK: Resources

func generateResourcesURL(customHetznerConsoleBaseUrl: String, projectId: Int?, resourceName: String) -> URL? {
    let baseURL = baseURL(customHetznerConsoleBaseUrl: customHetznerConsoleBaseUrl)
    if let safeProjectId = projectId {
        let urlString = String(format: "\(baseURL)/projects/%d/\(resourceName)", safeProjectId)
        return URL(string: urlString)
    }
    return nil
}

func generateResourceURL(customHetznerConsoleBaseUrl: String, projectId: Int?, resourceName: String, resourceId: Int?) -> URL? {
    let baseURL = baseURL(customHetznerConsoleBaseUrl: customHetznerConsoleBaseUrl)
    if let safeProjectId = projectId {
        if let safeResourceId = resourceId {
            let urlString = String(format: "\(baseURL)/projects/%d/\(resourceName)/%d", safeProjectId, safeResourceId)
            return URL(string: urlString)
        }
    }
    return nil
}

func generateCreateResourceURL(customHetznerConsoleBaseUrl: String, projectId: Int?, resourceName: String) -> URL? {
    let baseURL = baseURL(customHetznerConsoleBaseUrl: customHetznerConsoleBaseUrl)
    if let safeProjectId = projectId {
        let urlString = String(format: "\(baseURL)/projects/%d/\(resourceName)/create", safeProjectId)
        return URL(string: urlString)
    }
    return nil
}
