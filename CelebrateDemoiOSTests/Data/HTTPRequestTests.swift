import Foundation
import Testing
@testable import CelebrateDemoiOS

/// URL construction is the cheapest networking bug to catch and the most expensive to
/// debug from a UI symptom, so it is asserted directly on the type that performs it.
@Suite("HTTPRequest")
struct HTTPRequestTests {
    private let baseURL = URL(string: "https://dummyjson.com")!

    @Test("Resolves the path against the base URL and carries the method")
    func resolvesPathAndMethod() throws {
        let request = try HTTPRequest(path: "users/7").urlRequest(baseURL: baseURL)

        #expect(request.url?.absoluteString == "https://dummyjson.com/users/7")
        #expect(request.httpMethod == "GET")
    }

    @Test("Spaces and symbols in a query value are percent-encoded, not dropped")
    func percentEncoding() throws {
        let request = try HTTPRequest(
            path: "users/search",
            queryItems: [URLQueryItem(name: "q", value: "john+doe smith&co")]
        ).urlRequest(baseURL: baseURL)

        let url = try #require(request.url)

        // `+` must survive as %2B. URLComponents leaves it alone, and a server that reads
        // a literal `+` as a space would silently search "john doe" instead.
        #expect(url.absoluteString.contains("q=john%2Bdoe%20smith%26co"))
        #expect(url.path == "/users/search")
    }

    @Test("Query items with no value are omitted from the URL")
    func nilQueryItemsAreDropped() throws {
        let request = try HTTPRequest(
            path: "users",
            queryItems: [
                URLQueryItem(name: "limit", value: "30"),
                URLQueryItem(name: "cursor", value: nil),
            ]
        ).urlRequest(baseURL: baseURL)

        #expect(try #require(request.url).query == "limit=30")
    }

    @Test("A request with no query items produces no question mark")
    func noQueryItems() throws {
        let request = try HTTPRequest(path: "users/1").urlRequest(baseURL: baseURL)

        #expect(try #require(request.url).query == nil)
    }

    @Test("Headers and body reach the URLRequest")
    func headersAndBody() throws {
        let body = Data("{}".utf8)
        let request = try HTTPRequest(
            path: "users",
            method: .post,
            headers: ["X-Test": "value"],
            body: body
        ).urlRequest(baseURL: baseURL)

        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(request.httpBody == body)
    }
}
