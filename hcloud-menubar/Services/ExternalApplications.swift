import Cocoa

func openWebsite(webUrl: URL?) {
    // This uses whatever browser the user has set in Preferences -> General -> Default Web Browser
    if let url = webUrl, NSWorkspace.shared.open(url) {
        logUi.debug("openWebsite: Successfully opened '\(url.absoluteString)'")
    } else {
        logUi.debug("openWebsite: Not a valid URL")
    }
}

func dumpResourceJson(resourceName: String, resourceId: Int, json: Data) -> URL {
    let fileName = "\(resourceName)_\(resourceId).json"
    let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

    FileManager.default.createFile(atPath: fileUrl.path, contents: json, attributes: nil)

    return fileUrl
}

func openJsonInEditor(resource: any HCloudResource) {
    let appEditor = AppSettings.shared.appEditor

    if let safeResourceType = resource.resType {
        if let safeResourceId = resource.id {
            if let safeJsonData = resource.jsonData {
                let tempFileUrl = dumpResourceJson(resourceName: safeResourceType,
                                                   resourceId: safeResourceId,
                                                   json: safeJsonData)
                openUrlInApp(url: tempFileUrl, app: appEditor)
            } else {
                logUi.error("openJsonInEditor: Unable to create temp json file")
            }
        } else {
            logUi.error("openJsonInEditor: Resource has no id")
        }
    } else {
        logUi.error("openJsonInEditor: Resource has no resourceType")
    }
}

func openUrlInApp(url: URL, app: String) {
    if let safeAppUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.environment = [:]
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        configuration.hides = false

        NSWorkspace.shared.open([url], withApplicationAt: safeAppUrl, configuration: configuration)
    } else {
        logUi.error("openUrlInApp: Unable to open URL '\(url.path)' in '\(app)'")
    }
}

func openUrlInAssociatedApp(url: URL) {
    NSWorkspace.shared.open(url)
}

func startSshViaCommand(bundleIdentifier: String, command: String) {
    // All of this does not work if the app is sandboxed. Approach taken from:
    // https://github.com/PostgresApp/PostgresApp/blob/master/Postgres/ClientLauncher.swift

    guard let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
        logUi.error("Unable to find app")
        return
    }

    let tempDir = FileManager.default.temporaryDirectory
    let commandUrl = tempDir.appendingPathComponent("ssh-\(UUID().uuidString).command")

    do {
        try command.write(to: commandUrl, atomically: false, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: commandUrl.path)

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        Task {
            do {
                if bundleIdentifier == "com.github.wez.wezterm" {
                    // Opening shell scripts seems to work only if the app is already open, so open it first
                    try await NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration())
                }
                try await NSWorkspace.shared.open([commandUrl], withApplicationAt: appUrl, configuration: configuration)
                logUi.info("Launched app with SSH command")
            } catch {
                logUi.error("Failed to open command file: \(error.localizedDescription)")
            }
        }
    } catch {
        logUi.error("Failed to create command file: \(error.localizedDescription)")
    }
}
