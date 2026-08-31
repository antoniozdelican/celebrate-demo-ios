import Foundation
@testable import CelebrateDemoiOS

/// The production data stack, wired to a private ``NetworkMock``.
///
/// One instance per test: the stub is reachable as `stack.stub`, so no suite needs
/// `.serialized` and the tests stay parallel-safe.
///
/// The configuration carries the mock `URLProtocol` and the header that routes replies
/// back to this stack's own `NetworkMock`. `HTTPClient` builds the `Session` itself, so
/// the wire is the only thing these tests replace.
struct TestStack {
    static let baseURL = URL(string: "https://dummyjson.com")!

    let networkMock: NetworkMock
    let client: HTTPClient
    let dataSource: UserRemoteDataSource
    let repository: UserRepository

    init(baseURL: URL = TestStack.baseURL) {
        let networkMock = NetworkMock()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = [NetworkMock.headerField: networkMock.id]
        configuration.timeoutIntervalForRequest = 5

        let client = HTTPClient(baseURL: baseURL, configuration: configuration)
        let dataSource = UserRemoteDataSource(client: client)

        self.networkMock = networkMock
        self.client = client
        self.dataSource = dataSource
        self.repository = UserRepository(remoteDataSource: dataSource)
    }
}
