import Foundation

/// The user resource, expressed in response models.
///
/// A data source is *per resource*: it owns that resource's endpoints, its response models and
/// nothing else. Contrast with a single app-wide "NetworkManager", which accretes one
/// method per endpoint until it is untestable and merge-conflict-prone.
///
/// It returns response models rather than domain entities on purpose — mapping is the repository's
/// job, which keeps the data source a thin, obviously-correct translation of the API.
protocol UserRemoteDataSourceProtocol: Sendable {
    func users(limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse
    func searchUsers(query: String, limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse
    func userDetails(id: Int) async throws(HTTPError) -> UserDetailsResponse
}

/// Default implementation of ``UserRemoteDataSourceProtocol``.
///
/// Note how little there is here: the data source picks an endpoint and names a response
/// type. Transport concerns (retry, validation, error translation, decoding) belong to
/// ``HTTPClientProtocol``; domain concerns belong to ``UserRepository``.
struct UserRemoteDataSource: UserRemoteDataSourceProtocol {
    private let client: any HTTPClientProtocol

    init(client: any HTTPClientProtocol) {
        self.client = client
    }

    func users(limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse {
        try await client.send(UserEndpoints.list(limit: limit, skip: skip), as: UsersPageResponse.self)
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(HTTPError) -> UsersPageResponse {
        try await client.send(
            UserEndpoints.search(query: query, limit: limit, skip: skip),
            as: UsersPageResponse.self
        )
    }

    func userDetails(id: Int) async throws(HTTPError) -> UserDetailsResponse {
        try await client.send(UserEndpoints.details(id: id), as: UserDetailsResponse.self)
    }
}
