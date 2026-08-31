import Foundation

/// The HTTP verbs an ``Endpoint`` can use.
///
/// Raw values are the wire representation, so `URLRequest.httpMethod` is a direct
/// assignment. Deliberately not Alamofire's `HTTPMethod`: `Endpoint` is meant to be
/// describable — and assertable in tests — without importing a networking library.
enum HTTPMethod: String, Equatable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
