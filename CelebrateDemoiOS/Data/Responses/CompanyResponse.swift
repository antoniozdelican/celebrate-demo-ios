import Foundation

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
