import Foundation

/// JSON shaped like the real DummyJSON API.
///
/// Kept as inline literals rather than bundle resources: they are small, they diff
/// readably in review, and a test can point at the exact bytes it asserts on without an
/// indirection through `Bundle`.
enum Fixtures {
    /// `GET /users?limit=2&skip=0&select=…` — note `total` far exceeds the page size.
    static let usersPage = json("""
    {
      "users": [
        {
          "id": 1,
          "firstName": "Emily",
          "lastName": "Johnson",
          "email": "emily.johnson@x.dummyjson.com",
          "image": "https://dummyjson.com/icon/emilys/128",
          "company": { "name": "Dooley, Kozey and Cronin", "title": "Sales Manager", "department": "Engineering" }
        },
        {
          "id": 2,
          "firstName": "Michael",
          "lastName": "Williams",
          "email": "michael.williams@x.dummyjson.com",
          "image": "https://dummyjson.com/icon/michaelw/128",
          "company": { "name": "Rowe-Corkery", "title": "Support Specialist", "department": "Product" }
        }
      ],
      "total": 208,
      "skip": 0,
      "limit": 2
    }
    """)

    /// The second page — proves `nextSkip` arithmetic across two real requests.
    static let usersPageTwo = json("""
    {
      "users": [
        {
          "id": 3,
          "firstName": "Sophia",
          "lastName": "Brown",
          "email": "sophia.brown@x.dummyjson.com",
          "image": "https://dummyjson.com/icon/sophiab/128",
          "company": { "name": "Blanda-O'Keefe", "title": "Help Desk Operator", "department": "Services" }
        }
      ],
      "total": 208,
      "skip": 2,
      "limit": 2
    }
    """)

    /// The final page: `skip + count == total`, so nothing follows it.
    static let usersLastPage = json("""
    {
      "users": [
        { "id": 208, "firstName": "Zara", "lastName": "Khan", "email": "zara@x.dummyjson.com", "image": null, "company": null }
      ],
      "total": 208,
      "skip": 207,
      "limit": 2
    }
    """)

    static let emptyPage = json("""
    { "users": [], "total": 0, "skip": 0, "limit": 30 }
    """)

    static let searchResults = json("""
    {
      "users": [
        {
          "id": 1,
          "firstName": "Emily",
          "lastName": "Johnson",
          "email": "emily.johnson@x.dummyjson.com",
          "image": "https://dummyjson.com/icon/emilys/128",
          "company": { "name": "Dooley, Kozey and Cronin", "title": "Sales Manager", "department": "Engineering" }
        }
      ],
      "total": 1,
      "skip": 0,
      "limit": 30
    }
    """)

    /// A row where every optional the API can omit *is* omitted, with whitespace-only
    /// values where it isn't — the mapper must degrade this row, not the response.
    static let sparsePage = json("""
    {
      "users": [ { "id": 42, "image": "   ", "company": { "title": "  " } } ],
      "total": 1,
      "skip": 0,
      "limit": 30
    }
    """)

    static let userDetails = json("""
    {
      "id": 1,
      "firstName": "Emily",
      "lastName": "Johnson",
      "maidenName": "Smith",
      "age": 28,
      "gender": "female",
      "email": "emily.johnson@x.dummyjson.com",
      "phone": "+81 965-431-3024",
      "username": "emilys",
      "password": "emilyspass",
      "birthDate": "1996-5-30",
      "image": "https://dummyjson.com/icon/emilys/128",
      "bloodGroup": "O-",
      "university": "University of Wisconsin--Madison",
      "ssn": "900-590-289",
      "role": "admin",
      "company": { "name": "Dooley, Kozey and Cronin", "title": "Sales Manager", "department": "Engineering" },
      "address": {
        "address": "626 Main Street",
        "city": "Phoenix",
        "state": "Mississippi",
        "postalCode": "29112",
        "country": "United States"
      }
    }
    """)

    static let notFound = json(#"{ "message": "User with id '9999' not found" }"#)

    /// Valid JSON, wrong shape: `total` is a string where the DTO expects an `Int`.
    static let malformedPage = json("""
    { "users": [], "total": "lots", "skip": 0, "limit": 30 }
    """)

    private static func json(_ string: String) -> Data { Data(string.utf8) }
}
