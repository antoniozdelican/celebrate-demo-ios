import Foundation

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
