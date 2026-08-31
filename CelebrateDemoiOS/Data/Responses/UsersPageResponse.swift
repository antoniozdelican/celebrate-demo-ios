import Foundation

/// The paginated envelope DummyJSON wraps every collection in.
///
/// Shared by `GET /users` and `GET /users/search`, which is why pagination is modelled
/// once here rather than per endpoint.
struct UsersPageResponse: Decodable, Equatable, Sendable {
    let users: [UserSummaryResponse]
    let total: Int
    let skip: Int
    let limit: Int
}

// MARK: - Mapping

extension UsersPageResponse {
    func toDomain() -> Page<User> {
        Page(items: users.map { $0.toDomain() }, total: total, skip: skip, limit: limit)
    }
}
