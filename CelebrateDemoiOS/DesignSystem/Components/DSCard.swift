import SwiftUI

struct DSCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DSColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.large))
    }
}

#Preview {
    DSCard {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSText("Company", style: .caption, role: .secondary)
            DSText("Dooley, Kozey and Cronin", style: .headline)
            DSText("Sales Manager · Engineering", role: .secondary)
        }
    }
    .padding()
}
