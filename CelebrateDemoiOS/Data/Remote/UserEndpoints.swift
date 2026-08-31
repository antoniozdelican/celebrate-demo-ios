import Foundation

/// Every DummyJSON users URL the app can produce, in one place.
///
/// Endpoint construction is separated from the data source so it can be asserted on
/// directly in tests — query encoding bugs (a missing `skip`, an unescaped `q`) are the
/// most common networking defect and the cheapest to catch here.
enum UserEndpoints {
    /// Fields requested for list rows.
    ///
    /// `select` trims the response from ~30 fields per user to 5, a meaningful bandwidth
    /// and decode-time saving across 200+ users. The detail screen fetches the full
    /// record separately.
    static let summaryFields = "firstName,lastName,email,image,company"

    /// `GET /users?limit=&skip=&select=`
    static func list(limit: Int, skip: Int) -> Endpoint {
        Endpoint(
            path: "users",
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "skip", value: String(skip)),
                URLQueryItem(name: "select", value: summaryFields),
            ]
        )
    }

    /// `GET /users/search?q=&limit=&skip=&select=`
    static func search(query: String, limit: Int, skip: Int) -> Endpoint {
        Endpoint(
            path: "users/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "skip", value: String(skip)),
                URLQueryItem(name: "select", value: summaryFields),
            ]
        )
    }

    /// `GET /users/{id}` — full record, no `select`.
    static func details(id: Int) -> Endpoint {
        Endpoint(path: "users/\(id)")
    }
}
