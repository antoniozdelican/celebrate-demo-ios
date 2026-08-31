import Foundation

/// A person's gender as reported by the API.
///
/// Modelled with an escape hatch so an unexpected value degrades into `.other` rather
/// than failing the decode or being silently dropped — the set of values a backend
/// returns here is not something a client should assume it knows in advance.
enum Gender: Equatable, Sendable {
    case male
    case female
    case other(String)
    case unspecified
}
