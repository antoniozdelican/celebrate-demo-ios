import Foundation
@testable import CelebrateDemoiOS

final class GetUsersInteractorStub: GetUsersInteractorProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _skips: [Int] = []

    var result: Result<Page<User>, DomainError> = .success(.empty)
    /// Pages keyed by offset, for tests that walk more than one page.
    var pages: [Int: Page<User>] = [:]

    var skips: [Int] { lock.withLock { _skips } }
    var callCount: Int { skips.count }

    func execute(skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _skips.append(skip) }
        if let page = pages[skip] { return page }
        switch result {
        case .success(let page): return page
        case .failure(let error): throw error
        }
    }
}

final class SearchUsersInteractorStub: SearchUsersInteractorProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(query: String, skip: Int)] = []

    var result: Result<Page<User>, DomainError> = .success(.empty)

    var calls: [(query: String, skip: Int)] { lock.withLock { _calls } }
    var queries: [String] { calls.map(\.query) }

    func execute(query: String, skip: Int) async throws(DomainError) -> Page<User> {
        lock.withLock { _calls.append((query, skip)) }
        switch result {
        case .success(let page): return page
        case .failure(let error): throw error
        }
    }
}

extension Page where Item == User {
    /// A page of `count` users starting at `skip`, with `total` items available overall.
    static func stub(count: Int, skip: Int = 0, total: Int) -> Page<User> {
        Page(
            items: (0..<count).map { User.stub(id: skip + $0 + 1, firstName: "User\(skip + $0 + 1)") },
            total: total,
            skip: skip,
            limit: count
        )
    }
}
