import Foundation

enum DomainError: Error, Equatable, Sendable {
    case notConnected
    case timedOut
    case cancelled
    case notFound
    case server(statusCode: Int)
    case invalidResponse
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

    var isRetryable: Bool {
        switch self {
        case .notConnected, .timedOut, .server, .unknown: true
        case .cancelled, .notFound, .invalidResponse: false
        }
    }
}
