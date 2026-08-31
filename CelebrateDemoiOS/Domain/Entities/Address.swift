import Foundation

struct Address: Equatable, Sendable {
    let street: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?

    var formatted: String {
        [street, city, state, postalCode, country]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
    }
}
