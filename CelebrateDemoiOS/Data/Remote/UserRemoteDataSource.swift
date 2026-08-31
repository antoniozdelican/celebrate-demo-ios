import Foundation

/// The user resource, expressed in response models.
///
/// A data source is *per resource*: it owns that resource's paths, its response models
/// and nothing else. Contrast with a single app-wide "NetworkManager", which accretes
/// one method per endpoint until it is untestable and merge-conflict-prone.
///
/// It returns response models rather than domain entities on purpose — mapping is the
/// repository's job, which keeps the data source a thin, obviously-correct translation
/// of the API.
protocol UserRemoteDataSourceProtocol: Sendable {
    func users(limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse
    func searchUsers(query: String, limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse
    func userDetails(id: Int) async throws(HTTPError) -> UserDetailsResponse
}

struct UserRemoteDataSource: UserRemoteDataSourceProtocol {
    /// Endpoints this resource can address. Values only — each function builds its own
    /// ``HTTPRequest`` around them.
    private enum Endpoint: String {
        case users
        case search = "users/search"
    }

    /// Fields requested for list rows.
    ///
    /// `select` trims the response from ~30 fields per user to 5, a meaningful bandwidth
    /// and decode-time saving across 200+ users. The detail screen fetches the full
    /// record separately, so it sends no `select`.
    private static let summaryFields = "firstName,lastName,email,image,company"

    private let client: any HTTPClientProtocol

    init(client: any HTTPClientProtocol) {
        self.client = client
    }

    func users(limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse {
        let request = HTTPRequest(
            path: Endpoint.users.rawValue,
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "skip", value: String(skip)),
                URLQueryItem(name: "select", value: Self.summaryFields),
            ]
        )
        return try await client.send(request, as: UsersPageResponse.self)
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse {
        let request = HTTPRequest(
            path: Endpoint.search.rawValue,
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "skip", value: String(skip)),
                URLQueryItem(name: "select", value: Self.summaryFields),
            ]
        )
        return try await client.send(request, as: UsersPageResponse.self)
    }

    func userDetails(id: Int) async throws(HTTPError) -> UserDetailsResponse {
        let request = HTTPRequest(path: "\(Endpoint.users.rawValue)/\(id)")
        return try await client.send(request, as: UserDetailsResponse.self)
    }
}
