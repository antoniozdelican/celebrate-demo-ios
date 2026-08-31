import Foundation
@testable import CelebrateDemoiOS

/// Records what an interactor asked the repository for, and replies with canned results.
///
/// Hand-written rather than generated: Swift has no runtime mocking, and a double this
/// small is clearer than any framework that would produce it.
final class UserRepositoryMock: UserRepositoryProtocol, @unchecked Sendable {
    /// One recorded call, so tests can assert on the arguments an interactor chose —
    /// page size in particular, which is the interactor's decision to make.
    enum Call: Equatable {
        case users(limit: Int, skip: Int)
        case search(query: String, limit: Int, skip: Int)
        case details(id: Int)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []

    var usersResult: Result<Page<User>, DomainError> = .success(.empty)
    var detailsResult: Result<UserDetails, DomainError> = .success(.fixture)

    var calls: [Call] { lock.withLock { _calls } }

    func users(limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _calls.append(.users(limit: limit, skip: skip)) }
        return try usersResult.value()
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _calls.append(.search(query: query, limit: limit, skip: skip)) }
        return try usersResult.value()
    }

    func userDetails(id: Int) async throws(DomainError) -> UserDetails {
        lock.withLock { _calls.append(.details(id: id)) }
        return try detailsResult.value()
    }
}

extension Result where Failure == DomainError {
    /// `Result.get()` throws untyped; the protocols demand `throws(DomainError)`.
    func value() throws(DomainError) -> Success {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
