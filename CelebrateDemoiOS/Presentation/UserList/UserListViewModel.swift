import Combine
import Foundation

@MainActor
protocol UserListViewModelProtocol: ObservableObject {
    var state: UserListViewState { get }
    var isLoadingMore: Bool { get }
    var canLoadMore: Bool { get }
    var query: String { get set }

    func load() async
    func refresh() async
    func loadMore() async
    func retry() async
}

@MainActor
final class UserListViewModel: UserListViewModelProtocol {
    @Published private(set) var state: UserListViewState = .loading
    @Published private(set) var isLoadingMore = false
    @Published var query = ""

    private let getUsers: any GetUsersInteractorProtocol
    private let searchUsers: any SearchUsersInteractorProtocol
    private let searchDebounce: Duration

    private var nextSkip: Int?
    private var hasLoadedOnce = false

    init(
        getUsers: any GetUsersInteractorProtocol,
        searchUsers: any SearchUsersInteractorProtocol,
        searchDebounce: Duration = .milliseconds(300)
    ) {
        self.getUsers = getUsers
        self.searchUsers = searchUsers
        self.searchDebounce = searchDebounce
    }

    var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canLoadMore: Bool {
        nextSkip != nil && !isLoadingMore
    }

    func load() async {
        if hasLoadedOnce {
            do {
                try await Task.sleep(for: searchDebounce)
            } catch {
                return
            }
            state = .loading
        }

        do {
            let page = try await page(skip: 0)
            hasLoadedOnce = true
            nextSkip = page.nextSkip
            state = page.items.isEmpty ? .empty(emptyReason) : .loaded(page.items)
        } catch {
            hasLoadedOnce = true
            guard error != .cancelled else { return }
            state = .failed(error)
        }
    }

    func refresh() async {
        do {
            let page = try await page(skip: 0)
            nextSkip = page.nextSkip
            state = page.items.isEmpty ? .empty(emptyReason) : .loaded(page.items)
        } catch {
            guard error != .cancelled else { return }
            state = .failed(error)
        }
    }

    func loadMore() async {
        guard let skip = nextSkip, !isLoadingMore, case .loaded(let existing) = state else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await page(skip: skip)
            nextSkip = page.nextSkip
            state = .loaded(existing + page.items)
        } catch {
            nextSkip = nil
        }
    }

    func retry() async {
        state = .loading
        await refresh()
    }

    private func page(skip: Int) async throws(DomainError) -> Page<User> {
        isSearching
            ? try await searchUsers.execute(query: query, skip: skip)
            : try await getUsers.execute(skip: skip)
    }

    private var emptyReason: UserListViewState.Empty {
        isSearching
            ? .noMatches(query: query.trimmingCharacters(in: .whitespacesAndNewlines))
            : .noUsers
    }
}
