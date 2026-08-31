import Foundation

/// Parser for DummyJSON's unpadded `"1996-5-30"` birth dates.
///
/// A fixed `en_US_POSIX` locale and UTC calendar keep parsing independent of the device's
/// region — the classic source of "works on my machine" date bugs — and make the result
/// stable in snapshot tests.
enum DummyJSONDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-M-d"
        return formatter
    }()

    static func parse(_ value: String) -> Date? {
        formatter.date(from: value.trimmed)
    }
}
