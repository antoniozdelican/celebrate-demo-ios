import SwiftUI

@main
struct CelebrateDemoiOSApp: App {
    /// The composition root, built once at launch and held for the app's lifetime.
    ///
    /// When UI tests arrive this becomes a switch: a `-uiTesting` launch argument will
    /// select a fixture-backed graph, which is the only way to make error and empty
    /// states reachable from XCUITest — the live API will not return a 500 on request,
    /// and `URLProtocol` stubbing cannot cross into the app's process.
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
    }
}
