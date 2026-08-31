import Foundation

/// A postal address.
///
/// Every field is optional, so `formatted` is the only safe way to render it as text.
struct Address: Equatable, Sendable {
    let street: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?

    /// Single-line rendering, skipping whatever the API left out.
    ///
    /// Lives here rather than in a view so the joining rule — and the decision to omit
    /// empty components rather than leave ", ," gaps — is stated once.
    var formatted: String {
        [street, city, state, postalCode, country]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
    }
}
