import Foundation
import Observation

@MainActor
protocol UserDetailViewModelProtocol: AnyObject, Observable {
    var state: UserDetailViewState { get }

    func load() async
    func retry() async
    func formattedBirthDate(_ date: Date) -> String
}

@MainActor
@Observable
final class UserDetailViewModel: UserDetailViewModelProtocol {
    private(set) var state: UserDetailViewState = .loading

    private let userID: Int
    private let getUserDetailsInteractor: any GetUserDetailsInteractorProtocol
    private let formatBirthDateInteractor: any FormatBirthDateInteractorProtocol

    init(
        userID: Int,
        getUserDetailsInteractor: any GetUserDetailsInteractorProtocol,
        formatBirthDateInteractor: any FormatBirthDateInteractorProtocol
    ) {
        self.userID = userID
        self.getUserDetailsInteractor = getUserDetailsInteractor
        self.formatBirthDateInteractor = formatBirthDateInteractor
    }

    func formattedBirthDate(_ date: Date) -> String {
        formatBirthDateInteractor.execute(date)
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
