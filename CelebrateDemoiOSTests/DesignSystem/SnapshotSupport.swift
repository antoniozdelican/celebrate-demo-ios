import SnapshotTesting
import SwiftUI
@testable import CelebrateDemoiOS

/// Tolerances and traits shared by every component snapshot.
///
/// `precision` and `perceptualPrecision` are below 1 deliberately: exact pixel equality
/// fails on antialiasing differences that no reviewer would call a regression, and that
/// is the usual reason snapshot suites get deleted rather than maintained.
///
/// The interface style is pinned per assertion rather than inherited, so a run under a
/// dark-mode simulator does not rewrite every reference.
enum Snapshot {
    static func image(
        width: CGFloat = 320,
        height: CGFloat? = nil,
        style: UIUserInterfaceStyle = .light
    ) -> Snapshotting<AnyView, UIImage> {
        .image(
            precision: 0.99,
            perceptualPrecision: 0.98,
            layout: height.map { .fixed(width: width, height: $0) } ?? .sizeThatFits,
            traits: UITraitCollection(userInterfaceStyle: style)
        )
    }

    /// Components are snapshotted at a fixed width with a background, so the reference is
    /// not a transparent strip whose diff is impossible to read.
    static func subject(_ view: some View, width: CGFloat = 320) -> AnyView {
        AnyView(
            view
                .padding(DSSpacing.lg)
                .frame(width: width)
                .background(DSColor.background)
        )
    }
}
