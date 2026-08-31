import SwiftUI

struct UserDetailView<ViewModel: UserDetailViewModelProtocol>: View {
    @State private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            DSStateView(.loading)

        case .loaded(let details):
            profile(details)

        case .failed(.notFound):
            DSStateView(.empty(
                systemImage: "person.slash",
                title: "User not found",
                message: "This profile is no longer available."
            ))

        case .failed(let error):
            DSStateView(
                .failure(title: "Couldn't load profile", message: error.errorDescription),
                retry: error.isRetryable ? { Task { await viewModel.retry() } } : nil
            )
        }
    }

    private func profile(_ details: UserDetails) -> some View {
        ScrollView {
            VStack(spacing: DSSpacing.xl) {
                header(details)

                if let company = details.company {
                    section("Work") {
                        field("Company", company.name)
                        field("Title", company.title)
                        field("Department", company.department)
                    }
                }

                section("Contact") {
                    field("Email", details.email)
                    field("Phone", details.phone)
                    field("Username", details.username)
                }

                if let address = details.address, !address.formatted.isEmpty {
                    section("Address") {
                        field("Location", address.formatted)
                    }
                }

                section("Personal") {
                    field("Age", details.age.map(String.init))
                    field("Gender", details.gender.title)
                    field("Born", details.birthDate.map(BirthDateFormatter.string(from:)))
                    field("University", details.university)
                }
            }
            .padding(DSSpacing.lg)
        }
        .navigationTitle(details.fullName)
    }

    private func header(_ details: UserDetails) -> some View {
        VStack(spacing: DSSpacing.md) {
            DSAvatar(url: details.imageURL, initials: details.initials, size: .large)

            VStack(spacing: DSSpacing.xs) {
                DSText(details.fullName, style: .largeTitle)
                    .multilineTextAlignment(.center)

                if let title = details.company?.title {
                    DSText(title, style: .callout, role: .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            DSText(title.uppercased(), style: .caption, role: .secondary)
                .padding(.leading, DSSpacing.xs)

            DSCard {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    content()
                }
            }
        }
    }

    @ViewBuilder
    private func field(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                DSText(label, style: .caption, role: .secondary)
                DSText(value)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private enum BirthDateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}

private extension UserDetails {
    var initials: String {
        [firstName, lastName]
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private extension Gender {
    var title: String? {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other(let value): value.capitalized
        case .unspecified: nil
        }
    }
}
