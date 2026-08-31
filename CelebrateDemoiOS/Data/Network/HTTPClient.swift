import Alamofire
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
        _ request: HTTPRequest,
        as type: Response.Type
    ) async throws(HTTPError) -> Response
}

/// Alamofire-backed implementation of ``HTTPClientProtocol``.
///
/// **This is one of only two files in the project that import Alamofire** (the other
/// being `HTTPError`). Everything above it speaks in `HTTPRequest` / `HTTPError`,
/// so replacing Alamofire with `URLSession` — or adding certificate pinning, auth
/// refresh or logging — is a change confined to this type.
///
/// What Alamofire buys us over raw `URLSession`: `validate()` and response
/// serialization with automatic task cancellation.
final class HTTPClient: HTTPClientProtocol {
    /// Session configuration this client expects in production.
    ///
    /// Timeouts are tuned for a list/detail app: fail fast enough that the retry button
    /// is reachable before the user gives up. Computed rather than stored, since
    /// `URLSessionConfiguration` is a mutable reference type and each caller should get
    /// its own copy.
    static var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = false
        return configuration
    }

    private let baseURL: URL
    private let session: Session

    /// - Parameters:
    ///   - baseURL: the only value that genuinely varies in production.
    ///   - configuration: defaulted, and injected for one reason — integration tests
    ///     install a stub `URLProtocol` through `protocolClasses`. Setting it on the
    ///     configuration is the only reliable way to intercept `URLSession` traffic, so
    ///     without this parameter this type could not be tested at all.
    ///
    /// No `RequestInterceptor` is attached: failed requests are surfaced to the user via
    /// `DomainError.isRetryable` and a retry affordance, rather than retried silently.
    /// Automatic retry doubles latency during a real outage and hides the failure.
    init(baseURL: URL, configuration: URLSessionConfiguration = HTTPClient.configuration) {
        self.baseURL = baseURL
        self.session = Session(configuration: configuration)
    }

    func send<Response: Decodable & Sendable>(
        _ request: HTTPRequest,
        as type: Response.Type
    ) async throws(HTTPError) -> Response {
        let urlRequest = try request.urlRequest(baseURL: baseURL)

        let dataResponse = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingDecodable(Response.self)
            .response

        switch dataResponse.result {
        case .success(let value):
            return value
        case .failure(let error):
            throw HTTPError(error, responseData: dataResponse.data)
        }
    }
}
