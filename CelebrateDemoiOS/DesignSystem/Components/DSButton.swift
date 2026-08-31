import SwiftUI

struct DSButton: View {
    enum Variant {
        case primary
        case secondary
        case destructive
    }

    enum Size {
        case regular
        case compact

        var verticalPadding: CGFloat {
            switch self {
            case .regular: DSSpacing.md
            case .compact: DSSpacing.sm
            }
        }

        var typography: DSTypography {
            switch self {
            case .regular: .headline
            case .compact: .callout
            }
        }
    }

    private let title: String
    private let variant: Variant
    private let size: Size
    private let isLoading: Bool
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        variant: Variant = .primary,
        size: Size = .regular,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                DSText(title, style: size.typography, role: textRole)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(spinnerTint)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, DSSpacing.lg)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.medium))
            .overlay(border)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .allowsHitTesting(!isLoading)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isLoading ? [.isButton, .updatesFrequently] : .isButton)
    }

    private var textRole: DSText.Role {
        switch variant {
        case .primary: .inverse
        case .secondary: .accent
        case .destructive: .inverse
        }
    }

    private var background: Color {
        switch variant {
        case .primary: DSColor.accent
        case .secondary: .clear
        case .destructive: DSColor.destructive
        }
    }

    private var spinnerTint: Color {
        variant == .secondary ? DSColor.accent : DSColor.inverseText
    }

    @ViewBuilder
    private var border: some View {
        if variant == .secondary {
            RoundedRectangle(cornerRadius: DSRadius.medium)
                .stroke(DSColor.accent, lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: DSSpacing.md) {
        DSButton("Primary") {}
        DSButton("Secondary", variant: .secondary) {}
        DSButton("Destructive", variant: .destructive) {}
        DSButton("Compact", size: .compact) {}
        DSButton("Loading", isLoading: true) {}
        DSButton("Disabled") {}.disabled(true)
    }
    .padding()
}
