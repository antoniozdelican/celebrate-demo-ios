import Foundation

/// A row of `GET /users` (and `GET /users/search`).
///
/// Every field except `id` is optional. DummyJSON's `select` parameter lets us request a
/// subset of columns, and a DTO that hard-requires a field would break the moment that
/// list changes. Optionality is resolved once, during mapping.
struct UserSummaryDTO: Decodable, Equatable, Sendable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let email: String?
    let image: String?
    let company: CompanyDTO?
}

/// The paginated envelope DummyJSON wraps every collection in.
struct UsersPageDTO: Decodable, Equatable, Sendable {
    let users: [UserSummaryDTO]
    let total: Int
    let skip: Int
    let limit: Int
}

struct CompanyDTO: Decodable, Equatable, Sendable {
    let name: String?
    let title: String?
    let department: String?
}

struct AddressDTO: Decodable, Equatable, Sendable {
    let address: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
}
