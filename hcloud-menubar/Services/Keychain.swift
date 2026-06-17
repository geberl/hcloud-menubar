import Foundation
import Security
import SwiftData

/// One-time cleanup for the pre-Keychain era, when API tokens were persisted in plaintext as a
/// SwiftData attribute. Simply removing the attribute would drop it from the schema but leave the
/// secret bytes lingering in the SQLite file until its pages were reused — so on first launch of
/// this version we delete the store outright. Projects (and tokens) are re-entered afterwards;
/// fresh installs see an empty store either way, so this is a harmless no-op for them.
func purgeLegacyPlaintextTokenStoreIfNeeded() {
    let flagKey = "didPurgeLegacyPlaintextTokenStore"
    guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
    defer { UserDefaults.standard.set(true, forKey: flagKey) }

    let storeURL = ModelConfiguration().url
    let directory = storeURL.deletingLastPathComponent()
    let name = storeURL.lastPathComponent

    // SwiftData/SQLite keeps sidecar files next to the main store; remove them too.
    let urls = [name, "\(name)-shm", "\(name)-wal"].map { directory.appending(path: $0) }
    let fileManager = FileManager.default

    for url in urls where fileManager.fileExists(atPath: url.path) {
        do {
            try fileManager.removeItem(at: url)
            logGeneral.info("Purged legacy plaintext token store file: \(url.lastPathComponent)")
        } catch {
            logGeneral.error("Failed to purge legacy store file \(url.lastPathComponent): \(error)")
        }
    }
}

/// Stores Hetzner API tokens in the macOS Keychain as generic-password items, keyed by the owning
/// `Project`'s stable UUID. The SwiftData model persists everything *except* the secret; the token
/// is read lazily from here whenever a request is built or tested, and removed when the project is
/// deleted. The app is not sandboxed, so it accesses its own keychain items without an access group.
enum KeychainTokenStore {
    /// Service string namespacing our items within the keychain.
    private static let service = "se.eberl.hcloud-menubar.token"

    /// Reads the token for a project, returning "" when none is stored. The empty-string default
    /// matches the previous SwiftData behaviour, so bindings and call sites are unaffected.
    static func read(for projectID: UUID) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: projectID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                logGeneral.error("Keychain read failed (status \(status))")
            }
            return ""
        }

        guard let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
            return ""
        }
        return token
    }

    /// Inserts or updates the token for a project. An empty token deletes the item so we never
    /// leave a stale secret behind.
    static func write(_ token: String, for projectID: UUID) {
        guard !token.isEmpty else {
            delete(for: projectID)
            return
        }

        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: projectID.uuidString,
        ]

        let status = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            var attributes = query
            attributes[kSecValueData as String] = data
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            if addStatus != errSecSuccess {
                logGeneral.error("Keychain add failed (status \(addStatus))")
            }
        default:
            logGeneral.error("Keychain update failed (status \(status))")
        }
    }

    /// Removes the token for a project. Safe to call when nothing is stored.
    static func delete(for projectID: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: projectID.uuidString,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess, status != errSecItemNotFound {
            logGeneral.error("Keychain delete failed (status \(status))")
        }
    }
}
