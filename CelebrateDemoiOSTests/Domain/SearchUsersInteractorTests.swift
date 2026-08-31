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

        #expect(repository.calls == [.search(query: "Emily", limit: SearchUsersInteractor.pageSize, skip: 0)])
    }

    /// The two page sizes are declared separately, so this guards the drift that
    /// duplication invites: a search paginating differently from the list would break
    /// `Page.nextSkip` arithmetic when switching between filtered and unfiltered.
    @Test("Search and list request the same page size")
    func sharesPageSizeWithList() {
        #expect(SearchUsersInteractor.pageSize == GetUsersInteractor.pageSize)
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

        #expect(repository.calls == [.search(query: "Emily", limit: SearchUsersInteractor.pageSize, skip: 30)])
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
