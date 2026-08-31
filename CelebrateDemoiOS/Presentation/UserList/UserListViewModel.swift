import Foundation
import Observation

@MainActor
protocol UserListViewModelProtocol: AnyObject, Observable {
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
@Observable
final class UserListViewModel: UserListViewModelProtocol {
    private(set) var state: UserListViewState = .loading
    private(set) var isLoadingMore = false
    var query = ""

    private let getUsersInteractor: any GetUsersInteractorProtocol
    private let searchUsersInteractor: any SearchUsersInteractorProtocol
    private let searchDebounce: Duration

    private var nextSkip: Int?
    private var hasLoadedOnce = false

    init(
        getUsersInteractor: any GetUsersInteractorProtocol,
        searchUsersInteractor: any SearchUsersInteractorProtocol,
        searchDebounce: Duration = .milliseconds(300)
    ) {
        self.getUsersInteractor = getUsersInteractor
        self.searchUsersInteractor = searchUsersInteractor
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
            ? try await searchUsersInteractor.execute(query: query, skip: skip)
            : try await getUsersInteractor.execute(skip: skip)
    }

    private var emptyReason: UserListViewState.Empty {
        isSearching
            ? .noMatches(query: query.trimmingCharacters(in: .whitespacesAndNewlines))
            : .noUsers
    }
}
