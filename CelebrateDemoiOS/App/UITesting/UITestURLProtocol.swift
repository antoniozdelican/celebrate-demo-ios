#if DEBUG
import Foundation

/// Serves canned responses to the app's own network stack during UI tests.
///
/// UI tests run the app out of process, so the integration tests' `MockURLProtocol`
/// cannot reach it — something has to live in the app. Faking the *wire* rather than the
/// repository means the UI tests still exercise `HTTPClient`, `UserRemoteDataSource`,
/// decoding, mapping and error translation. Replacing the repository would have skipped
/// all of it, and the tests would pass with a broken decoder.
///
/// `#if DEBUG`, so none of this is in a Release build.
final class UITestURLProtocol: URLProtocol {
    enum Scenario: String {
        case success
        case empty
        case error
    }

    nonisolated(unsafe) static var scenario: Scenario = .success

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }

        if Self.scenario == .error {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: UITestFixtures.body(for: url, scenario: Self.scenario))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// The JSON the app is served during UI tests, shaped exactly like DummyJSON's.
private enum UITestFixtures {
    static func body(for url: URL, scenario: UITestURLProtocol.Scenario) -> Data {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = components?.queryItems?.first { $0.name == "q" }?.value

        if url.path.hasPrefix("/users/"), let id = Int(url.lastPathComponent) {
            return Data(details(id: id).utf8)
        }
        if scenario == .empty {
            return Data(page(users: []).utf8)
        }
        let matches = query.map { term in
            users.filter { $0.name.localizedCaseInsensitiveContains(term) }
        } ?? users
        return Data(page(users: matches).utf8)
    }

    private struct Row {
        let id: Int
        let first: String
        let last: String
        let title: String
        var name: String { "\(first) \(last)" }
    }

    private static let users: [Row] = [
        Row(id: 1, first: "Emily", last: "Johnson", title: "Sales Manager"),
        Row(id: 2, first: "Michael", last: "Williams", title: "Support Specialist"),
        Row(id: 3, first: "Sophia", last: "Brown", title: "Accountant"),
        Row(id: 4, first: "James", last: "Davis", title: "Research Analyst"),
        Row(id: 5, first: "Emma", last: "Miller", title: "Quality Assurance Engineer"),
        Row(id: 6, first: "Olivia", last: "Wilson", title: "Research Analyst"),
    ]

    private static func page(users rows: [Row]) -> String {
        let items = rows.map { row in
            """
            {
              "id": \(row.id),
              "firstName": "\(row.first)",
              "lastName": "\(row.last)",
              "email": "\(row.first.lowercased())@example.com",
              "image": null,
              "company": { "name": "Dooley, Kozey and Cronin", "title": "\(row.title)", "department": "Engineering" }
            }
            """
        }
        return """
        { "users": [\(items.joined(separator: ","))], "total": \(rows.count), "skip": 0, "limit": 30 }
        """
    }

    private static func details(id: Int) -> String {
        let row = users.first { $0.id == id } ?? users[0]
        return """
        {
          "id": \(row.id),
          "firstName": "\(row.first)",
          "lastName": "\(row.last)",
          "email": "\(row.first.lowercased())@example.com",
          "phone": "+1 555 0100",
          "username": "\(row.first.lowercased())",
          "age": 28,
          "gender": "female",
          "birthDate": "1996-5-30",
          "image": null,
          "university": "University of Wisconsin",
          "role": "admin",
          "company": { "name": "Dooley, Kozey and Cronin", "title": "\(row.title)", "department": "Engineering" },
          "address": {
            "address": "626 Main Street", "city": "Phoenix", "state": "Arizona",
            "postalCode": "29112", "country": "United States"
          }
        }
        """
    }
}
#endif
