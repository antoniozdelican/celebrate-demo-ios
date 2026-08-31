import Testing
@testable import CelebrateDemoiOS

@Suite("UsersPage")
struct UsersPageTests {
    @Test("Page size stays within the range the brief and the API allow")
    func pageSizeIsInRange() {
        #expect((20...50).contains(UsersPage.size))
    }
}
