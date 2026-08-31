import Foundation

enum HTTPMethod: String, Equatable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A transport-agnostic description of one request.
///
/// Intentionally *not* Alamofire's `URLRequestConvertible`: endpoints are built and
/// asserted on by data sources and tests, and neither should have to import a
/// networking library to do it. ``HTTPClient`` is the single place that turns this into
/// a `URLRequest`.
struct Endpoint: Equatable, Sendable {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?

    /// Resolves the endpoint against a base URL.
    ///
    /// Query items with a `nil` value are dropped, which lets callers express optional
    /// parameters without branching at every call site.
    func urlRequest(baseURL: URL) throws(HTTPError) -> URLRequest {
        let resolved = baseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: resolved, resolvingAgainstBaseURL: false) else {
            throw .invalidURL
        }
        let present = queryItems.filter { $0.value != nil }
        components.queryItems = present.isEmpty ? nil : present

        // `URLComponents` does not escape `+` in a query value, and many servers read a
        // literal `+` as a space — so a search for "john+doe" would silently become
        // "john doe". Escaping it explicitly is the standard workaround.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")

        guard let url = components.url else { throw .invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
