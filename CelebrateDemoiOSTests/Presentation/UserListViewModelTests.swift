import Foundation
import Testing
@testable import CelebrateDemoiOS

@MainActor
@Suite("UserListViewModel")
struct UserListViewModelTests {
    /// Debounce is zeroed so tests assert behaviour rather than wait on a timer. The
    /// debounce itself is covered separately, in `debouncesSearch`.
    private func makeSUT(
        getUsers: GetUsersInteractorMock = .init(),
        searchUsers: SearchUsersInteractorMock = .init(),
        debounce: Duration = .zero
    ) -> UserListViewModel {
        UserListViewModel(
            getUsersInteractor: getUsers,
            searchUsersInteractor: searchUsers,
            searchDebounce: debounce
        )
    }

    // MARK: - Initial load

    @Test("Starts loading, then shows the first page")
    func loadsFirstPage() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .success(.fixture(count: 3, total: 208))
        let sut = makeSUT(getUsers: getUsers)

        #expect(sut.state == .loading)

        await sut.load()

        #expect(getUsers.skips == [0])
        guard case .loaded(let users) = sut.state else {
            Issue.record("Expected .loaded, got \(sut.state)")
            return
        }
        #expect(users.count == 3)
    }

    @Test("An empty collection is an empty state, not an error")
    func emptyCollection() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .success(.fixture(count: 0, total: 0))
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()

        #expect(sut.state == .empty(.noUsers))
    }

    @Test("A failure becomes a failed state carrying the domain error")
    func failure() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .failure(.notConnected)
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()

        #expect(sut.state == .failed(.notConnected))
    }

    @Test("A cancelled load leaves the state alone rather than showing an error")
    func cancellationIsNotAnError() async {
        // A superseded search keystroke must not flash an error at the user.
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .failure(.cancelled)
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()

        #expect(sut.state == .loading)
    }

    // MARK: - Search

    @Test("A query switches to the search use case")
    func searchesWhenQueryPresent() async {
        let getUsers = GetUsersInteractorMock()
        let searchUsers = SearchUsersInteractorMock()
        searchUsers.result = .success(.fixture(count: 1, total: 1))
        let sut = makeSUT(getUsers: getUsers, searchUsers: searchUsers)

        await sut.load()
        sut.query = "Emily"
        await sut.load()

        #expect(searchUsers.queries == ["Emily"])
        #expect(getUsers.callCount == 1, "the list use case must not run for a search")
    }

    @Test("Clearing the query returns to the unfiltered list")
    func clearingQueryReloadsList() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .success(.fixture(count: 3, total: 208))
        let searchUsers = SearchUsersInteractorMock()
        let sut = makeSUT(getUsers: getUsers, searchUsers: searchUsers)

        await sut.load()
        sut.query = "Emily"
        await sut.load()
        sut.query = ""
        await sut.load()

        #expect(getUsers.callCount == 2)
        #expect(searchUsers.calls.count == 1)
    }

    @Test("A whitespace-only query is not a search")
    func whitespaceQueryIsNotASearch() async {
        let getUsers = GetUsersInteractorMock()
        let searchUsers = SearchUsersInteractorMock()
        let sut = makeSUT(getUsers: getUsers, searchUsers: searchUsers)

        sut.query = "   "
        await sut.load()

        #expect(searchUsers.calls.isEmpty)
        #expect(getUsers.callCount == 1)
    }

    @Test("No matches reports the query so the UI can name it")
    func noMatches() async {
        let searchUsers = SearchUsersInteractorMock()
        searchUsers.result = .success(.fixture(count: 0, total: 0))
        let sut = makeSUT(searchUsers: searchUsers)

        await sut.load()
        sut.query = "  Zzz  "
        await sut.load()

        #expect(sut.state == .empty(.noMatches(query: "Zzz")))
    }

    @Test("A superseded search never reaches the interactor")
    func debouncesSearch() async {
        let searchUsers = SearchUsersInteractorMock()
        let sut = makeSUT(searchUsers: searchUsers, debounce: .milliseconds(200))

        await sut.load()

        // Typing "Em" then "Emi": the first task is cancelled before its debounce ends,
        // exactly as `.task(id:)` does when the query changes.
        sut.query = "Em"
        let superseded = Task { await sut.load() }
        try? await Task.sleep(for: .milliseconds(20))
        superseded.cancel()

        sut.query = "Emi"
        await sut.load()

        #expect(searchUsers.queries == ["Emi"])
    }

    // MARK: - Pagination

    @Test("Loading more appends the next page and advances the offset")
    func loadsMore() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.pages = [
            0: .fixture(count: 3, skip: 0, total: 6),
            3: .fixture(count: 3, skip: 3, total: 6),
        ]
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()
        await sut.loadMore()

        #expect(getUsers.skips == [0, 3])
        guard case .loaded(let users) = sut.state else {
            Issue.record("Expected .loaded")
            return
        }
        #expect(users.map(\.id) == [1, 2, 3, 4, 5, 6])
    }

    @Test("The last page stops pagination")
    func stopsAtLastPage() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .success(.fixture(count: 3, total: 3))
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()
        #expect(!sut.canLoadMore)

        await sut.loadMore()
        #expect(getUsers.skips == [0], "no further request should be made")
    }

    @Test("A failure while paginating keeps the rows already on screen")
    func paginationFailureKeepsExistingRows() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.pages = [0: .fixture(count: 3, skip: 0, total: 6)]
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()
        getUsers.result = .failure(.timedOut)
        await sut.loadMore()

        // Replacing the list with a full-screen error would discard what the user is
        // already reading.
        guard case .loaded(let users) = sut.state else {
            Issue.record("Expected .loaded, got \(sut.state)")
            return
        }
        #expect(users.count == 3)
        #expect(!sut.canLoadMore)
    }

    // MARK: - Refresh and retry

    @Test("Refresh replaces the contents rather than appending")
    func refreshReplaces() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.pages = [0: .fixture(count: 3, skip: 0, total: 6)]
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()
        await sut.refresh()

        guard case .loaded(let users) = sut.state else {
            Issue.record("Expected .loaded")
            return
        }
        #expect(users.count == 3)
    }

    @Test("Retry goes back through loading and can recover")
    func retryRecovers() async {
        let getUsers = GetUsersInteractorMock()
        getUsers.result = .failure(.timedOut)
        let sut = makeSUT(getUsers: getUsers)

        await sut.load()
        #expect(sut.state == .failed(.timedOut))

        getUsers.result = .success(.fixture(count: 2, total: 2))
        await sut.retry()

        guard case .loaded(let users) = sut.state else {
            Issue.record("Expected .loaded after retry")
            return
        }
        #expect(users.count == 2)
    }
}
