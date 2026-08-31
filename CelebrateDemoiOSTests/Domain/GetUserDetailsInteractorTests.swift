import Foundation
import Testing
@testable import CelebrateDemoiOS

@Suite("GetUserDetailsInteractor")
struct GetUserDetailsInteractorTests {
    @Test("Asks the repository for the requested identifier")
    func requestsIdentifier() async throws {
        let repository = UserRepositoryMock()
        let sut = GetUserDetailsInteractor(repository: repository)

        _ = try await sut.execute(id: 7)

        #expect(repository.calls == [.details(id: 7)])
    }

    @Test("Returns the profile unchanged")
    func returnsDetails() async throws {
        let repository = UserRepositoryMock()
        let sut = GetUserDetailsInteractor(repository: repository)

        #expect(try await sut.execute(id: 1) == .fixture)
    }

    @Test("A missing user propagates as .notFound for the detail screen to render")
    func propagatesNotFound() async {
        let repository = UserRepositoryMock()
        repository.detailsResult = .failure(.notFound)
        let sut = GetUserDetailsInteractor(repository: repository)

        await #expect(throws: DomainError.notFound) {
            _ = try await sut.execute(id: 9999)
        }
    }
}

@Suite("FormatBirthDateInteractor")
struct FormatBirthDateInteractorTests {
    @Test("Formats in UTC so the rendered date does not shift with the device's region")
    func formatsInUTC() {
        let date = Date(timeIntervalSince1970: 833_414_400)

        let formatted = FormatBirthDateInteractor().execute(date)

        #expect(formatted.contains("1996"))
        #expect(formatted.contains("30"))
    }
}
