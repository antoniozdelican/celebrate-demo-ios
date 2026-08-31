import SwiftUI

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

extension View {
    func onScrollOffsetChange(
        in coordinateSpace: String,
        perform action: @escaping (CGFloat) -> Void
    ) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollOffsetKey.self,
                    value: -proxy.frame(in: .named(coordinateSpace)).minY
                )
            }
        }
        .onPreferenceChange(ScrollOffsetKey.self) { action($0) }
    }
}
