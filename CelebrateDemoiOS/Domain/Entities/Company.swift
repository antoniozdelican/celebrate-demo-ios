import Foundation

/// Where a user works.
///
/// Every field is optional: the API populates these inconsistently, and a missing
/// department should not prevent a profile from rendering.
struct Company: Equatable, Sendable {
    let name: String?
    let title: String?
    let department: String?
}
