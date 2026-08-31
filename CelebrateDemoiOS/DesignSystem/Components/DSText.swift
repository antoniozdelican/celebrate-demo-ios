import SwiftUI

struct DSText: View {
    enum Role {
        case primary
        case secondary
        case accent
        case destructive
        case inverse

        var color: Color {
            switch self {
            case .primary: DSColor.primaryText
            case .secondary: DSColor.secondaryText
            case .accent: DSColor.accent
            case .destructive: DSColor.destructive
            case .inverse: DSColor.inverseText
            }
        }
    }

    private let content: String
    private let style: DSTypography
    private let role: Role

    init(_ content: String, style: DSTypography = .body, role: Role = .primary) {
        self.content = content
        self.style = style
        self.role = role
    }

    var body: some View {
        Text(content)
            .font(style.font)
            .foregroundStyle(role.color)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: DSSpacing.sm) {
        DSText("Large title", style: .largeTitle)
        DSText("Title", style: .title)
        DSText("Headline", style: .headline)
        DSText("Body")
        DSText("Callout", style: .callout, role: .secondary)
        DSText("Caption", style: .caption, role: .secondary)
        DSText("Accent", role: .accent)
        DSText("Destructive", role: .destructive)
    }
    .padding()
}
