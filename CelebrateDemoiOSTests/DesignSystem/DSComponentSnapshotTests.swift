import SnapshotTesting
import SwiftUI
import XCTest
@testable import CelebrateDemoiOS

@MainActor
final class DSComponentSnapshotTests: XCTestCase {
    func testTypographyScale() {
        assertSnapshot(
            of: Snapshot.subject(
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    DSText("Large title", style: .largeTitle)
                    DSText("Title", style: .title)
                    DSText("Headline", style: .headline)
                    DSText("Body")
                    DSText("Callout", style: .callout, role: .secondary)
                    DSText("Caption", style: .caption, role: .secondary)
                }
            ),
            as: Snapshot.image()
        )
    }

    func testAvatarSizesFallBackToInitials() {
        assertSnapshot(
            of: Snapshot.subject(
                HStack(spacing: DSSpacing.lg) {
                    DSAvatar(url: nil, initials: "EJ", size: .small)
                    DSAvatar(url: nil, initials: "MW")
                    DSAvatar(url: nil, initials: "SB", size: .large)
                }
            ),
            as: Snapshot.image()
        )
    }

    func testCard() {
        assertSnapshot(
            of: Snapshot.subject(
                DSCard {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        DSText("Company", style: .caption, role: .secondary)
                        DSText("Dooley, Kozey and Cronin", style: .headline)
                        DSText("Sales Manager · Engineering", role: .secondary)
                    }
                }
            ),
            as: Snapshot.image()
        )
    }
}
