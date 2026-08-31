import Foundation
@testable import CelebrateDemoiOS

/// In-memory ``HTTPClientProtocol`` for unit-testing the data source in isolation.
///
/// Hand-written rather than generated: Swift has no runtime mocking, and a fake this
/// small is clearer than any framework that would produce it.
final class HTTPClientMock: HTTPClientProtocol, @unchecked Sendable {
    /// What `send` should do next. Success carries `Data`, so the spy still exercises the
    /// real response shape rather than letting a wrong type slip through.
    enum Outcome: Sendable {
        case success(Data)
        case failure(HTTPError)
    }

    private let lock = NSLock()
    private var outcome: Outcome
    private var _requests: [HTTPRequest] = []

    init(outcome: Outcome = .success(Data("{}".utf8))) {
        self.outcome = outcome
    }

    /// Requests the subject under test sent, in order.
    var requests: [HTTPRequest] { lock.withLock { _requests } }

    func set(_ outcome: Outcome) { lock.withLock { self.outcome = outcome } }

    func send<Response: Decodable & Sendable>(
        _ request: HTTPRequest,
        as type: Response.Type
    ) async throws(HTTPError) -> Response {
        let current: Outcome = lock.withLock {
            _requests.append(request)
            return outcome
        }

        switch current {
        case .failure(let error):
            throw error
        case .success(let data):
            do {
                return try JSONDecoder().decode(Response.self, from: data)
            } catch {
                throw .decoding(description: String(describing: error))
            }
        }
    }
}

extension HTTPRequest {
    /// Convenience for asserting on query encoding without rebuilding a `URLRequest`.
    func queryValue(_ name: String) -> String? {
        queryItems.first { $0.name == name }?.value
    }
}
