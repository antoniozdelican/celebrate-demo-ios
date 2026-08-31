import Foundation

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

    func users(limit: Int, skip: Int) async throws(HTTPError) -> UsersPageDTO {
        try await client.send(UserEndpoints.list(limit: limit, skip: skip), as: UsersPageDTO.self)
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(HTTPError) -> UsersPageDTO {
        try await client.send(
            UserEndpoints.search(query: query, limit: limit, skip: skip),
            as: UsersPageDTO.self
        )
    }

    func userDetails(id: Int) async throws(HTTPError) -> UserDetailsDTO {
        try await client.send(UserEndpoints.details(id: id), as: UserDetailsDTO.self)
    }
}
