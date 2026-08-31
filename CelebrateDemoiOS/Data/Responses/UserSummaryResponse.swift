import Foundation

/// A row of `GET /users` (and `GET /users/search`).
///
/// Every field except `id` is optional. DummyJSON's `select` parameter lets us request a
/// subset of columns, and a response model that hard-requires a field would break the
/// moment that list changes. Optionality is resolved once, during mapping.
struct UserSummaryResponse: Decodable, Equatable, Sendable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let email: String?
    let image: String?
    let company: CompanyResponse?
}

// MARK: - Mapping

extension UserSummaryResponse {
    /// Response → entity.
    ///
    /// Mapping is total: it cannot fail. Missing optional strings become `""` and a bad
    /// image URL becomes `nil`, because one malformed row should degrade that row, never
    /// blank the whole screen. Anything genuinely unusable would have failed at decode.
    func toDomain() -> User {
        User(
            id: id,
            firstName: firstName?.trimmed ?? "",
            lastName: lastName?.trimmed ?? "",
            email: email?.trimmed ?? "",
            imageURL: image?.nilIfBlank.flatMap(URL.init(string:)),
            jobTitle: company?.title?.nilIfBlank
        )
    }
}
