import SwiftUI

struct UserListView<ViewModel: UserListViewModelProtocol, Detail: View>: View {
    @State private var viewModel: ViewModel
    private let detail: (User) -> Detail

    init(viewModel: ViewModel, @ViewBuilder detail: @escaping (User) -> Detail) {
        _viewModel = State(wrappedValue: viewModel)
        self.detail = detail
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .searchable(text: $viewModel.query, prompt: "Search users")
                .navigationDestination(for: User.self, destination: detail)
        }
        .task(id: viewModel.query) {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            DSStateView(.loading)

        case .loaded(let users):
            list(users)

        case .empty(.noMatches(let query)):
            DSStateView(.empty(
                systemImage: "magnifyingglass",
                title: "No results",
                message: "Nothing matched “\(query)”."
            ))

        case .empty(.noUsers):
            DSStateView(.empty(
                systemImage: "person.2.slash",
                title: "No users yet",
                message: "There is nothing to show right now."
            ))

        case .failed(let error):
            DSStateView(
                .failure(title: "Couldn't load users", message: error.errorDescription),
                retry: error.isRetryable ? { Task { await viewModel.retry() } } : nil
            )
        }
    }

    private func list(_ users: [User]) -> some View {
        List {
            ForEach(users) { user in
                NavigationLink(value: user) {
                    UserRow(user: user)
                }
                .onAppear {
                    guard user.id == users.last?.id else { return }
                    Task { await viewModel.loadMore() }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
    }
}
