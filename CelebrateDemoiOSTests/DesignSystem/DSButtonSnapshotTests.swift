import SnapshotTesting
import SwiftUI
import XCTest
@testable import CelebrateDemoiOS

/// XCTest rather than Swift Testing: under Swift Testing each assertion ran twice in this
/// bundle, so every component recorded two references. XCTest is also the library's
/// primary integration.
@MainActor
final class DSButtonSnapshotTests: XCTestCase {
    func testVariants() {
        assertSnapshot(
            of: Snapshot.subject(
                VStack(spacing: DSSpacing.md) {
                    DSButton("Primary") {}
                    DSButton("Secondary", variant: .secondary) {}
                    DSButton("Destructive", variant: .destructive) {}
                }
            ),
            as: Snapshot.image()
        )
    }

    func testSizes() {
        assertSnapshot(
            of: Snapshot.subject(
                VStack(spacing: DSSpacing.md) {
                    DSButton("Regular") {}
                    DSButton("Compact", size: .compact) {}
                }
            ),
            as: Snapshot.image()
        )
    }

    /// Pins the fix for a real bug: `.disabled(isLoading)` applied SwiftUI's disabled
    /// styling and desaturated the accent fill, so a loading button looked dead rather
    /// than busy. Nothing else guards it.
    func testLoadingKeepsItsFillWhileDisabledDoesNot() {
        assertSnapshot(
            of: Snapshot.subject(
                VStack(spacing: DSSpacing.md) {
                    DSButton("Loading", isLoading: true) {}
                    DSButton("Disabled") {}.disabled(true)
                }
            ),
            as: Snapshot.image()
        )
    }

    func testDarkMode() {
        assertSnapshot(
            of: Snapshot.subject(
                VStack(spacing: DSSpacing.md) {
                    DSButton("Primary") {}
                    DSButton("Secondary", variant: .secondary) {}
                }
            ),
            as: Snapshot.image(style: .dark)
        )
    }
}
