import Foundation
import Testing
@testable import CelebrateDemoiOS

/// Unit tests: the data source against a fake transport. No Alamofire involved.
@Suite("UserRemoteDataSource")
struct UserRemoteDataSourceTests {
    @Test("Decodes a page and forwards the pagination envelope untouched")
    func decodesUsersPage() async throws {
        let client = HTTPClientSpy(outcome: .success(Fixtures.usersPage))
        let sut = UserRemoteDataSource(client: client)

        let page = try await sut.users(limit: 2, skip: 0)

        #expect(page.users.count == 2)
        #expect(page.total == 208)
        #expect(page.skip == 0)
        #expect(page.users.first?.firstName == "Emily")
        #expect(page.users.first?.company?.title == "Sales Manager")
    }

    @Test("Asks for the endpoint the caller's parameters describe")
    func requestsCorrectEndpoint() async throws {
        let client = HTTPClientSpy(outcome: .success(Fixtures.usersPage))
        let sut = UserRemoteDataSource(client: client)

        _ = try await sut.users(limit: 50, skip: 100)

        let endpoint = try #require(client.endpoints.first)
        #expect(endpoint.path == "users")
        #expect(endpoint.queryValue("limit") == "50")
        #expect(endpoint.queryValue("skip") == "100")
    }

    @Test("Ignores the fields we deliberately do not model")
    func ignoresUnmodelledFields() async throws {
        // `password`, `ssn` and `bloodGroup` are in the fixture and absent from the DTO.
        let client = HTTPClientSpy(outcome: .success(Fixtures.userDetails))
        let sut = UserRemoteDataSource(client: client)

        let details = try await sut.userDetails(id: 1)

        #expect(details.username == "emilys")
        #expect(details.birthDate == "1996-5-30")
    }

    @Test("Propagates transport failures unchanged — translation is not its job")
    func propagatesTransportError() async {
        let client = HTTPClientSpy(outcome: .failure(.status(code: 500, data: nil)))
        let sut = UserRemoteDataSource(client: client)

        await #expect(throws: HTTPError.status(code: 500, data: nil)) {
            _ = try await sut.users(limit: 30, skip: 0)
        }
    }

    @Test("Reports a shape mismatch as a decoding failure")
    func reportsDecodingFailure() async {
        let client = HTTPClientSpy(outcome: .success(Fixtures.malformedPage))
        let sut = UserRemoteDataSource(client: client)

        await #expect(throws: HTTPError.self) {
            _ = try await sut.users(limit: 30, skip: 0)
        }
    }
}
