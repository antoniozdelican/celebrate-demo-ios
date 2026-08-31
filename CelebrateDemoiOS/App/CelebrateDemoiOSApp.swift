import SwiftUI

@main
struct CelebrateDemoiOSApp: App {
    /// The composition root and the root view model, both built once in `init`.
    ///
    /// Constructing the view model inside `body` would allocate a fresh one on every
    /// scene body evaluation, only for `@State` to discard it — `@State` keeps whatever
    /// it was first given.
    ///
    /// When UI tests arrive, `AppDependencies` becomes a switch: a `-uiTesting` launch
    /// argument will select a fixture-backed graph, which is the only way to make error
    /// and empty states reachable from XCUITest — the live API will not return a 500 on
    /// request, and `URLProtocol` stubbing cannot cross into the app's process.
    private let dependencies: AppDependencies
    private let listViewModel: UserListViewModel

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        listViewModel = UserListViewModel(
            getUsers: dependencies.getUsers,
            searchUsers: dependencies.searchUsers
        )
    }

    var body: some Scene {
        WindowGroup {
            UserListView(viewModel: listViewModel) { user in
                UserDetailView(
                    viewModel: UserDetailViewModel(
                        userID: user.id,
                        getUserDetails: dependencies.getUserDetails
                    )
                )
            }
        }
    }
}
