import SnapshotTesting
import SwiftUI
import XCTest
@testable import CelebrateDemoiOS

@MainActor
final class DSStateViewSnapshotTests: XCTestCase {
    func testEmpty() {
        assertSnapshot(
            of: Snapshot.subject(
                DSStateView(.empty(
                    systemImage: "person.2.slash",
                    title: "No users yet",
                    message: "There is nothing to show right now."
                ))
            ),
            as: Snapshot.image(height: 320)
        )
    }

    func testFailureWithRetry() {
        assertSnapshot(
            of: Snapshot.subject(
                DSStateView(
                    .failure(title: "Couldn't load users", message: "You appear to be offline."),
                    retry: {}
                )
            ),
            as: Snapshot.image(height: 320)
        )
    }
}
