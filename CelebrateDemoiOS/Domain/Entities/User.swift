import Foundation

/// A user as shown in the list screen.
///
/// Deliberately lean: it carries only what a row needs to render. Richer data lives in
/// ``UserDetails`` and is fetched on demand, which keeps the list payload small and the
/// list cheap to diff.
struct User: Identifiable, Equatable, Sendable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let imageURL: URL?
    /// Job title, used as the secondary line in a list row. Optional: the API may omit it.
    let jobTitle: String?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    /// Uppercased initials, used as the avatar placeholder while the image loads.
    var initials: String {
        [firstName, lastName]
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}
