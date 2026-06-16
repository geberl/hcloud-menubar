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
                     token: String,
                     queryItems: [URLQueryItem] = []) -> URLRequest?
{
    let baseUrl = customApiBaseUrl.isEmpty ? DefaultApiBaseUrl : customApiBaseUrl
    let urlString = "\(baseUrl)/\(resourceSuffix)"

    guard var components = URLComponents(string: urlString) else {
        logApi.error("buildURLRequest failed to create URL for \(urlString)")
        return nil
    }

    if !queryItems.isEmpty {
        components.queryItems = queryItems
    }

    guard let url = components.url else {
        logApi.error("buildURLRequest failed to build URL with query for \(urlString)")
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

/// Shared session reused for all resource list requests.
let hcloudURLSession = URLSession(configuration: .default)

/// Performs a GET and returns the response body on HTTP 200, or `nil` (logging the reason) on any
/// failure. Non-isolated `async`, so the network wait never blocks the main actor.
func fetchData(request: URLRequest) async -> Data? {
    do {
        let (data, response) = try await hcloudURLSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logApi.error("fetchData did not return a valid response")
            return nil
        }

        guard httpResponse.statusCode == 200 else {
            logApi.error("fetchData http response code: \(httpResponse.statusCode)")
            return nil
        }

        return data
    } catch {
        logApi.error("fetchData error: \(String(describing: error))")
        return nil
    }
}

/// A single decoded page of a resource list: the typed elements plus the cursor to the next
/// page (`nil` once the last page has been reached).
struct ResourcePage<T: HCloudResource> {
    let items: [T]
    let nextPage: Int?
}

/// Fetches and decodes a full resource list, following Hetzner's `meta.pagination.next_page`
/// cursor until it runs out. Both the network wait and the JSON decode run off the main actor
/// (this function is non-isolated); callers assign the result back on their own actor.
///
/// Hetzner paginates with a default of 25 items/page, so a single fetch would silently drop
/// everything past the first page. We request `ResourcesPerPage` items and accumulate pages up
/// to `ResourcesMaxPages` as a defensive cap; hitting the cap is logged.
func loadResources<T: HCloudResource>(customApiBaseUrl: String,
                                      resourceSuffix: String,
                                      timeout: Double,
                                      token: String) async -> [T]
{
    var items: [T] = []
    var page: Int? = 1
    var pagesFetched = 0

    while let currentPage = page {
        guard pagesFetched < ResourcesMaxPages else {
            logApi.error("loadResources hit the \(ResourcesMaxPages)-page cap for '\(resourceSuffix)'; some items may be missing")
            break
        }

        guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                            resourceSuffix: resourceSuffix,
                                            timeout: timeout,
                                            token: token,
                                            queryItems: [
                                                URLQueryItem(name: "page", value: String(currentPage)),
                                                URLQueryItem(name: "per_page", value: String(ResourcesPerPage)),
                                            ])
        else { return items }

        guard let data = await fetchData(request: request) else { return items }

        let decoded: ResourcePage<T> = decodeResourceList(from: data)
        items.append(contentsOf: decoded.items)
        page = decoded.nextPage
        pagesFetched += 1
    }

    return items
}

/// Decodes a Hetzner list response (`{ "<container>": [...], "meta": {...} }`) into typed resources.
///
/// The container key and type tag are read from the element type's static metadata. A single
/// `JSONSerialization` pass splits out the container array so each element's exact raw bytes can be
/// retained (pretty-printed) for the "Show JSON" feature; the typed fields are then decoded per
/// element with `JSONDecoder`. Elements that fail to decode are skipped and logged rather than
/// discarding the whole list. The `meta.pagination.next_page` cursor is read out alongside the
/// elements so the caller can follow it.
func decodeResourceList<T: HCloudResource>(from data: Data) -> ResourcePage<T> {
    let container = T.endpoint

    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        logJson.error("Error creating dictionary from json data")
        return ResourcePage(items: [], nextPage: nil)
    }

    // A JSON `null` decodes to NSNull, so `as? Int` cleanly yields nil on the last page.
    let nextPage = (root["meta"] as? [String: Any])
        .flatMap { $0["pagination"] as? [String: Any] }?["next_page"] as? Int

    guard let elements = root[container] as? [Any] else {
        logJson.error("Error getting '\(container)' array item from json")
        return ResourcePage(items: [], nextPage: nil)
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

    return ResourcePage(items: resources, nextPage: nextPage)
}
