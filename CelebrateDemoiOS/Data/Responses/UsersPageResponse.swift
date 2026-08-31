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

extension Page where Item == User {
    /// Constrained to `Page<User>`: `Page` is generic, but this envelope only ever
    /// carries users.
    init(response: UsersPageResponse) {
        self.init(
            items: response.users.map(User.init(response:)),
            total: response.total,
            skip: response.skip,
            limit: response.limit
        )
    }
}
