import Foundation

/// The `GET /users/{id}` payload — or rather, the slice of it we care about.
///
/// DummyJSON returns ~30 fields including `password`, `ssn`, `ein`, `macAddress` and
/// bank details. Those are deliberately not modelled: undeclared keys are ignored by
/// `Codable`, and not decoding credentials keeps them out of memory entirely.
struct UserDetailsDTO: Decodable, Equatable, Sendable {
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
    let company: CompanyDTO?
    let address: AddressDTO?
}
