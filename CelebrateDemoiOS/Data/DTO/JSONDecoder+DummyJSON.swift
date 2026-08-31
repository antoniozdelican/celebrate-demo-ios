import Foundation

extension JSONDecoder {
    /// DummyJSON already emits camelCase keys, so no key strategy is needed.
    ///
    /// Dates are *not* decoded here: DummyJSON's `birthDate` is `"1996-5-30"` —
    /// unpadded, and therefore rejected by both ISO-8601 and a `yyyy-MM-dd` formatter.
    /// It is carried as a `String` in the DTO and parsed during mapping, where a bad
    /// value degrades to `nil` instead of failing the whole response.
    static var dummyJSON: JSONDecoder {
        JSONDecoder()
    }
}
