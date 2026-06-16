import Foundation

func userAgent() -> String {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    return "hcloud-menubar/\(appVersion) (macOS \(versionString))"
}

func buildURLRequest(customApiBaseUrl: String,
                     resourceSuffix: String,
                     timeout: Double,
                     token: String) -> URLRequest?
{
    let baseUrl = customApiBaseUrl.isEmpty ? DefaultApiBaseUrl : customApiBaseUrl
    let urlString = "\(baseUrl)/\(resourceSuffix)"

    guard let url = URL(string: urlString) else {
        logApi.error("buildURLRequest failed to create URL for \(urlString)")
        return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = timeout
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(userAgent(), forHTTPHeaderField: "User-Agent")

    return request
}

func startDataTask(request: URLRequest, onData: @escaping (Data) -> Void) {
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)

    let task = urlSession.dataTask(with: request as URLRequest) { data, response, error in
        guard error == nil else {
            logApi.error("startDataTask error: \(String(describing: error))")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            logApi.error("startDataTask did not return a valid response")
            return
        }

        switch httpResponse.statusCode {
        case 200:
            guard let saveData = data else {
                logApi.error("startDataTask http response error: Did not contain any data")
                return
            }
            onData(saveData)
        default:
            logApi.error("startDataTask http response code: \(httpResponse.statusCode)")
        }
    }

    task.resume()
}

/// Decodes a Hetzner list response (`{ "<container>": [...], "meta": {...} }`) into typed resources.
///
/// The container key and type tag are read from the element type's static metadata. A single
/// `JSONSerialization` pass splits out the container array so each element's exact raw bytes can be
/// retained (pretty-printed) for the "Show JSON" feature; the typed fields are then decoded per
/// element with `JSONDecoder`. Elements that fail to decode are skipped and logged rather than
/// discarding the whole list.
func decodeResourceList<T: HCloudResource>(from data: Data) -> [T] {
    let container = T.endpoint

    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        logJson.error("Error creating dictionary from json data")
        return []
    }

    guard let elements = root[container] as? [Any] else {
        logJson.error("Error getting '\(container)' array item from json")
        return []
    }

    let decoder = JSONDecoder()
    var resources: [T] = []

    for element in elements {
        guard let itemData = try? JSONSerialization.data(withJSONObject: element, options: .prettyPrinted) else {
            logJson.error("Error serializing '\(container)' element")
            continue
        }

        do {
            var resource = try decoder.decode(T.self, from: itemData)
            resource.resType = T.resourceType
            resource.jsonData = itemData
            resources.append(resource)
        } catch {
            logJson.error("Error decoding '\(container)' element: \(String(describing: error))")
        }
    }

    return resources
}
