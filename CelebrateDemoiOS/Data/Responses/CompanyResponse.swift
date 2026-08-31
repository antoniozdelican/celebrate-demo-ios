import Foundation

/// Employment details, nested in both the summary and the detail payloads.
///
/// The API also returns the company's own address here; it is deliberately not modelled,
/// since nothing in the app displays it.
struct CompanyResponse: Decodable, Equatable, Sendable {
    let name: String?
    let title: String?
    let department: String?
}

// MARK: - Mapping

extension CompanyResponse {
    func toDomain() -> UserDetails.Company {
        UserDetails.Company(
            name: name?.nilIfBlank,
            title: title?.nilIfBlank,
            department: department?.nilIfBlank
        )
    }
}
