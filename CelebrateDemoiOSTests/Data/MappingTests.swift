import Foundation
import Testing
@testable import CelebrateDemoiOS

@Suite("Mapping")
struct MappingTests {
    @Test("A complete row maps to a complete entity")
    func mapsCompleteSummary() throws {
        let page = try JSONDecoder().decode(UsersPageResponse.self, from: Fixtures.usersPage)

        let user = try #require(Page(response: page).items.first)

        #expect(user.id == 1)
        #expect(user.fullName == "Emily Johnson")
        #expect(user.initials == "EJ")
        #expect(user.email == "emily.johnson@x.dummyjson.com")
        #expect(user.jobTitle == "Sales Manager")
        #expect(user.imageURL?.absoluteString == "https://dummyjson.com/icon/emilys/128")
    }

    @Test("A row missing every optional degrades instead of failing")
    func mapsSparseSummary() throws {
        let page = try JSONDecoder().decode(UsersPageResponse.self, from: Fixtures.sparsePage)

        let user = try #require(Page(response: page).items.first)

        #expect(user.id == 42)
        #expect(user.fullName.isEmpty)
        #expect(user.email.isEmpty)
        #expect(user.jobTitle == nil)
        #expect(user.imageURL == nil)
        #expect(user.initials.isEmpty)
    }

    @Test("Details map, including the unpadded birth date")
    func mapsDetails() throws {
        let response = try JSONDecoder().decode(UserDetailsResponse.self, from: Fixtures.userDetails)

        let details = UserDetails(response: response)

        #expect(details.fullName == "Emily Johnson")
        #expect(details.maidenName == "Smith")
        #expect(details.age == 28)
        #expect(details.gender == .female)
        #expect(details.company?.department == "Engineering")
        #expect(details.address?.city == "Phoenix")
        #expect(details.address?.formatted == "626 Main Street, Phoenix, Mississippi, 29112, United States")
        #expect(details.university == "University of Wisconsin--Madison")

        let components = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(secondsFromGMT: 0)!,
            from: try #require(details.birthDate)
        )
        #expect(components.year == 1996)
        #expect(components.month == 5)
        #expect(components.day == 30)
    }

    @Test("An unrecognised gender is preserved rather than discarded")
    func preservesUnknownGender() throws {
        let data = Data(#"{ "id": 1, "gender": "non-binary" }"#.utf8)
        let response = try JSONDecoder().decode(UserDetailsResponse.self, from: data)

        #expect(UserDetails(response: response).gender == .other("non-binary"))
    }

    @Test("Page arithmetic: a full page in a larger collection has a next offset")
    func pageHasMore() {
        let page = Page(items: [1, 2], total: 208, skip: 0, limit: 2)

        #expect(page.hasMore)
        #expect(page.nextSkip == 2)
    }

    @Test("Page arithmetic: the final page terminates pagination")
    func lastPageHasNoMore() {
        let page = Page(items: [208], total: 208, skip: 207, limit: 2)

        #expect(!page.hasMore)
        #expect(page.nextSkip == nil)
    }

    @Test("Page arithmetic: an empty page terminates even if total disagrees")
    func emptyPageTerminates() {
        let page = Page(items: [Int](), total: 208, skip: 30, limit: 30)

        #expect(!page.hasMore)
    }
}
