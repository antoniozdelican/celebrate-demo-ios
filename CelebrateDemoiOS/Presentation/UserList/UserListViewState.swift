import Foundation

enum UserListViewState: Equatable {
    case loading
    case loaded([User])
    case empty(Empty)
    case failed(DomainError)

    enum Empty: Equatable {
        case noUsers
        case noMatches(query: String)
    }
}
