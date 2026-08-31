import Foundation

struct Page<Item: Equatable & Sendable>: Equatable, Sendable {
    let items: [Item]
    let total: Int
    let skip: Int
    let limit: Int

    var nextSkip: Int? {
        let consumed = skip + items.count
        return consumed < total && !items.isEmpty ? consumed : nil
    }

    var hasMore: Bool { nextSkip != nil }

    static var empty: Page<Item> {
        Page(items: [], total: 0, skip: 0, limit: 0)
    }
}
