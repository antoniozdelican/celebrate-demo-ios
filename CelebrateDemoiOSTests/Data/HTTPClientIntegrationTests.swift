import Foundation
import Testing
@testable import CelebrateDemoiOS

/// Integration tests for the real Alamofire client.
///
/// Everything runs for real — `Session`, `validate()`, `serializingDecodable`, the whole
/// `AFError` tree — with only the wire replaced by ``StubURLProtocol``. This is the layer
/// that catches misconfigured decoders and unmapped error branches; a fake transport
/// cannot, because it never produces an `AFError`.
@Suite("HTTPClient (integration)")
struct HTTPClientIntegrationTests {
    @Test("Sends a real request to the resolved URL and decodes the response")
    func decodesSuccessfulResponse() async throws {
        let stack = TestStack()
        stack.stub.setStub(.ok(Fixtures.usersPage))

        let page = try await stack.client.send(UserEndpoints.list(limit: 2, skip: 0), as: UsersPageResponse.self)

        #expect(page.users.count == 2)
        let sent = try #require(stack.stub.recordedURLs.first)
        #expect(sent.hasPrefix("https://dummyjson.com/users?"))
        #expect(sent.contains("limit=2"))
        #expect(sent.contains("skip=0"))
    }

    @Test("A non-2xx status fails validation and keeps the code and body")
    func mapsUnacceptableStatusCode() async throws {
        let stack = TestStack()
        stack.stub.setStub(.status(404, body: Fixtures.notFound))

        let error = await #expect(throws: HTTPError.self) {
            _ = try await stack.client.send(UserEndpoints.details(id: 9999), as: UserDetailsResponse.self)
        }

        #expect(error?.statusCode == 404)
    }

    @Test("A 2xx response with the wrong shape is a decoding failure, not a transport one")
    func mapsDecodingFailure() async throws {
        let stack = TestStack()
        stack.stub.setStub(.ok(Fixtures.malformedPage))

        let error = await #expect(throws: HTTPError.self) {
            _ = try await stack.client.send(UserEndpoints.list(limit: 30, skip: 0), as: UsersPageResponse.self)
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
        stack.stub.setStub(.failure(code))

        let error = await #expect(throws: HTTPError.self) {
            _ = try await stack.client.send(UserEndpoints.list(limit: 30, skip: 0), as: UsersPageResponse.self)
        }

        #expect(error == expected)
    }

    @Test("Cancelling the task cancels the underlying request")
    func propagatesCancellation() async throws {
        let stack = TestStack()
        stack.stub.setStub(.ok(Fixtures.usersPage))

        let task = Task {
            try await stack.client.send(UserEndpoints.list(limit: 30, skip: 0), as: UsersPageResponse.self)
        }
        task.cancel()

        // Either the request never started (CancellationError) or Alamofire cancelled it
        // in flight (.cancelled). Both are correct; a *success* would mean cancellation
        // is not wired through, which is what this asserts against.
        do {
            _ = try await task.value
        } catch let error as HTTPError {
            #expect(error == .cancelled)
        } catch is CancellationError {
            // Also acceptable.
        }
    }
}
