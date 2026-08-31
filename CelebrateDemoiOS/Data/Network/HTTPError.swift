import Alamofire
import Foundation

/// Failures the transport layer can produce.
///
/// Lives in the Data layer and stops there: ``UserRepository`` translates it into
/// `DomainError`. Kept `Equatable` and `Sendable` — hence `String` rather than the
/// underlying `Error` in the associated values — so tests can assert on exact cases.
enum HTTPError: Error, Equatable, Sendable {
    case invalidURL
    case notConnected
    case timedOut
    case cancelled
    /// A response was received with a non-2xx status. `data` is the raw body, kept for
    /// diagnostics and for endpoints that return structured error payloads.
    case status(code: Int, data: Data?)
    /// A 2xx response whose body did not match the expected shape.
    case decoding(description: String)
    /// Anything else the URL loading system reported.
    case transport(description: String)

    var statusCode: Int? {
        if case .status(let code, _) = self { return code }
        return nil
    }
}

extension HTTPError {
    /// Collapses Alamofire's deep, nested error tree into the handful of cases the rest
    /// of the app can act on.
    ///
    /// Keeping this translation next to the client — rather than in a `catch` at every
    /// call site — means `AFError` appears exactly once in the codebase.
    init(_ error: any Error, responseData: Data?) {
        switch error {
        case let afError as AFError:
            self = HTTPError(afError: afError, responseData: responseData)
        case let urlError as URLError:
            self = HTTPError(urlError: urlError)
        case is CancellationError:
            self = .cancelled
        default:
            self = .transport(description: String(describing: error))
        }
    }

    private init(afError: AFError, responseData: Data?) {
        switch afError {
        case .explicitlyCancelled:
            self = .cancelled

        case .responseValidationFailed(reason: .unacceptableStatusCode(let code)):
            self = .status(code: code, data: responseData)

        case .responseSerializationFailed(reason: .decodingFailed(let underlying)):
            self = .decoding(description: String(describing: underlying))

        case .responseSerializationFailed(reason: .inputDataNilOrZeroLength):
            self = .decoding(description: "Empty response body")

        case .sessionTaskFailed(let underlying):
            if let urlError = underlying as? URLError {
                self = HTTPError(urlError: urlError)
            } else {
                self = .transport(description: String(describing: underlying))
            }

        case .createURLRequestFailed, .invalidURL:
            self = .invalidURL

        default:
            // A non-2xx that carried a body reaches us as a validation failure above;
            // anything left here is genuinely unclassified.
            self = .transport(description: afError.localizedDescription)
        }
    }

    private init(urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotConnectToHost:
            self = .notConnected
        case .timedOut:
            self = .timedOut
        case .cancelled:
            self = .cancelled
        case .badURL, .unsupportedURL:
            self = .invalidURL
        default:
            self = .transport(description: urlError.localizedDescription)
        }
    }
}

// MARK: - Mapping

extension HTTPError {
    /// Transport failure → domain failure.
    ///
    /// This is the boundary the whole layering rests on: above it, nothing knows what
    /// HTTP is. `404` becomes `.notFound` because "this user doesn't exist" is a domain
    /// fact the detail screen must render, whereas `500` stays a generic server error.
    ///
    /// Expressed as `HTTPError.toDomain()` rather than `DomainError.init(_:)` so the
    /// conversion sits on the Data type, matching the response mapping and keeping every
    /// reference to `HTTPError` inside the Data layer.
    func toDomain() -> DomainError {
        switch self {
        case .notConnected: .notConnected
        case .timedOut: .timedOut
        case .cancelled: .cancelled
        case .status(let code, _) where code == 404: .notFound
        case .status(let code, _): .server(statusCode: code)
        case .decoding: .invalidResponse
        case .invalidURL, .transport: .unknown
        }
    }
}
