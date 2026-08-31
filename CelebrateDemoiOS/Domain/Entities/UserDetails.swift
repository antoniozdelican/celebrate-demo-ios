import Foundation

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

    var initials: String {
        [firstName, lastName]
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}
