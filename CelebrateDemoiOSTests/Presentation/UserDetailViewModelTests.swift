import Foundation
import Testing
@testable import CelebrateDemoiOS

@MainActor
@Suite("UserDetailViewModel")
struct UserDetailViewModelTests {
    private func makeSUT(
        userID: Int = 1,
        getUserDetails: GetUserDetailsInteractorMock = .init(),
        formatBirthDate: FormatBirthDateInteractorMock = .init()
    ) -> UserDetailViewModel {
        UserDetailViewModel(
            userID: userID,
            getUserDetailsInteractor: getUserDetails,
            formatBirthDateInteractor: formatBirthDate
        )
    }

    @Test("Starts loading, then shows the profile for the requested identifier")
    func loadsProfile() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        let sut = makeSUT(userID: 7, getUserDetails: getUserDetails)

        #expect(sut.state == .loading)

        await sut.load()

        #expect(getUserDetails.ids == [7])
        #expect(sut.state == .loaded(.fixture))
    }

    @Test("Loading again after the profile is on screen does not refetch")
    func doesNotRefetchOnceLoaded() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        let sut = makeSUT(getUserDetails: getUserDetails)

        await sut.load()
        await sut.load()

        #expect(getUserDetails.callCount == 1)
    }

    @Test("A missing user becomes .notFound, which the screen renders without a retry")
    func missingUser() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        getUserDetails.result = .failure(.notFound)
        let sut = makeSUT(userID: 9999, getUserDetails: getUserDetails)

        await sut.load()

        #expect(sut.state == .failed(.notFound))
        #expect(!DomainError.notFound.isRetryable)
    }

    @Test("A recoverable failure becomes .failed and stays retryable")
    func recoverableFailure() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        getUserDetails.result = .failure(.notConnected)
        let sut = makeSUT(getUserDetails: getUserDetails)

        await sut.load()

        #expect(sut.state == .failed(.notConnected))
        #expect(DomainError.notConnected.isRetryable)
    }

    @Test("A cancelled load leaves the state alone rather than showing an error")
    func cancellationIsNotAnError() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        getUserDetails.result = .failure(.cancelled)
        let sut = makeSUT(getUserDetails: getUserDetails)

        await sut.load()

        #expect(sut.state == .loading)
    }

    @Test("Retry goes back through loading and can recover")
    func retryRecovers() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        getUserDetails.result = .failure(.timedOut)
        let sut = makeSUT(getUserDetails: getUserDetails)

        await sut.load()
        #expect(sut.state == .failed(.timedOut))

        getUserDetails.result = .success(.fixture)
        await sut.retry()

        #expect(sut.state == .loaded(.fixture))
        #expect(getUserDetails.callCount == 2)
    }

    @Test("Birth dates are formatted through the interactor, not in the view")
    func formatsBirthDate() {
        let sut = makeSUT(formatBirthDate: FormatBirthDateInteractorMock(output: "30 May 1996"))

        #expect(sut.formattedBirthDate(Date(timeIntervalSince1970: 0)) == "30 May 1996")
    }

    @Test("Retry asks for the same user it was created for")
    func retryKeepsIdentifier() async {
        let getUserDetails = GetUserDetailsInteractorMock()
        getUserDetails.result = .failure(.timedOut)
        let sut = makeSUT(userID: 42, getUserDetails: getUserDetails)

        await sut.load()
        await sut.retry()

        #expect(getUserDetails.ids == [42, 42])
    }
}
