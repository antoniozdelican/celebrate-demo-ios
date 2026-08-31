import Foundation

/// The complete set of failures the presentation layer has to handle.
///
/// Transport-specific errors (`AFError`, `URLError`, `HTTPError`) are translated into
/// these cases at the repository boundary, so no SwiftUI code ever pattern-matches on a
/// networking type. `Equatable` makes error assertions in tests trivial.
enum DomainError: Error, Equatable, Sendable {
    /// No network path to the host.
    case notConnected
    /// The request exceeded its timeout.
    case timedOut
    /// The task was cancelled — usually a superseded search keystroke. Callers should
    /// normally swallow this rather than showing an error state.
    case cancelled
    /// The requested resource does not exist (HTTP 404).
    case notFound
    /// The server answered, but not successfully.
    case server(statusCode: Int)
    /// The server answered successfully but the payload could not be understood.
    case invalidResponse
    /// Anything we could not classify.
    case unknown
}

extension DomainError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConnected: "You appear to be offline."
        case .timedOut: "The request took too long to complete."
        case .cancelled: "The request was cancelled."
        case .notFound: "We couldn't find that user."
        case .server(let statusCode): "The server returned an error (\(statusCode))."
        case .invalidResponse: "We received an unexpected response from the server."
        case .unknown: "Something went wrong."
        }
    }

    /// Whether offering a "Try again" affordance makes sense for this failure.
    var isRetryable: Bool {
        switch self {
        case .notConnected, .timedOut, .server, .unknown: true
        case .cancelled, .notFound, .invalidResponse: false
        }
    }
}
