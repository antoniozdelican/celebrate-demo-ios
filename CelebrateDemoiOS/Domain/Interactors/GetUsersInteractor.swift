import Foundation

/// Loads one page of the unfiltered user list.
protocol GetUsersInteractorProtocol: Sendable {
    /// - Parameter skip: offset of the first item, from `Page.nextSkip`.
    func execute(skip: Int) async throws(DomainError) -> Page<User>
}

struct GetUsersInteractor: GetUsersInteractorProtocol {
    private let repository: any UserRepositoryProtocol

    init(repository: any UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute(skip: Int) async throws(DomainError) -> Page<User> {
        try await repository.users(limit: UsersPage.size, skip: skip)
    }
}
