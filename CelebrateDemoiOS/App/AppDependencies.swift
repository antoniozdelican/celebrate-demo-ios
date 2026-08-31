import Foundation

/// The composition root: the single place that knows which concrete implementations
/// satisfy the domain's contracts.
///
/// Everything below this line depends on protocols only. The presentation layer receives
/// interactors — never the repository — so a view model cannot reach past its use cases
/// into arbitrary data access, and cannot tell whether the data comes from DummyJSON, a
/// cache, or fixtures. Assembling the graph here rather than inside the
/// Data layer is what keeps Alamofire from leaking upwards: `HTTPClient`'s initialiser
/// takes only Foundation types, so this file does not import Alamofire either.
///
/// Built once at launch and held for the app's lifetime. That is deliberate: `HTTPClient`
/// owns a `Session`, which owns a `URLSession` and its connection pool. Rebuilding it per
/// screen or per request would discard connection reuse and leak sessions.
struct AppDependencies {
    let getUsersInteractor: any GetUsersInteractorProtocol
    let searchUsersInteractor: any SearchUsersInteractorProtocol
    let getUserDetailsInteractor: any GetUserDetailsInteractorProtocol
    let formatBirthDateInteractor: any FormatBirthDateInteractorProtocol

    /// The production graph, wired against the live DummyJSON API.
    ///
    /// - Parameter baseURL: defaulted, and a parameter rather than a constant so that a
    ///   future staging environment — or a test that wants a harmless host — can supply
    ///   its own without this type growing a build-configuration dependency.
    /// The graph the app launches with.
    ///
    /// Under a `-uiTesting` launch argument the *wire* is faked, not the repository, so
    /// UI tests still run through HTTPClient, the data source, decoding and mapping. The
    /// live API cannot be asked for a 500, and the integration tests' MockURLProtocol
    /// cannot reach another process, so the fake has to live here.
    static func make() -> AppDependencies {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            let name = ProcessInfo.processInfo.environment["STUB_SCENARIO"] ?? "success"
            UITestURLProtocol.scenario = UITestURLProtocol.Scenario(rawValue: name) ?? .success

            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [UITestURLProtocol.self]
            return live(configuration: configuration)
        }
        #endif
        return live()
    }

    static func live(
        baseURL: URL = .dummyJSON,
        configuration: URLSessionConfiguration = HTTPClient.configuration
    ) -> AppDependencies {
        let client = HTTPClient(baseURL: baseURL, configuration: configuration)
        let dataSource = UserRemoteDataSource(client: client)

        return make(repository: UserRepository(remoteDataSource: dataSource))
    }

    private static func make(repository: any UserRepositoryProtocol) -> AppDependencies {
        AppDependencies(
            getUsersInteractor: GetUsersInteractor(repository: repository),
            searchUsersInteractor: SearchUsersInteractor(repository: repository),
            getUserDetailsInteractor: GetUserDetailsInteractor(repository: repository),
            formatBirthDateInteractor: FormatBirthDateInteractor()
        )
    }
}

extension URL {
    /// The API the app is built against.
    ///
    /// A constant is proportionate here. If the project ever needed staging and
    /// production builds, this would come from an `.xcconfig` through Info.plist rather
    /// than growing a conditional in code.
    static let dummyJSON = URL(string: "https://dummyjson.com")!
}
