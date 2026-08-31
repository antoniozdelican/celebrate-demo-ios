import Foundation

/// Pagination policy for user lists.
///
/// A domain decision, not a presentation one: the UI should not be able to change what a
/// page costs. Shared by the list and search use cases so the two cannot drift apart —
/// a search that paginated differently from the list would break `Page.nextSkip`
/// arithmetic when switching between them.
enum UsersPage {
    /// 30 sits mid-range of the 20–50 the API is comfortable serving.
    static let size = 30
}
