import Foundation

class Resource: Identifiable {
    var resType: String?
    var jsonData: Data?

    var id: Int?
    var name: String?
    var created: String?
    var labels: [String: String] = [:]

    init(fromDict dict: NSDictionary, as resType: String) {
        self.resType = resType
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        } catch {
            logJson.error("Resource Json Serialization error: \(String(describing: error))")
        }

        if let id = dict["id"] as? Int { self.id = id }
        if let name = dict["name"] as? String { self.name = name }
        if let created = dict["created"] as? String { self.created = created }

        if let labels = dict["labels"] as? [String: String] {
            for (key, value) in labels {
                self.labels[key] = value
            }
        }
    }

    func hidden() -> Bool {
        labels.contains { $0.key == labelHide && LabelBoolsPositive.contains($0.value) }
    }
}
