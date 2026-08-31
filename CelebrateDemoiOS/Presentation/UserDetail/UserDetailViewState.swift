import Foundation

enum UserDetailViewState: Equatable {
    case loading
    case loaded(UserDetails)
    case failed(DomainError)
}
