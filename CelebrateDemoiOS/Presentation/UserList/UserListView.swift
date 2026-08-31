import SwiftUI

struct UserListView<ViewModel: UserListViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .safeAreaInset(edge: .top) {
                    DSSearchField(text: $viewModel.query, placeholder: "Search users")
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.bottom, DSSpacing.sm)
                        .background(DSColor.background)
                }
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

        case .empty(let reason):
            DSStateView(emptyStyle(reason))

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
                UserRow(user: user)
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

    private func emptyStyle(_ reason: UserListViewState.Empty) -> DSStateView.Style {
        switch reason {
        case .noUsers:
            .empty(
                systemImage: "person.2.slash",
                title: "No users yet",
                message: "There is nothing to show right now."
            )
        case .noMatches(let query):
            .empty(
                systemImage: "magnifyingglass",
                title: "No results",
                message: "Nothing matched “\(query)”."
            )
        }
    }
}
