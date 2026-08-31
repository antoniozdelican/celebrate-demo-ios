import Foundation
import Testing
@testable import CelebrateDemoiOS

/// End-to-end through the data stack: `UserRepository` → `UserRemoteDataSource` →
/// `HTTPClient` → Alamofire → stubbed wire. Nothing between the repository and the
/// socket is mocked.
///
/// This is the suite that catches a wrong query parameter, a decoder misconfigured for
/// the real payload, broken pagination arithmetic, or an error reaching the presentation
/// layer as the wrong `DomainError`.
@Suite("UserRepository (integration)")
struct UserRepositoryIntegrationTests {
    // MARK: - Listing

    @Test("Fetches, decodes and maps a page all the way to domain entities")
    func fetchesFirstPage() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.usersPage))

        let page = try await stack.repository.users(limit: 2, skip: 0)

        #expect(page.items.count == 2)
        #expect(page.total == 208)
        #expect(page.items.first?.fullName == "Emily Johnson")
        #expect(page.items.first?.jobTitle == "Sales Manager")
        #expect(page.hasMore)
        #expect(page.nextSkip == 2)
    }

    @Test("Paginates: the second request uses the offset the first page reported")
    func paginatesAcrossTwoRealRequests() async throws {
        let stack = TestStack()
        stack.networkMock.setHandler { request in
            let query = request.url?.query ?? ""
            return query.contains("skip=2") ? .ok(Fixtures.usersPageTwo) : .ok(Fixtures.usersPage)
        }

        let first = try await stack.repository.users(limit: 2, skip: 0)
        let nextSkip = try #require(first.nextSkip)
        let second = try await stack.repository.users(limit: 2, skip: nextSkip)

        #expect(second.items.map(\.id) == [3])
        #expect(second.skip == 2)
        // Two distinct requests actually left the repository.
        #expect(stack.networkMock.recordedURLs.count == 2)
        #expect(stack.networkMock.recordedURLs[1].contains("skip=2"))
    }

    @Test("The final page reports no further offset, terminating infinite scroll")
    func stopsAtLastPage() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.usersLastPage))

        let page = try await stack.repository.users(limit: 2, skip: 207)

        #expect(!page.hasMore)
        #expect(page.nextSkip == nil)
    }

    @Test("An empty collection is a success with no items, not an error")
    func emptyCollectionIsNotAnError() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.emptyPage))

        let page = try await stack.repository.users(limit: 30, skip: 0)

        #expect(page.items.isEmpty)
        #expect(page.total == 0)
        #expect(!page.hasMore)
    }

    // MARK: - Search

    @Test("Search hits /users/search and maps the subset")
    func searchesUsers() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.searchResults))

        let page = try await stack.repository.searchUsers(query: "Emily", limit: 30, skip: 0)

        #expect(page.items.count == 1)
        #expect(page.items.first?.firstName == "Emily")
        let url = try #require(stack.networkMock.recordedURLs.first)
        #expect(url.contains("/users/search"))
        #expect(url.contains("q=Emily"))
    }

    @Test("A blank query short-circuits: no request, empty page")
    func blankSearchDoesNotHitTheNetwork() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.searchResults))

        let page = try await stack.repository.searchUsers(query: "   ", limit: 30, skip: 0)

        #expect(page.items.isEmpty)
        // `q=` would return the *unfiltered* collection, which reads as "search matched
        // everything". Not sending the request at all is the correct behaviour.
        #expect(stack.networkMock.recordedURLs.isEmpty)
    }

    @Test("Search terms are trimmed before they reach the wire")
    func trimsSearchQuery() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.searchResults))

        _ = try await stack.repository.searchUsers(query: "  Emily  ", limit: 30, skip: 0)

        let url = try #require(stack.networkMock.recordedURLs.first)
        #expect(url.contains("q=Emily&"))
    }

    // MARK: - Details

    @Test("Fetches and maps a full profile, ignoring fields we chose not to model")
    func fetchesUserDetails() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.userDetails))

        let details = try await stack.repository.userDetails(id: 1)

        #expect(details.id == 1)
        #expect(details.fullName == "Emily Johnson")
        #expect(details.gender == .female)
        #expect(details.company?.title == "Sales Manager")
        #expect(details.address?.city == "Phoenix")
        #expect(details.birthDate != nil)
        #expect(stack.networkMock.recordedURLs.first?.hasSuffix("/users/1") == true)
    }

    // MARK: - Error translation

    @Test("404 on a detail fetch becomes .notFound, the case the detail screen renders")
    func missingUserBecomesNotFound() async {
        let stack = TestStack()
        stack.networkMock.setResponse(.status(404, body: Fixtures.notFound))

        await #expect(throws: DomainError.notFound) {
            _ = try await stack.repository.userDetails(id: 9999)
        }
    }

    @Test("A server fault keeps its status code so the UI can offer a retry")
    func serverFaultBecomesServerError() async {
        let stack = TestStack()
        stack.networkMock.setResponse(.status(503))

        await #expect(throws: DomainError.server(statusCode: 503)) {
            _ = try await stack.repository.users(limit: 30, skip: 0)
        }
    }

    @Test("Being offline surfaces as .notConnected, not a generic failure")
    func offlineBecomesNotConnected() async {
        let stack = TestStack()
        stack.networkMock.setResponse(.failure(.notConnectedToInternet))

        await #expect(throws: DomainError.notConnected) {
            _ = try await stack.repository.users(limit: 30, skip: 0)
        }
    }

    @Test("A timeout surfaces as .timedOut")
    func timeoutBecomesTimedOut() async {
        let stack = TestStack()
        stack.networkMock.setResponse(.failure(.timedOut))

        await #expect(throws: DomainError.timedOut) {
            _ = try await stack.repository.users(limit: 30, skip: 0)
        }
    }

    @Test("An unparseable payload surfaces as .invalidResponse, never as a crash")
    func malformedPayloadBecomesInvalidResponse() async {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.malformedPage))

        await #expect(throws: DomainError.invalidResponse) {
            _ = try await stack.repository.users(limit: 30, skip: 0)
        }
    }
}
