import Foundation

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
    let birthDate: String?
    let image: String?
    let university: String?
    let role: String?
    let company: CompanyResponse?
    let address: AddressResponse?
}

// MARK: - Mapping

extension UserDetails {
    init(response: UserDetailsResponse) {
        self.init(
            id: response.id,
            firstName: response.firstName?.trimmed ?? "",
            lastName: response.lastName?.trimmed ?? "",
            maidenName: response.maidenName?.nilIfBlank,
            email: response.email?.trimmed ?? "",
            phone: response.phone?.nilIfBlank,
            username: response.username?.nilIfBlank,
            age: response.age,
            gender: Gender(apiValue: response.gender),
            birthDate: response.birthDate.flatMap(DummyJSONDate.parse),
            imageURL: response.image?.nilIfBlank.flatMap(URL.init(string:)),
            company: response.company.map(Company.init(response:)),
            address: response.address.map(Address.init(response:)),
            university: response.university?.nilIfBlank,
            role: response.role?.nilIfBlank
        )
    }
}

private extension Gender {
    init(apiValue: String?) {
        switch apiValue?.lowercased().trimmed {
        case "male": self = .male
        case "female": self = .female
        case .some(let value) where !value.isEmpty: self = .other(value)
        default: self = .unspecified
        }
    }
}
