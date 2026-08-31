import Foundation

/// Assembles the data stack.
///
/// The app's composition root calls this instead of wiring `HTTPClient` →
/// `UserRemoteDataSource` → `UserRepository` by hand, keeping that knowledge in the
/// layer that owns it.
enum UserRepositoryFactory {
    static let dummyJSONBaseURL = URL(string: "https://dummyjson.com")!

    static func make(
        baseURL: URL = dummyJSONBaseURL,
        configuration: URLSessionConfiguration = .celebrate
    ) -> any UserRepositoryProtocol {
        let client = HTTPClient(baseURL: baseURL, configuration: configuration)
        return UserRepository(remoteDataSource: UserRemoteDataSource(client: client))
    }
}
