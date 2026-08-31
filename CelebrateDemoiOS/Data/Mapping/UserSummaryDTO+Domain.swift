import Foundation

extension UserSummaryDTO {
    /// DTO → entity.
    ///
    /// Mapping is total: it cannot fail. Missing optional strings become `""` and a bad
    /// image URL becomes `nil`, because one malformed row should degrade that row, never
    /// blank the whole screen. Anything genuinely unusable would have failed at decode.
    func toDomain() -> User {
        User(
            id: id,
            firstName: firstName?.trimmed ?? "",
            lastName: lastName?.trimmed ?? "",
            email: email?.trimmed ?? "",
            imageURL: image?.nilIfBlank.flatMap(URL.init(string:)),
            jobTitle: company?.title?.nilIfBlank
        )
    }
}

extension UsersPageDTO {
    func toDomain() -> Page<User> {
        Page(items: users.map { $0.toDomain() }, total: total, skip: skip, limit: limit)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfBlank: String? { trimmed.isEmpty ? nil : trimmed }
}
