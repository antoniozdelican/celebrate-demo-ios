import SwiftUI

struct DSAvatar: View {
    enum Size {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small: 36
            case .medium: 48
            case .large: 96
            }
        }

        var typography: DSTypography {
            switch self {
            case .small: .caption
            case .medium: .callout
            case .large: .title
            }
        }
    }

    private let url: URL?
    private let initials: String
    private let size: Size

    init(url: URL?, initials: String, size: Size = .medium) {
        self.url = url
        self.initials = initials
        self.size = size
    }

    var body: some View {
        placeholder
            .overlay {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.clear
                }
            }
            .frame(width: size.dimension, height: size.dimension)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    private var placeholder: some View {
        DSColor.placeholder
            .overlay {
                DSText(initials, style: size.typography, role: .secondary)
            }
    }
}

#Preview {
    HStack(spacing: DSSpacing.lg) {
        DSAvatar(url: nil, initials: "EJ", size: .small)
        DSAvatar(url: nil, initials: "MW")
        DSAvatar(url: nil, initials: "SB", size: .large)
    }
    .padding()
}
