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
