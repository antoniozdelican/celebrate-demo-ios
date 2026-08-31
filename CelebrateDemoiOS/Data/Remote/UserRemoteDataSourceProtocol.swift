import Foundation

/// The user resource, expressed in DTOs.
///
/// A data source is *per resource*: it owns that resource's endpoints, its DTOs and
/// nothing else. Contrast with a single app-wide "NetworkManager", which accretes one
/// method per endpoint until it is untestable and merge-conflict-prone.
///
/// It returns DTOs rather than domain entities on purpose — mapping is the repository's
/// job, which keeps the data source a thin, obviously-correct translation of the API.
protocol UserRemoteDataSourceProtocol: Sendable {
    func users(limit: Int, skip: Int) async throws(HTTPError) -> UsersPageDTO
    func searchUsers(query: String, limit: Int, skip: Int) async throws(HTTPError) -> UsersPageDTO
    func userDetails(id: Int) async throws(HTTPError) -> UserDetailsDTO
}
