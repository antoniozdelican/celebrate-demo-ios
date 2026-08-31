#if DEBUG
import Foundation

/// Fixture-backed repository used only by UI tests.
///
/// UI tests run the app in a separate process, so the `URLProtocol` stub the integration
/// tests use cannot reach it. Swapping the repository at the composition root is what
/// makes error and empty states reachable at all — the live API will not return a 500 on
/// request — and it keeps the tests off the network, so they are deterministic.
struct MockUserRepository: UserRepositoryProtocol {
    enum Scenario: String {
        case success
        case empty
        case error
    }

    let scenario: Scenario

    private static let all: [User] = [
        User(id: 1, firstName: "Emily", lastName: "Johnson", email: "emily@example.com", imageURL: nil, jobTitle: "Sales Manager"),
        User(id: 2, firstName: "Michael", lastName: "Williams", email: "michael@example.com", imageURL: nil, jobTitle: "Support Specialist"),
        User(id: 3, firstName: "Sophia", lastName: "Brown", email: "sophia@example.com", imageURL: nil, jobTitle: "Accountant"),
        User(id: 4, firstName: "James", lastName: "Davis", email: "james@example.com", imageURL: nil, jobTitle: "Research Analyst"),
        User(id: 5, firstName: "Emma", lastName: "Miller", email: "emma@example.com", imageURL: nil, jobTitle: "Quality Assurance Engineer"),
        User(id: 6, firstName: "Olivia", lastName: "Wilson", email: "olivia@example.com", imageURL: nil, jobTitle: "Research Analyst"),
    ]

    func users(limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        switch scenario {
        case .error: throw .notConnected
        case .empty: return Page(items: [], total: 0, skip: 0, limit: limit)
        case .success: return page(from: Self.all, limit: limit, skip: skip)
        }
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        switch scenario {
        case .error: throw .notConnected
        case .empty: return Page(items: [], total: 0, skip: 0, limit: limit)
        case .success:
            let matches = Self.all.filter { $0.fullName.localizedCaseInsensitiveContains(query) }
            return page(from: matches, limit: limit, skip: skip)
        }
    }

    func userDetails(id: Int) async throws(DomainError) -> UserDetails {
        switch scenario {
        case .error: throw .notConnected
        case .empty, .success:
            guard let user = Self.all.first(where: { $0.id == id }) else { throw .notFound }
            return UserDetails(
                id: user.id,
                firstName: user.firstName,
                lastName: user.lastName,
                maidenName: nil,
                email: user.email,
                phone: "+1 555 0100",
                username: user.firstName.lowercased(),
                age: 28,
                gender: .female,
                birthDate: Date(timeIntervalSince1970: 833_414_400),
                imageURL: nil,
                company: Company(name: "Dooley, Kozey and Cronin", title: user.jobTitle, department: "Engineering"),
                address: Address(street: "626 Main Street", city: "Phoenix", state: "Arizona", postalCode: "29112", country: "United States"),
                university: "University of Wisconsin",
                role: "admin"
            )
        }
    }

    private func page(from users: [User], limit: Int, skip: Int) -> Page<User> {
        let slice = Array(users.dropFirst(skip).prefix(limit))
        return Page(items: slice, total: users.count, skip: skip, limit: limit)
    }
}
#endif
