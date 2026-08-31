import Foundation
import Testing
@testable import CelebrateDemoiOS

@Suite("GetUsersInteractor")
struct GetUsersInteractorTests {
    @Test("Loads the unfiltered list at the domain's page size")
    func loadsList() async throws {
        let repository = UserRepositoryMock()
        let sut = GetUsersInteractor(repository: repository)

        _ = try await sut.execute(skip: 0)

        #expect(repository.calls == [.users(limit: GetUsersInteractor.pageSize, skip: 0)])
    }

    @Test("The offset is passed through so pagination continues where the last page ended")
    func forwardsSkip() async throws {
        let repository = UserRepositoryMock()
        let sut = GetUsersInteractor(repository: repository)

        _ = try await sut.execute(skip: 60)

        #expect(repository.calls == [.users(limit: GetUsersInteractor.pageSize, skip: 60)])
    }

    @Test("The page is returned unchanged — the interactor does not reshape data")
    func returnsRepositoryPage() async throws {
        let repository = UserRepositoryMock()
        let page = Page(items: [User.fixture()], total: 208, skip: 0, limit: GetUsersInteractor.pageSize)
        repository.usersResult = .success(page)
        let sut = GetUsersInteractor(repository: repository)

        #expect(try await sut.execute(skip: 0) == page)
    }

    @Test("Page size stays within the range the brief and the API allow")
    func pageSizeIsInRange() {
        #expect((20...50).contains(GetUsersInteractor.pageSize))
    }

    @Test("Repository failures propagate untouched")
    func propagatesFailure() async {
        let repository = UserRepositoryMock()
        repository.usersResult = .failure(.notConnected)
        let sut = GetUsersInteractor(repository: repository)

        await #expect(throws: DomainError.notConnected) {
            _ = try await sut.execute(skip: 0)
        }
    }
}
