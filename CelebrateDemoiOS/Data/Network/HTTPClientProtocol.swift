import Foundation

/// A resource-agnostic HTTP transport.
///
/// This is the seam that keeps Alamofire out of the rest of the app. Data sources depend
/// on this protocol, so they can be unit-tested against a trivial in-memory fake, while
/// integration tests exercise the real ``HTTPClient`` with a stubbed `URLProtocol`.
///
/// It knows about verbs, headers, status codes and decoding — never about users,
/// pagination, or DummyJSON.
protocol HTTPClientProtocol: Sendable {
    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: Response.Type
    ) async throws(HTTPError) -> Response
}

extension HTTPClientProtocol {
    /// Sugar for call sites where the return type is already inferable.
    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws(HTTPError) -> Response {
        try await send(endpoint, as: Response.self)
    }
}
