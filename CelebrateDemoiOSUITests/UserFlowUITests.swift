import XCTest

/// End-to-end flow, run against a fixture-backed repository selected by a launch
/// argument. Nothing here touches the network, so a failure means the app broke rather
/// than that DummyJSON was slow.
private extension XCUIApplication {
    /// Query by identifier without asserting an element type. SwiftUI decides whether a
    /// row surfaces as a button, a cell or a plain element, and that is not something a
    /// test should have to predict.
    func element(id: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: id).firstMatch
    }
}

final class UserFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(scenario: String = "success") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launchEnvironment = ["STUB_SCENARIO": scenario]
        app.launch()
        return app
    }

    // MARK: - List

    func testListLoadsUsers() {
        let app = launch()

        XCTAssertTrue(app.element(id: "userRow_1").waitForExistence(timeout: 10))
        XCTAssertTrue(app.element(id: "userRow_2").exists)
        XCTAssertTrue(app.staticTexts["Emily Johnson"].exists)
    }

    // MARK: - Search

    func testSearchFiltersTheListAndClearingRestoresIt() {
        let app = launch()
        XCTAssertTrue(app.element(id: "userRow_1").waitForExistence(timeout: 10))

        let search = app.searchFields["Search users"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Emily")

        // Emily stays, Michael goes.
        XCTAssertTrue(app.element(id: "userRow_1").waitForExistence(timeout: 5))
        expectToDisappear(app.element(id: "userRow_2"))

        // Clearing brings the full list back.
        app.buttons["Clear text"].firstMatch.tap()
        XCTAssertTrue(app.element(id: "userRow_2").waitForExistence(timeout: 5))
    }

    func testSearchWithNoMatchesShowsTheEmptyState() {
        let app = launch()
        XCTAssertTrue(app.element(id: "userRow_1").waitForExistence(timeout: 10))

        let search = app.searchFields["Search users"]
        search.tap()
        search.typeText("Zzzzz")

        XCTAssertTrue(app.element(id: "state_empty").waitForExistence(timeout: 5))
    }

    // MARK: - Detail and the animated header

    func testTappingARowOpensTheDetailScreen() {
        let app = launch()
        XCTAssertTrue(app.element(id: "userRow_1").waitForExistence(timeout: 10))

        app.element(id: "userRow_1").tap()

        XCTAssertTrue(app.element(id: "collapsibleHeader").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Sales Manager"].exists)
        XCTAssertTrue(app.staticTexts["emily@example.com"].exists)
    }

    func testScrollingTheDetailScreenCollapsesTheHeader() {
        let app = launch()
        XCTAssertTrue(app.element(id: "userRow_1").waitForExistence(timeout: 10))
        app.element(id: "userRow_1").tap()

        XCTAssertTrue(app.element(id: "collapsibleHeader").waitForExistence(timeout: 10))

        // While expanded, the header carries the name and the navigation bar is bare.
        XCTAssertFalse(
            app.navigationBars["Emily Johnson"].exists,
            "the name should be in the header, not the navigation bar, before scrolling"
        )

        app.scrollViews.firstMatch.swipeUp(velocity: .fast)

        // Collapsing hands the name to the navigation bar — an observable consequence of
        // the animation that does not depend on measuring an accessibility frame.
        XCTAssertTrue(app.navigationBars["Emily Johnson"].waitForExistence(timeout: 5))
    }

    // MARK: - Failure and empty scenarios

    func testAFailureShowsTheErrorStateWithRetry() {
        let app = launch(scenario: "error")

        XCTAssertTrue(app.element(id: "state_failure").waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Try again"].exists)
    }

    func testAnEmptyCollectionShowsTheEmptyState() {
        let app = launch(scenario: "empty")

        XCTAssertTrue(app.element(id: "state_empty").waitForExistence(timeout: 10))
    }

    // MARK: - Helpers

    /// Polls until two consecutive samples agree, so a mid-animation frame is not
    /// mistaken for the resting size.
    private func settledHeight(of element: XCUIElement, timeout: TimeInterval = 3) -> CGFloat {
        var previous = element.frame.height
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
            let current = element.frame.height
            if abs(current - previous) < 0.5 { return current }
            previous = current
        }
        return previous
    }

    private func expectToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        let result = XCTWaiter.wait(for: [gone], timeout: timeout)
        XCTAssertEqual(result, .completed, "element never disappeared", file: file, line: line)
    }
}
