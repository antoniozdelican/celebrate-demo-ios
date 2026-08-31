import Foundation
import Testing
@testable import CelebrateDemoiOS

/// Query-string encoding is the cheapest networking bug to catch and the most expensive
/// to debug from a UI symptom, so it is asserted directly.
@Suite("UserEndpoints")
struct UserEndpointsTests {
    private let baseURL = URL(string: "https://dummyjson.com")!

    @Test("List endpoint carries limit, skip and the trimmed field selection")
    func listEndpoint() {
        let endpoint = UserEndpoints.list(limit: 30, skip: 60)

        #expect(endpoint.path == "users")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryValue("limit") == "30")
        #expect(endpoint.queryValue("skip") == "60")
        #expect(endpoint.queryValue("select") == "firstName,lastName,email,image,company")
    }

    @Test("Search endpoint sends the raw query under `q`")
    func searchEndpoint() {
        let endpoint = UserEndpoints.search(query: "John Doe", limit: 20, skip: 0)

        #expect(endpoint.path == "users/search")
        #expect(endpoint.queryValue("q") == "John Doe")
        #expect(endpoint.queryValue("limit") == "20")
    }

    @Test("Detail endpoint interpolates the identifier and requests the full record")
    func detailsEndpoint() {
        let endpoint = UserEndpoints.details(id: 7)

        #expect(endpoint.path == "users/7")
        // No `select`: the detail screen needs every field.
        #expect(endpoint.queryItems.isEmpty)
    }

    @Test("Spaces and symbols in a search term are percent-encoded, not dropped")
    func percentEncoding() throws {
        let endpoint = UserEndpoints.search(query: "john+doe smith&co", limit: 20, skip: 0)

        let request = try endpoint.urlRequest(baseURL: baseURL)
        let url = try #require(request.url)

        // `+` must survive as %2B, or the server reads it as a space.
        #expect(url.absoluteString.contains("q=john%2Bdoe%20smith%26co"))
        #expect(url.path == "/users/search")
    }

    @Test("Query items with no value are omitted from the URL")
    func nilQueryItemsAreDropped() throws {
        let endpoint = Endpoint(
            path: "users",
            queryItems: [
                URLQueryItem(name: "limit", value: "30"),
                URLQueryItem(name: "cursor", value: nil),
            ]
        )

        let request = try endpoint.urlRequest(baseURL: baseURL)
        let url = try #require(request.url)

        #expect(url.query == "limit=30")
    }
}
