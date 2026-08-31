import Foundation
@testable import CelebrateDemoiOS

final class SearchUsersInteractorMock: SearchUsersInteractorProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(query: String, skip: Int)] = []

    var result: Result<Page<User>, DomainError> = .success(.empty)

    var calls: [(query: String, skip: Int)] { lock.withLock { _calls } }
    var queries: [String] { calls.map(\.query) }

    func execute(query: String, skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _calls.append((query, skip)) }
        return try result.value()
    }
}
