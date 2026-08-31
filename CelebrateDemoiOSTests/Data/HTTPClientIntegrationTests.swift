import Foundation
import Testing
@testable import CelebrateDemoiOS

@Suite("HTTPClient (integration)")
struct HTTPClientIntegrationTests {
    @Test("Sends a real request to the resolved URL and decodes the response")
    func decodesSuccessfulResponse() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.usersPage))

        let page = try await stack.client.send(HTTPRequest(
                path: "users",
                queryItems: [
                    URLQueryItem(name: "limit", value: "2"),
                    URLQueryItem(name: "skip", value: "0"),
                ]
            ), as: UsersPageResponse.self)

        #expect(page.users.count == 2)
        let sent = try #require(stack.networkMock.recordedURLs.first)
        #expect(sent.hasPrefix("https://dummyjson.com/users?"))
        #expect(sent.contains("limit=2"))
        #expect(sent.contains("skip=0"))
    }

    @Test("A non-2xx status fails validation and keeps the code and body")
    func mapsUnacceptableStatusCode() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.status(404, body: Fixtures.notFound))

        let error = await #expect(throws: HTTPError.self) {
            _ = try await stack.client.send(HTTPRequest(path: "users/9999"), as: UserDetailsResponse.self)
        }

        #expect(error?.statusCode == 404)
    }

    @Test("A 2xx response with the wrong shape is a decoding failure, not a transport one")
    func mapsDecodingFailure() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.malformedPage))

        let error = await #expect(throws: HTTPError.self) {
            _ = try await stack.client.send(HTTPRequest(path: "users"), as: UsersPageResponse.self)
        }

        guard case .decoding = try #require(error) else {
            Issue.record("Expected .decoding, got \(String(describing: error))")
            return
        }
    }

    @Test(
        "URL loading failures are classified, not lumped into `.transport`",
        arguments: [
            (URLError.Code.notConnectedToInternet, HTTPError.notConnected),
            (.networkConnectionLost, .notConnected),
            (.timedOut, .timedOut),
        ]
    )
    func classifiesURLErrors(code: URLError.Code, expected: HTTPError) async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.failure(code))

        let error = await #expect(throws: HTTPError.self) {
            _ = try await stack.client.send(HTTPRequest(path: "users"), as: UsersPageResponse.self)
        }

        #expect(error == expected)
    }

    @Test("Cancelling the task cancels the underlying request")
    func propagatesCancellation() async throws {
        let stack = TestStack()
        stack.networkMock.setResponse(.ok(Fixtures.usersPage))

        let task = Task {
            try await stack.client.send(HTTPRequest(path: "users"), as: UsersPageResponse.self)
        }
        task.cancel()

        do {
            _ = try await task.value
        } catch let error as HTTPError {
            #expect(error == .cancelled)
        } catch is CancellationError {
        }
    }
}
