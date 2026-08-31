import Foundation

/// Loads one user's full profile.
protocol GetUserDetailsInteractorProtocol: Sendable {
    func execute(id: Int) async throws(DomainError) -> UserDetails
}

struct GetUserDetailsInteractor: GetUserDetailsInteractorProtocol {
    private let repository: any UserRepositoryProtocol

    init(repository: any UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: Int) async throws(DomainError) -> UserDetails {
        try await repository.userDetails(id: id)
    }
}
