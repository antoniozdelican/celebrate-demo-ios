import SwiftUI

struct CollapsibleHeader: View {
    static let collapseDistance: CGFloat = 120

    let imageURL: URL?
    let initials: String
    let name: String
    let subtitle: String?
    let scrollOffset: CGFloat

    private var progress: Double {
        min(max(Double(scrollOffset / Self.collapseDistance), 0), 1)
    }

    private var avatarScale: Double { 1 - (progress * 0.55) }
    private var nameScale: Double { 1 - (progress * 0.35) }
    private var subtitleOpacity: Double { max(0, 1 - progress * 2.5) }

    var body: some View {
        VStack(spacing: DSSpacing.md * (1 - progress * 0.6)) {
            DSAvatar(url: imageURL, initials: initials, size: .large)
                .scaleEffect(avatarScale, anchor: .center)
                .frame(height: DSAvatar.Size.large.dimension * avatarScale)

            VStack(spacing: DSSpacing.xs) {
                DSText(name, style: .largeTitle)
                    .multilineTextAlignment(.center)
                    .scaleEffect(nameScale, anchor: .center)

                if let subtitle {
                    DSText(subtitle, style: .callout, role: .secondary)
                        .opacity(subtitleOpacity)
                        .frame(height: subtitleOpacity == 0 ? 0 : nil)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.xl * (1 - progress * 0.75))
        .background(DSColor.background)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: progress)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([name, subtitle].compactMap { $0 }.joined(separator: ", "))
    }
}

#Preview("Expanded") {
    CollapsibleHeader(
        imageURL: nil,
        initials: "EJ",
        name: "Emily Johnson",
        subtitle: "Sales Manager",
        scrollOffset: 0
    )
}

#Preview("Collapsed") {
    CollapsibleHeader(
        imageURL: nil,
        initials: "EJ",
        name: "Emily Johnson",
        subtitle: "Sales Manager",
        scrollOffset: CollapsibleHeader.collapseDistance
    )
}
