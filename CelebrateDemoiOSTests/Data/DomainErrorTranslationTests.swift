import Testing
@testable import CelebrateDemoiOS

@Suite("HTTPError → DomainError")
struct DomainErrorTranslationTests {
    @Test(
        "Transport failures translate to their domain equivalents",
        arguments: [
            (HTTPError.notConnected, DomainError.notConnected),
            (.timedOut, .timedOut),
            (.cancelled, .cancelled),
            (.status(code: 404, data: nil), .notFound),
            (.status(code: 500, data: nil), .server(statusCode: 500)),
            (.status(code: 401, data: nil), .server(statusCode: 401)),
            (.decoding(description: "boom"), .invalidResponse),
            (.invalidURL, .unknown),
            (.transport(description: "boom"), .unknown),
        ]
    )
    func translates(httpError: HTTPError, expected: DomainError) {
        #expect(DomainError(httpError: httpError) == expected)
    }

    @Test("Only failures a retry could plausibly fix are retryable")
    func retryability() {
        #expect(DomainError.notConnected.isRetryable)
        #expect(DomainError.timedOut.isRetryable)
        #expect(DomainError.server(statusCode: 500).isRetryable)
        #expect(!DomainError.notFound.isRetryable)
        #expect(!DomainError.cancelled.isRetryable)
        #expect(!DomainError.invalidResponse.isRetryable)
    }

    @Test("Every domain error carries a user-facing message")
    func allErrorsHaveDescriptions() {
        let all: [DomainError] = [
            .notConnected, .timedOut, .cancelled, .notFound,
            .server(statusCode: 500), .invalidResponse, .unknown,
        ]

        for error in all {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}
