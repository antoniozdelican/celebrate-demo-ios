import Foundation
@testable import CelebrateDemoiOS

extension User {
    static func fixture(
        id: Int = 1,
        firstName: String = "Emily",
        lastName: String = "Johnson"
    ) -> User {
        User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: "\(firstName.lowercased())@example.com",
            imageURL: nil,
            jobTitle: "Sales Manager"
        )
    }
}

extension UserDetails {
    static let fixture = UserDetails(
        id: 1,
        firstName: "Emily",
        lastName: "Johnson",
        maidenName: nil,
        email: "emily@example.com",
        phone: nil,
        username: nil,
        age: 28,
        gender: .female,
        birthDate: nil,
        imageURL: nil,
        company: nil,
        address: nil,
        university: nil,
        role: nil
    )
}

extension Page where Item == User {
    /// A page of `count` users starting at `skip`, with `total` available overall.
    static func fixture(count: Int, skip: Int = 0, total: Int) -> Page<User> {
        Page(
            items: (0..<count).map { User.fixture(id: skip + $0 + 1, firstName: "User\(skip + $0 + 1)") },
            total: total,
            skip: skip,
            limit: count
        )
    }
}
