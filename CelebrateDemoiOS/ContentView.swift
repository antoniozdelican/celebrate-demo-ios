import SwiftUI

/// Temporary harness proving the composition root wires up correctly end to end.
///
/// **This is scaffolding and will be deleted.** It is replaced by `UserListView` and its
/// view model when the presentation layer lands; state belongs in a view model, not
/// inline in a view. It exists now because a composition root nothing consumes is dead
/// code, and because every test so far stubs the wire — this is the first thing to
/// exercise the stack against the live API.
struct ContentView: View {
    let getUsers: any GetUsersInteractorProtocol

    @State private var loadState: LoadState = .loading

    /// Named `LoadState`, not `State`: a nested `State` shadows SwiftUI's property
    /// wrapper inside this type.
    enum LoadState {
        case loading
        case loaded(Page<User>)
        case failed(DomainError)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading:
                    ProgressView()

                case .loaded(let page):
                    List(page.items) { user in
                        VStack(alignment: .leading) {
                            Text(user.fullName)
                            Text(user.jobTitle ?? user.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                case .failed(let error):
                    ContentUnavailableView(
                        "Couldn't load users",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.errorDescription ?? "")
                    )
                }
            }
            .navigationTitle(navigationTitle)
        }
        .task { await load() }
    }

    private var navigationTitle: String {
        if case .loaded(let page) = loadState {
            return "\(page.items.count) of \(page.total)"
        }
        return "Users"
    }

    private func load() async {
        do {
            loadState = .loaded(try await getUsers.execute(skip: 0))
        } catch {
            loadState = .failed(error)
        }
    }
}
