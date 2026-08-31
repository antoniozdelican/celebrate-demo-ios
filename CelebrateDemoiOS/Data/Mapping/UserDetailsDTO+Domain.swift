import Foundation

extension UserDetailsDTO {
    func toDomain() -> UserDetails {
        UserDetails(
            id: id,
            firstName: firstName?.trimmed ?? "",
            lastName: lastName?.trimmed ?? "",
            maidenName: maidenName?.nilIfBlank,
            email: email?.trimmed ?? "",
            phone: phone?.nilIfBlank,
            username: username?.nilIfBlank,
            age: age,
            gender: UserDetails.Gender(apiValue: gender),
            birthDate: birthDate.flatMap(DummyJSONDate.parse),
            imageURL: image?.nilIfBlank.flatMap(URL.init(string:)),
            company: company?.toDomain(),
            address: address?.toDomain(),
            university: university?.nilIfBlank,
            role: role?.nilIfBlank
        )
    }
}

extension CompanyDTO {
    func toDomain() -> UserDetails.Company {
        UserDetails.Company(
            name: name?.nilIfBlank,
            title: title?.nilIfBlank,
            department: department?.nilIfBlank
        )
    }
}

extension AddressDTO {
    func toDomain() -> UserDetails.Address {
        UserDetails.Address(
            street: address?.nilIfBlank,
            city: city?.nilIfBlank,
            state: state?.nilIfBlank,
            postalCode: postalCode?.nilIfBlank,
            country: country?.nilIfBlank
        )
    }
}

private extension UserDetails.Gender {
    /// Unknown values are preserved rather than discarded, so the UI can display
    /// whatever the API sends without this enum knowing it in advance.
    init(apiValue: String?) {
        switch apiValue?.lowercased().trimmed {
        case "male": self = .male
        case "female": self = .female
        case .some(let value) where !value.isEmpty: self = .other(value)
        default: self = .unspecified
        }
    }
}

/// Parser for DummyJSON's unpadded `"1996-5-30"` birth dates.
///
/// A fixed `en_US_POSIX` locale and UTC calendar keep parsing independent of the device's
/// region — the classic source of "works on my machine" date bugs — and make the result
/// stable in snapshot tests.
enum DummyJSONDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-M-d"
        return formatter
    }()

    static func parse(_ value: String) -> Date? {
        formatter.date(from: value.trimmed)
    }
}
