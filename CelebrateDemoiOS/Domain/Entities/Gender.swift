import Foundation

enum Gender: Equatable, Sendable {
    case male
    case female
    case other(String)
    case unspecified
}
