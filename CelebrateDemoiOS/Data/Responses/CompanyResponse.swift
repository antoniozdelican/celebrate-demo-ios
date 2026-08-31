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

extension Company {
    init(response: CompanyResponse) {
        self.init(
            name: response.name?.nilIfBlank,
            title: response.title?.nilIfBlank,
            department: response.department?.nilIfBlank
        )
    }
}
