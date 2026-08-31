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

extension User {
    /// Response → entity.
    ///
    /// Declared in the Data layer, not alongside `User`: extending a Domain type from
    /// here is fine — Data is allowed to know Domain — but the reverse would invert the
    /// dependency rule.
    ///
    /// Mapping is total: it cannot fail. Missing optional strings become `""` and a bad
    /// image URL becomes `nil`, because one malformed row should degrade that row, never
    /// blank the whole screen. Anything genuinely unusable would have failed at decode.
    init(response: UserSummaryResponse) {
        self.init(
            id: response.id,
            firstName: response.firstName?.trimmed ?? "",
            lastName: response.lastName?.trimmed ?? "",
            email: response.email?.trimmed ?? "",
            imageURL: response.image?.nilIfBlank.flatMap(URL.init(string:)),
            jobTitle: response.company?.title?.nilIfBlank
        )
    }
}
