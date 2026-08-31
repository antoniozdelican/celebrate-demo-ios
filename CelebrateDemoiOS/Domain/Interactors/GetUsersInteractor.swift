import Foundation

/// Loads one page of the unfiltered user list.
protocol GetUsersInteractorProtocol: Sendable {
    /// - Parameter skip: offset of the first item, from `Page.nextSkip`.
    func execute(skip: Int) async throws(DomainError) -> Page<User>
}

struct GetUsersInteractor: GetUsersInteractorProtocol {
    /// A domain decision, not a presentation one: the UI should not be able to change
    /// what a page costs. 30 sits mid-range of the 20–50 the API is comfortable serving.
    static let pageSize = 30

    private let repository: any UserRepositoryProtocol

    init(repository: any UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute(skip: Int) async throws(DomainError) -> Page<User> {
        try await repository.users(limit: Self.pageSize, skip: skip)
    }
}
