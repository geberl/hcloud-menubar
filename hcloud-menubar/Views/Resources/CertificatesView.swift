import SwiftUI

struct CertificatesView: View {
    var project: Project
    @EnvironmentObject var certificates: Certificates

    var body: some View {
        Menu {
            switch certificates.loadState {
            case .idle:
                Button("Not Loaded", action: {}).disabled(true)
            case .loading:
                Button("Loading…", action: {}).disabled(true)
            case .loaded:
                if certificates.items.count > 0 {
                    ForEach(certificates.items) { certificate in
                        CertificateMenuItem(project: project, certificate: certificate)
                    }
                } else {
                    Button("No Certificates", action: {}).disabled(true)
                }
            case let .failed(error):
                Button(error.menuDescription, action: {}).disabled(true)
            }
            Divider()
            Button("View Certificates", action: { openCertificates() })
            Divider()
            Button("Reload", action: { reloadCertificates() })
        } label: {
            Label("Certificates", systemImage: "shield.fill")
                .labelStyle(.titleAndIcon)
        }
    }

    func openCertificates() {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "security/certificates"))
    }

    func reloadCertificates() {
        certificates.reload(customApiBaseUrl: project.customApiBaseUrl, token: project.token)
    }
}

struct CertificateMenuItem: View {
    var project: Project
    var certificate: Certificate

    var body: some View {
        if !certificate.hidden() {
            Menu {
                if let safeID = certificate.id {
                    Button("Copy ID", action: { copyToClipboard(content: String(safeID)) })
                }
                if let safeName = certificate.name {
                    Button("Copy Name", action: { copyToClipboard(content: safeName) })
                }
                if let safeFingerprint = certificate.fingerprint {
                    Button("Copy Fingerprint", action: { copyToClipboard(content: safeFingerprint) })
                }
                if let safePublicKey = certificate.publicKey {
                    Button("Copy PEM", action: { copyToClipboard(content: safePublicKey) })
                }
                Divider()
                Button("Show JSON", action: { openJsonInEditor(resource: certificate) })
                Divider()
                Button("View Certificate", action: { openCertificate(certificateId: certificate.id) })
            } label: {
                Label(getTitle(), systemImage: "shield.fill")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    func getTitle() -> String {
        if let safeName = certificate.name {
            safeName
        } else {
            "Unknown"
        }
    }

    func openCertificate(certificateId: Int?) {
        openWebsite(webUrl: generateResourcesURL(customHetznerConsoleBaseUrl: project.customHetznerConsoleBaseUrl,
                                                 projectId: project.projectId,
                                                 resourceName: "security/certificates"))
    }
}
