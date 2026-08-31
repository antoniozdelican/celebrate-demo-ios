import Foundation

/// The `GET /users/{id}` payload — or rather, the slice of it we care about.
///
/// DummyJSON returns ~30 fields including `password`, `ssn`, `ein`, `macAddress` and
/// bank details. Those are deliberately not modelled: undeclared keys are ignored by
/// `Codable`, and not decoding credentials keeps them out of memory entirely.
struct UserDetailsResponse: Decodable, Equatable, Sendable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let maidenName: String?
    let email: String?
    let phone: String?
    let username: String?
    let age: Int?
    let gender: String?
    /// Unpadded `"yyyy-M-d"` — for example `"1996-5-30"`, which both ISO-8601 and a
    /// `yyyy-MM-dd` formatter reject.
    ///
    /// Deliberately carried as a `String` and parsed during mapping rather than by a
    /// decoder date strategy: there, an unparseable value degrades to `nil` instead of
    /// failing the entire response.
    let birthDate: String?
    let image: String?
    let university: String?
    let role: String?
    let company: CompanyResponse?
    let address: AddressResponse?
}

// MARK: - Mapping

extension UserDetailsResponse {
    func toDomain() -> UserDetails {
        UserDetails(
            id: id,
            firstName: firstName?.trimmed ?? "",
            lastName: lastName?.trimmed ?? "",
            maidenName: maidenName?.nilIfBlank,
            email: email?.trimmed ?? "",
            phone: phone?.nilIfBlank,
            username: username?.nilIfBlank,
            age: age,
            gender: UserDetails.Gender(apiValue: gender),
            birthDate: birthDate.flatMap(DummyJSONDate.parse),
            imageURL: image?.nilIfBlank.flatMap(URL.init(string:)),
            company: company?.toDomain(),
            address: address?.toDomain(),
            university: university?.nilIfBlank,
            role: role?.nilIfBlank
        )
    }
}

private extension UserDetails.Gender {
    /// Unknown values are preserved rather than discarded, so the UI can display
    /// whatever the API sends without this enum knowing it in advance.
    init(apiValue: String?) {
        switch apiValue?.lowercased().trimmed {
        case "male": self = .male
        case "female": self = .female
        case .some(let value) where !value.isEmpty: self = .other(value)
        default: self = .unspecified
        }
    }
}
