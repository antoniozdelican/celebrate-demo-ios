import Foundation

struct User: Identifiable, Equatable, Sendable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let imageURL: URL?
    let jobTitle: String?

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
