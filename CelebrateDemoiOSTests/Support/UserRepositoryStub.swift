import Foundation
@testable import CelebrateDemoiOS

/// Records what an interactor asked the repository for, and replies with canned results.
///
/// Hand-written rather than generated: Swift has no runtime mocking, and a fake this
/// small is clearer than any framework that would produce it.
final class UserRepositoryStub: UserRepositoryProtocol, @unchecked Sendable {
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
    var detailsResult: Result<UserDetails, DomainError>

    init(details: UserDetails = .stub) {
        detailsResult = .success(details)
    }

    var calls: [Call] { lock.withLock { _calls } }

    func users(limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _calls.append(.users(limit: limit, skip: skip)) }
        return try usersResult.get()
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _calls.append(.search(query: query, limit: limit, skip: skip)) }
        return try usersResult.get()
    }

    func userDetails(id: Int) async throws(DomainError) -> UserDetails {
        lock.withLock { _calls.append(.details(id: id)) }
        return try detailsResult.get()
    }
}

private extension Result where Failure == DomainError {
    /// `Result.get()` throws untyped; the protocol demands `throws(DomainError)`.
    func get() throws(DomainError) -> Success {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}

extension User {
    static func stub(id: Int = 1, firstName: String = "Emily", lastName: String = "Johnson") -> User {
        User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: "\(firstName.lowercased())@example.com",
            imageURL: nil,
            jobTitle: "Sales Manager"
        )
    }
}

extension UserDetails {
    static let stub = UserDetails(
        id: 1,
        firstName: "Emily",
        lastName: "Johnson",
        maidenName: nil,
        email: "emily@example.com",
        phone: nil,
        username: nil,
        age: 28,
        gender: .female,
        birthDate: nil,
        imageURL: nil,
        company: nil,
        address: nil,
        university: nil,
        role: nil
    )
}
