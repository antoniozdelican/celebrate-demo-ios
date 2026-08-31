import Foundation
@testable import CelebrateDemoiOS

struct FormatBirthDateInteractorMock: FormatBirthDateInteractorProtocol {
    var output = "30 May 1996"

    func execute(_ date: Date) -> String { output }
}
