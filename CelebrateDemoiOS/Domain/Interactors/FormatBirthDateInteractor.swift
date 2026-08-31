import Foundation

protocol FormatBirthDateInteractorProtocol: Sendable {
    func execute(_ date: Date) -> String
}

struct FormatBirthDateInteractor: FormatBirthDateInteractorProtocol {
    func execute(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
