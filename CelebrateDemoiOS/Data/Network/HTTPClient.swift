import Alamofire
import Foundation

/// Alamofire-backed implementation of ``HTTPClientProtocol``.
///
/// **This is one of only two files in the project that import Alamofire** (the other
/// being `HTTPError+Alamofire`). Everything above it speaks in `Endpoint` / `HTTPError`,
/// so replacing Alamofire with `URLSession` — or adding certificate pinning, auth
/// refresh or logging — is a change confined to this type.
///
/// What Alamofire buys us over raw `URLSession`: `validate()`, response serialization
/// with automatic task cancellation, and `RequestInterceptor`-based retry.
final class HTTPClient: HTTPClientProtocol {
    private let baseURL: URL
    private let session: Session
    private let decoder: JSONDecoder

    /// Designated initialiser.
    /// - Parameter session: injected so integration tests can supply a `Session` whose
    ///   `URLSessionConfiguration` carries a stub `URLProtocol`.
    init(baseURL: URL, session: Session, decoder: JSONDecoder = .dummyJSON) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    /// Production initialiser, with sensible timeouts and a bounded retry policy.
    convenience init(
        baseURL: URL,
        configuration: URLSessionConfiguration = .celebrate,
        decoder: JSONDecoder = .dummyJSON
    ) {
        let session = Session(configuration: configuration, interceptor: RetryPolicy(retryLimit: 2))
        self.init(baseURL: baseURL, session: session, decoder: decoder)
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: Response.Type
    ) async throws(HTTPError) -> Response {
        let request = try endpoint.urlRequest(baseURL: baseURL)

        let dataResponse = await session
            .request(request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(Response.self, decoder: decoder)
            .response

        switch dataResponse.result {
        case .success(let value):
            return value
        case .failure(let error):
            throw HTTPError(error, responseData: dataResponse.data)
        }
    }
}

extension URLSessionConfiguration {
    /// Timeouts tuned for a list/detail app: fail fast enough that the retry button is
    /// reachable before the user gives up.
    static var celebrate: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = false
        return configuration
    }
}
