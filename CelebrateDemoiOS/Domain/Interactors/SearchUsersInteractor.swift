import Foundation

/// Loads one page of users matching a search term.
///
/// Separate from ``GetUsersInteractorProtocol`` rather than a blank-query mode of it:
/// they hit different endpoints, and folding them together would make an empty string a
/// sentinel meaning "no filter". Callers decide which use case they are invoking.
protocol SearchUsersInteractorProtocol: Sendable {
    /// - Parameters:
    ///   - query: trimmed before use; a blank term yields an empty page without a request.
    ///   - skip: offset of the first item, from `Page.nextSkip`.
    func execute(query: String, skip: Int) async throws(DomainError) -> Page<User>
}

struct SearchUsersInteractor: SearchUsersInteractorProtocol {
    private let repository: any UserRepositoryProtocol

    init(repository: any UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String, skip: Int) async throws(DomainError) -> Page<User> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        return try await repository.searchUsers(query: trimmed, limit: UsersPage.size, skip: skip)
    }
}
