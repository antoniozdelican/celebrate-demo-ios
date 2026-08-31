import Foundation
@testable import CelebrateDemoiOS

/// The production data stack, wired to a private ``NetworkStub``.
///
/// One instance per test: the stub is reachable as `stack.stub`, so no suite needs
/// `.serialized` and the tests stay parallel-safe.
///
/// The configuration carries the stub `URLProtocol` and the header that routes replies
/// back to this stack's own `NetworkStub`. `HTTPClient` builds the `Session` itself, so
/// the wire is the only thing these tests replace.
struct TestStack {
    static let baseURL = URL(string: "https://dummyjson.com")!

    let stub: NetworkStub
    let client: HTTPClient
    let dataSource: UserRemoteDataSource
    let repository: UserRepository

    init(baseURL: URL = TestStack.baseURL) {
        let stub = NetworkStub()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [NetworkStub.headerField: stub.id]
        configuration.timeoutIntervalForRequest = 5

        let client = HTTPClient(baseURL: baseURL, configuration: configuration)
        let dataSource = UserRemoteDataSource(client: client)

        self.stub = stub
        self.client = client
        self.dataSource = dataSource
        self.repository = UserRepository(remoteDataSource: dataSource)
    }
}
