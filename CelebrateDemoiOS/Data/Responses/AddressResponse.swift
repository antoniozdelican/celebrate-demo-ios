import Foundation

/// A postal address, nested in the detail payload.
///
/// The API names the street line `address`, which is why the domain entity renames it to
/// `street` — the nesting `address.address` reads as a mistake at every call site.
struct AddressResponse: Decodable, Equatable, Sendable {
    let address: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
}

// MARK: - Mapping

extension AddressResponse {
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
