import SwiftUI

struct DSSearchField: View {
    private let placeholder: String
    @Binding private var text: String
    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String) {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DSColor.secondaryText)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel(placeholder)

            if !text.isEmpty {
                Button {
                    text = ""
                    isFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColor.secondaryText)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.medium))
    }
}

#Preview {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "Emily"

    return VStack(spacing: DSSpacing.md) {
        DSSearchField(text: $empty, placeholder: "Search users")
        DSSearchField(text: $filled, placeholder: "Search users")
    }
    .padding()
}
