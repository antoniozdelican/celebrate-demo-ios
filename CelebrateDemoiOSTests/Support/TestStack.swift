import Alamofire
import Foundation
@testable import CelebrateDemoiOS

/// The production data stack, wired to a private ``NetworkStub``.
///
/// One instance per test: the stub is reachable as `stack.stub`, so no suite needs
/// `.serialized` and the tests stay parallel-safe.
///
/// Note the absence of an interceptor: the production client retries, which would make
/// a 500-status test wait through two backoffs. Retry behaviour deserves its own test,
/// not a tax on every other one.
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

        let client = HTTPClient(baseURL: baseURL, session: Session(configuration: configuration))
        let dataSource = UserRemoteDataSource(client: client)

        self.stub = stub
        self.client = client
        self.dataSource = dataSource
        self.repository = UserRepository(remoteDataSource: dataSource)
    }
}
