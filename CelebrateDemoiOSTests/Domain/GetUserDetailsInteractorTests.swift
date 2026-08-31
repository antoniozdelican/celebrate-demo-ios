import Foundation
import Testing
@testable import CelebrateDemoiOS

@Suite("GetUserDetailsInteractor")
struct GetUserDetailsInteractorTests {
    @Test("Asks the repository for the requested identifier")
    func requestsIdentifier() async throws {
        let repository = UserRepositoryStub()
        let sut = GetUserDetailsInteractor(repository: repository)

        _ = try await sut.execute(id: 7)

        #expect(repository.calls == [.details(id: 7)])
    }

    @Test("Returns the profile unchanged")
    func returnsDetails() async throws {
        let repository = UserRepositoryStub()
        let sut = GetUserDetailsInteractor(repository: repository)

        #expect(try await sut.execute(id: 1) == .stub)
    }

    @Test("A missing user propagates as .notFound for the detail screen to render")
    func propagatesNotFound() async {
        let repository = UserRepositoryStub()
        repository.detailsResult = .failure(.notFound)
        let sut = GetUserDetailsInteractor(repository: repository)

        await #expect(throws: DomainError.notFound) {
            _ = try await sut.execute(id: 9999)
        }
    }
}
