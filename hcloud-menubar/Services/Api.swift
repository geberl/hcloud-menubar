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

func startDataTask(request: URLRequest,
                   dataCompletion: @escaping (Data, String, @escaping (NSArray) -> Void) -> Void,
                   jsonContainer: String,
                   addItemsHandler: @escaping (NSArray) -> Void)
{
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
            dataCompletion(saveData, jsonContainer, addItemsHandler)
        default:
            logApi.error("startDataTask http response code: \(httpResponse.statusCode)")
        }
    }

    task.resume()
}

func handleResponse(data: Data, jsonContainer: String, addItemsHandler: @escaping (NSArray) -> Void) {
    do {
        let responseSerialized = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        let jsonResult: NSDictionary! = responseSerialized as? NSDictionary // or NSArray depending on root element
        if jsonResult != nil {
            guard let items = jsonResult[jsonContainer] as? NSArray else {
                logJson.error("Error getting '\(jsonContainer)' array item from json")
                return
            }

            DispatchQueue.main.async {
                addItemsHandler(items)
            }
        } else {
            logJson.error("Error creating dictionary from json data")
        }
    } catch {
        logJson.error("Error serializing json")
    }
}
