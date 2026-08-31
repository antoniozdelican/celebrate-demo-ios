import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            UserListView(
                viewModel: UserListViewModel(
                    getUsersInteractor: dependencies.getUsersInteractor,
                    searchUsersInteractor: dependencies.searchUsersInteractor
                )
            )
            .navigationDestination(for: Route.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .userDetail(let userID):
            UserDetailView(
                viewModel: UserDetailViewModel(
                    userID: userID,
                    getUserDetailsInteractor: dependencies.getUserDetailsInteractor,
                    formatBirthDateInteractor: dependencies.formatBirthDateInteractor
                )
            )
        }
    }
}
