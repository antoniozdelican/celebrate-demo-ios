import Foundation

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
