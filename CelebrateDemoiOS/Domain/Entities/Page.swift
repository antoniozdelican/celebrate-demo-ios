import Foundation

/// One page of a paginated collection, mirroring DummyJSON's `total` / `skip` / `limit`
/// envelope but expressed in domain terms.
///
/// Pagination state lives here rather than in the presentation layer so that
/// "is there another page?" is answered by the same rule everywhere.
struct Page<Item: Equatable & Sendable>: Equatable, Sendable {
    let items: [Item]
    /// Total number of items available on the server for this query.
    let total: Int
    /// Offset of the first item in `items`.
    let skip: Int
    /// Page size that was requested.
    let limit: Int

    /// Offset to request next, or `nil` when the collection is exhausted.
    ///
    /// Derived from `skip + items.count` rather than `skip + limit`, so a short page
    /// (server returned fewer rows than asked) does not create a gap. An empty page
    /// always terminates, which prevents an infinite scroll loop if `total` is stale.
    var nextSkip: Int? {
        let consumed = skip + items.count
        return consumed < total && !items.isEmpty ? consumed : nil
    }

    var hasMore: Bool { nextSkip != nil }

    static var empty: Page<Item> {
        Page(items: [], total: 0, skip: 0, limit: 0)
    }
}
