import Foundation

struct UsersPageResponse: Decodable, Equatable, Sendable {
    let users: [UserSummaryResponse]
    let total: Int
    let skip: Int
    let limit: Int
}

// MARK: - Mapping

extension Page where Item == User {
    init(response: UsersPageResponse) {
        self.init(
            items: response.users.map(User.init(response:)),
            total: response.total,
            skip: response.skip,
            limit: response.limit
        )
    }
}
