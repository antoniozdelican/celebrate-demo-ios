import Foundation

/// The full profile shown on the detail screen.
///
/// A separate type from ``User`` rather than an extension of it: the two come from
/// different endpoints with different guarantees, and modelling them separately keeps
/// the list screen from accidentally depending on fields it never fetched.
struct UserDetails: Identifiable, Equatable, Sendable {
    let id: Int
    let firstName: String
    let lastName: String
    let maidenName: String?
    let email: String
    let phone: String?
    let username: String?
    let age: Int?
    let gender: Gender
    let birthDate: Date?
    let imageURL: URL?
    let company: Company?
    let address: Address?
    let university: String?
    let role: String?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
