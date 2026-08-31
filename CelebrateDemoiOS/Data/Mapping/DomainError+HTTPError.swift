import Foundation

extension DomainError {
    /// Transport failure → domain failure.
    ///
    /// This is the boundary the whole layering rests on: above it, nothing knows what
    /// HTTP is. `404` becomes `.notFound` because "this user doesn't exist" is a domain
    /// fact the detail screen must render, whereas `500` stays a generic server error.
    init(_ error: HTTPError) {
        switch error {
        case .notConnected: self = .notConnected
        case .timedOut: self = .timedOut
        case .cancelled: self = .cancelled
        case .status(let code, _) where code == 404: self = .notFound
        case .status(let code, _): self = .server(statusCode: code)
        case .decoding: self = .invalidResponse
        case .invalidURL, .transport: self = .unknown
        }
    }
}
