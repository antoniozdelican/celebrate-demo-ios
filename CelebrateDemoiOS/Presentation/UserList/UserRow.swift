import SwiftUI

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            DSAvatar(url: user.imageURL, initials: user.initials, size: .medium)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                DSText(user.fullName, style: .headline)
                DSText(user.jobTitle ?? user.email, style: .callout, role: .secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, DSSpacing.xs)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        UserRow(user: User(
            id: 1,
            firstName: "Emily",
            lastName: "Johnson",
            email: "emily@example.com",
            imageURL: nil,
            jobTitle: "Sales Manager"
        ))
        UserRow(user: User(
            id: 2,
            firstName: "Michael",
            lastName: "Williams",
            email: "michael@example.com",
            imageURL: nil,
            jobTitle: nil
        ))
    }
}
