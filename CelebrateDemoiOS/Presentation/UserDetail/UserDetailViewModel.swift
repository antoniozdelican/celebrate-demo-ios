import Foundation
import Observation

@MainActor
protocol UserDetailViewModelProtocol: AnyObject, Observable {
    var state: UserDetailViewState { get }

    func load() async
    func retry() async
}

@MainActor
@Observable
final class UserDetailViewModel: UserDetailViewModelProtocol {
    private(set) var state: UserDetailViewState = .loading

    private let userID: Int
    private let getUserDetailsInteractor: any GetUserDetailsInteractorProtocol

    init(userID: Int, getUserDetailsInteractor: any GetUserDetailsInteractorProtocol) {
        self.userID = userID
        self.getUserDetailsInteractor = getUserDetailsInteractor
    }

    func load() async {
        guard state == .loading else { return }

        do {
            state = .loaded(try await getUserDetailsInteractor.execute(id: userID))
        } catch {
            guard error != .cancelled else { return }
            state = .failed(error)
        }
    }

    func retry() async {
        state = .loading
        await load()
    }
}
