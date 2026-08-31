import Foundation

/// Intercepts requests at the `URLProtocol` layer so integration tests can drive the
/// **real** Alamofire stack — real `Session`, real validation, real serialization —
/// without a socket.
///
/// Each test owns its own ``NetworkMock``; requests are routed back to the right one by
/// a header stamped on that test's session configuration. That keeps the suites free of
/// shared mutable state, so Swift Testing can run them in parallel.
final class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        NetworkMock.mockID(for: request) != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let mock = NetworkMock.registered(for: request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        mock.record(request)

        guard let response = mock.response(for: request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        if let error = response.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        if let data = response.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// What ``MockURLProtocol`` should reply with.
struct MockResponse: Sendable {
    var statusCode: Int = 200
    var data: Data?
    var error: URLError?

    static func ok(_ data: Data) -> MockResponse { MockResponse(statusCode: 200, data: data) }
    static func status(_ code: Int, body: Data? = nil) -> MockResponse { MockResponse(statusCode: code, data: body) }
    static func failure(_ code: URLError.Code) -> MockResponse { MockResponse(error: URLError(code)) }
}

/// One test's canned responses, and the requests it received.
///
/// Guarded by a lock rather than an actor because `URLProtocol.startLoading()` is
/// synchronous and runs off the test's task.
final class NetworkMock: @unchecked Sendable {
    /// Identifies which stub a request belongs to. Stamped on the test session's
    /// `httpAdditionalHeaders`, so production code never learns it exists.
    static let headerField = "X-Celebrate-Mock-ID"

    let id = UUID().uuidString

    private let lock = NSLock()
    private var handler: (@Sendable (URLRequest) -> MockResponse?)?
    private var requests: [URLRequest] = []

    init() { Self.registry.add(self) }
    deinit { Self.registry.remove(id) }

    /// Replies with `stub` to every request.
    func setResponse(_ response: MockResponse) {
        setHandler { _ in response }
    }

    /// Replies based on the request — used to give page 1 and page 2 different bodies.
    func setHandler(_ handler: @escaping @Sendable (URLRequest) -> MockResponse?) {
        lock.withLock {
            self.handler = handler
            self.requests = []
        }
    }

    /// Every request this stack actually sent, in order.
    var recordedRequests: [URLRequest] { lock.withLock { requests } }

    var recordedURLs: [String] { recordedRequests.compactMap { $0.url?.absoluteString } }

    fileprivate func response(for request: URLRequest) -> MockResponse? {
        lock.withLock { handler?(request) }
    }

    fileprivate func record(_ request: URLRequest) {
        lock.withLock { requests.append(request) }
    }

    // MARK: - Routing

    fileprivate static func mockID(for request: URLRequest) -> String? {
        request.value(forHTTPHeaderField: headerField)
    }

    fileprivate static func registered(for request: URLRequest) -> NetworkMock? {
        mockID(for: request).flatMap { registry.mock(id: $0) }
    }

    private static let registry = Registry()

    private final class Registry: @unchecked Sendable {
        private let lock = NSLock()
        private var mocks: [String: NetworkMock] = [:]

        func add(_ mock: NetworkMock) { lock.withLock { mocks[mock.id] = mock } }
        func remove(_ id: String) { lock.withLock { mocks[id] = nil } }
        func mock(id: String) -> NetworkMock? { lock.withLock { mocks[id] } }
    }
}
