import Foundation

/// The Domain layer's contract for user data.
///
/// Declared here — and implemented in the Data layer — so the dependency arrow points
/// inwards: interactors depend on this abstraction, never on Alamofire, response models or
/// DummyJSON. Swapping the backend, adding a cache, or feeding fixtures to UI tests are
/// all changes behind this protocol.
///
/// Typed `throws(DomainError)` means implementations are *forced* to translate their
/// transport errors; a raw `URLError` cannot leak through the boundary by accident.
protocol UserRepositoryProtocol: Sendable {
    /// A page of users.
    /// - Parameters:
    ///   - limit: page size (the brief allows 20–50).
    ///   - skip: offset of the first item.
    func users(limit: Int, skip: Int) async throws(DomainError) -> Page<User>

    /// Server-side search. A blank query yields an empty page without a request.
    func searchUsers(query: String, limit: Int, skip: Int) async throws(DomainError) -> Page<User>

    /// Full profile for one user.
    /// - Throws: ``DomainError/notFound`` when no user has this identifier.
    func userDetails(id: Int) async throws(DomainError) -> UserDetails
}
