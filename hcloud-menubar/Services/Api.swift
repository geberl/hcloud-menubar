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

/// Performs a GET and returns the response body on HTTP 200, or a mapped `HCloudError` (logging the
/// reason) on any failure. Non-isolated `async`, so the network wait never blocks the main actor.
func fetchData(request: URLRequest) async -> Result<Data, HCloudError> {
    do {
        let (data, response) = try await hcloudURLSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logApi.error("fetchData did not return a valid response")
            return .failure(.network)
        }

        switch httpResponse.statusCode {
        case 200:
            return .success(data)
        case 401:
            logApi.error("fetchData http response code: 401 (unauthorized)")
            return .failure(.auth)
        case 429:
            logApi.error("fetchData http response code: 429 (rate limited)")
            return .failure(.rateLimited)
        case 500 ... 599:
            logApi.error("fetchData http response code: \(httpResponse.statusCode) (server error)")
            return .failure(.server)
        default:
            logApi.error("fetchData http response code: \(httpResponse.statusCode)")
            return .failure(.unexpected(httpResponse.statusCode))
        }
    } catch {
        logApi.error("fetchData error: \(String(describing: error))")
        return .failure(.network)
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
                                      token: String) async -> Result<[T], HCloudError>
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
        else { return .failure(.network) }

        switch await fetchData(request: request) {
        case let .success(data):
            let decoded: ResourcePage<T> = decodeResourceList(from: data)
            items.append(contentsOf: decoded.items)
            page = decoded.nextPage
            pagesFetched += 1
        case let .failure(error):
            // Discard any partial pages: a failed load should surface the error, not a truncated list.
            return .failure(error)
        }
    }

    return .success(items)
}

/// RFC3339 formatter for the metrics `start`/`end` query parameters.
private let metricsDateFormatter = ISO8601DateFormatter()

/// Fetches the displayed metrics (`MetricTypesDisplayed`) for a single Load Balancer over the
/// trailing `rangeSeconds` window in one call, reusing the shared request/fetch path. Non-isolated
/// `async`, so the network wait and JSON decode stay off the main actor.
///
/// `GET /load_balancers/{id}/metrics?type=…&type=…&start=…&end=…&step=…`. Returns a dictionary
/// keyed by metric type, each value sorted by time. A decodable body that isn't the expected shape
/// maps to `.decoding`.
func loadLoadBalancerMetrics(customApiBaseUrl: String,
                             loadBalancerId: Int,
                             rangeSeconds: Int,
                             step: Int,
                             timeout: Double,
                             token: String) async -> Result<[String: [MetricSample]], HCloudError>
{
    let end = Date()
    let start = end.addingTimeInterval(-Double(rangeSeconds))

    var queryItems = [
        URLQueryItem(name: "start", value: metricsDateFormatter.string(from: start)),
        URLQueryItem(name: "end", value: metricsDateFormatter.string(from: end)),
        URLQueryItem(name: "step", value: String(step)),
    ]
    queryItems.append(contentsOf: MetricTypesDisplayed.map { URLQueryItem(name: "type", value: $0) })

    guard let request = buildURLRequest(customApiBaseUrl: customApiBaseUrl,
                                        resourceSuffix: "load_balancers/\(loadBalancerId)/metrics",
                                        timeout: timeout,
                                        token: token,
                                        queryItems: queryItems)
    else { return .failure(.network) }

    switch await fetchData(request: request) {
    case let .success(data):
        guard let response = try? JSONDecoder().decode(LBMetricsResponse.self, from: data) else {
            logJson.error("loadLoadBalancerMetrics failed to decode metrics response")
            return .failure(.decoding)
        }

        let series = response.metrics.timeSeries.mapValues { series in
            series.values
                .map { MetricSample(date: $0.date, value: $0.value) }
                .sorted { $0.date < $1.date }
        }
        return .success(series)
    case let .failure(error):
        return .failure(error)
    }
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
