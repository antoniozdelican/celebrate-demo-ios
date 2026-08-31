import SwiftUI

struct DSStateView: View {
    enum Style {
        case loading
        case empty(systemImage: String, title: String, message: String?)
        case failure(title: String, message: String?)
    }

    private let style: Style
    private let retry: (() -> Void)?

    init(_ style: Style, retry: (() -> Void)? = nil) {
        self.style = style
        self.retry = retry
    }

    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            switch style {
            case .loading:
                ProgressView()
                    .accessibilityLabel("Loading")

            case .empty(let systemImage, let title, let message):
                icon(systemImage, color: DSColor.secondaryText)
                copy(title: title, message: message)

            case .failure(let title, let message):
                icon("exclamationmark.triangle", color: DSColor.destructive)
                copy(title: title, message: message)
            }

            if let retry {
                DSButton("Try again", variant: .secondary, size: .compact, action: retry)
                    .fixedSize()
            }
        }
        .padding(DSSpacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private var identifier: String {
        switch style {
        case .loading: "state_loading"
        case .empty: "state_empty"
        case .failure: "state_failure"
        }
    }

    private func icon(_ systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.largeTitle)
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }

    private func copy(title: String, message: String?) -> some View {
        VStack(spacing: DSSpacing.sm) {
            DSText(title, style: .headline)
            if let message {
                DSText(message, role: .secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview("Loading") {
    DSStateView(.loading)
}

#Preview("Empty") {
    DSStateView(.empty(
        systemImage: "person.slash",
        title: "No users found",
        message: "Try a different search term."
    ))
}

#Preview("Failure") {
    DSStateView(
        .failure(title: "Couldn't load users", message: "You appear to be offline."),
        retry: {}
    )
}
