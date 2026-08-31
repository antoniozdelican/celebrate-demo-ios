import SwiftUI

private let scrollSpaceName = "userDetailScroll"

struct UserDetailView<ViewModel: UserDetailViewModelProtocol>: View {
    @State private var viewModel: ViewModel
    @State private var scrollOffset: CGFloat = 0

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
                Color.clear
                    .frame(height: 0)
                    .onScrollOffsetChange(in: scrollSpaceName) { scrollOffset = $0 }

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
                    field("Born", details.birthDate.map(viewModel.formattedBirthDate))
                    field("University", details.university)
                }
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.bottom, DSSpacing.lg)
        }
        .coordinateSpace(name: scrollSpaceName)
        .safeAreaInset(edge: .top, spacing: 0) {
            CollapsibleHeader(
                imageURL: details.imageURL,
                initials: details.initials,
                name: details.fullName,
                subtitle: details.company?.title,
                scrollOffset: scrollOffset
            )
        }
        .navigationTitle(scrollOffset > CollapsibleHeader.collapseDistance * 0.9 ? details.fullName : "")
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
