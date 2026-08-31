import Foundation

/// Data-layer implementation of ``UserRepositoryProtocol``.
///
/// Three responsibilities, and no others:
/// 1. delegate to the remote data source,
/// 2. map DTOs to entities,
/// 3. translate `HTTPError` into `DomainError`.
///
/// It is the outermost point at which a networking type is still visible. A local cache
/// would slot in here without the protocol above it changing.
struct UserRepository: UserRepositoryProtocol {
    private let remoteDataSource: any UserRemoteDataSourceProtocol

    init(remoteDataSource: any UserRemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func users(limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        do {
            return try await remoteDataSource.users(limit: limit, skip: skip).toDomain()
        } catch {
            throw DomainError(error)
        }
    }

    func searchUsers(query: String, limit: Int, skip: Int) async throws(DomainError) -> Page<User> {
        let trimmed = query.trimmed
        // Guard rather than call: `q=` returns the unfiltered collection, which would
        // silently read as "search matched everything" after the field is cleared.
        guard !trimmed.isEmpty else { return .empty }

        do {
            return try await remoteDataSource
                .searchUsers(query: trimmed, limit: limit, skip: skip)
                .toDomain()
        } catch {
            throw DomainError(error)
        }
    }

    func userDetails(id: Int) async throws(DomainError) -> UserDetails {
        do {
            return try await remoteDataSource.userDetails(id: id).toDomain()
        } catch {
            throw DomainError(error)
        }
    }
}
