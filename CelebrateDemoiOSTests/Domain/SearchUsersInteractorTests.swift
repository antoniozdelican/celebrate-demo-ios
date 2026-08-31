import Foundation
import Testing
@testable import CelebrateDemoiOS

@Suite("SearchUsersInteractor")
struct SearchUsersInteractorTests {
    @Test("Searches with the term trimmed, at the same page size as the list")
    func searchesTrimmedTerm() async throws {
        let repository = UserRepositoryStub()
        let sut = SearchUsersInteractor(repository: repository)

        _ = try await sut.execute(query: "  Emily  ", skip: 0)

        #expect(repository.calls == [.search(query: "Emily", limit: UsersPage.size, skip: 0)])
    }

    @Test("Search paginates with the same page size as the list, so offsets stay comparable")
    func sharesPageSizeWithList() async throws {
        let repository = UserRepositoryStub()

        _ = try await GetUsersInteractor(repository: repository).execute(skip: 0)
        _ = try await SearchUsersInteractor(repository: repository).execute(query: "Emily", skip: 0)

        #expect(repository.calls == [
            .users(limit: UsersPage.size, skip: 0),
            .search(query: "Emily", limit: UsersPage.size, skip: 0),
        ])
    }

    @Test(
        "A blank term yields an empty page without a request",
        arguments: ["", "   ", "\n\t "]
    )
    func blankTermMakesNoRequest(query: String) async throws {
        let repository = UserRepositoryStub()
        let sut = SearchUsersInteractor(repository: repository)

        let page = try await sut.execute(query: query, skip: 0)

        #expect(page.items.isEmpty)
        #expect(repository.calls.isEmpty)
    }

    @Test("The offset is passed through for paginated search results")
    func forwardsSkip() async throws {
        let repository = UserRepositoryStub()
        let sut = SearchUsersInteractor(repository: repository)

        _ = try await sut.execute(query: "Emily", skip: 30)

        #expect(repository.calls == [.search(query: "Emily", limit: UsersPage.size, skip: 30)])
    }

    @Test("Repository failures propagate untouched")
    func propagatesFailure() async {
        let repository = UserRepositoryStub()
        repository.usersResult = .failure(.timedOut)
        let sut = SearchUsersInteractor(repository: repository)

        await #expect(throws: DomainError.timedOut) {
            _ = try await sut.execute(query: "Emily", skip: 0)
        }
    }
}
