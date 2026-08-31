import SwiftUI

enum DSTypography {
    case largeTitle
    case title
    case headline
    case body
    case callout
    case caption

    var font: Font {
        switch self {
        case .largeTitle: .largeTitle.weight(.bold)
        case .title: .title2.weight(.semibold)
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .caption: .caption
        }
    }
}
