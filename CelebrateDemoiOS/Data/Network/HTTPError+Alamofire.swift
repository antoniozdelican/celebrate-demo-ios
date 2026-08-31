import Alamofire
import Foundation

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
