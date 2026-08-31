import Foundation

enum Gender: Equatable, Sendable {
    case male
    case female
    case other(String)
    case unspecified

    var title: String? {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other(let value): value.capitalized
        case .unspecified: nil
        }
    }
}
