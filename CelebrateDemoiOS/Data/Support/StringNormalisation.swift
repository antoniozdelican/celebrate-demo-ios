import Foundation

/// Normalisation used while mapping responses to domain entities.
///
/// The API returns whitespace-padded and whitespace-only values in optional fields, and
/// `"   "` renders as a blank row rather than as absent data. Collapsing those to `nil`
/// once, here, keeps the rule out of every mapping site.
extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfBlank: String? { trimmed.isEmpty ? nil : trimmed }
}
