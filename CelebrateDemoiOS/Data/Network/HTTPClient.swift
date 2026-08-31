import Alamofire
import Foundation

/// Alamofire-backed implementation of ``HTTPClientProtocol``.
///
/// **This is one of only two files in the project that import Alamofire** (the other
/// being `HTTPError+Alamofire`). Everything above it speaks in `Endpoint` / `HTTPError`,
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
        _ endpoint: Endpoint,
        as type: Response.Type
    ) async throws(HTTPError) -> Response {
        let request = try endpoint.urlRequest(baseURL: baseURL)

        let dataResponse = await session
            .request(request)
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
