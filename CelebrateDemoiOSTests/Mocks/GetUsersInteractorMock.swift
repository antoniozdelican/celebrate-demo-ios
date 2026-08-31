import Foundation
@testable import CelebrateDemoiOS

final class GetUsersInteractorMock: GetUsersInteractorProtocol, @unchecked Sendable {
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
        return try result.value()
    }
}
