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

extension Address {
    init(response: AddressResponse) {
        self.init(
            street: response.address?.nilIfBlank,
            city: response.city?.nilIfBlank,
            state: response.state?.nilIfBlank,
            postalCode: response.postalCode?.nilIfBlank,
            country: response.country?.nilIfBlank
        )
    }
}
