import Foundation
import Testing
@testable import CelebrateDemoiOS

/// The interactor's job is choosing which repository call to make and with what page
/// size — so that is what these assert on, not the data coming back.
@Suite("GetUsersInteractor")
struct GetUsersInteractorTests {
    @Test("Loads the unfiltered list at the domain's page size")
    func loadsList() async throws {
        let repository = UserRepositoryStub()
        let sut = GetUsersInteractor(repository: repository)

        _ = try await sut.execute(skip: 0)

        #expect(repository.calls == [.users(limit: UsersPage.size, skip: 0)])
    }

    @Test("The offset is passed through so pagination continues where the last page ended")
    func forwardsSkip() async throws {
        let repository = UserRepositoryStub()
        let sut = GetUsersInteractor(repository: repository)

        _ = try await sut.execute(skip: 60)

        #expect(repository.calls == [.users(limit: UsersPage.size, skip: 60)])
    }

    @Test("The page is returned unchanged — the interactor does not reshape data")
    func returnsRepositoryPage() async throws {
        let repository = UserRepositoryStub()
        let page = Page(items: [User.stub()], total: 208, skip: 0, limit: UsersPage.size)
        repository.usersResult = .success(page)
        let sut = GetUsersInteractor(repository: repository)

        #expect(try await sut.execute(skip: 0) == page)
    }

    @Test("Repository failures propagate untouched")
    func propagatesFailure() async {
        let repository = UserRepositoryStub()
        repository.usersResult = .failure(.notConnected)
        let sut = GetUsersInteractor(repository: repository)

        await #expect(throws: DomainError.notConnected) {
            _ = try await sut.execute(skip: 0)
        }
    }
}
