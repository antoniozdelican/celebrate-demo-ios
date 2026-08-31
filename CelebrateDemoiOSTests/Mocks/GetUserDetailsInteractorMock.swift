import Foundation
@testable import CelebrateDemoiOS

final class GetUserDetailsInteractorMock: GetUserDetailsInteractorProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _ids: [Int] = []

    var result: Result<UserDetails, DomainError> = .success(.fixture)

    var ids: [Int] { lock.withLock { _ids } }
    var callCount: Int { ids.count }

    func execute(id: Int) async throws(DomainError) -> UserDetails {
        lock.withLock { _ids.append(id) }
        return try result.value()
    }
}
