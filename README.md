# CelebrateDemoiOS

A native iOS users directory built with SwiftUI, backed by the
[DummyJSON Users API](https://dummyjson.com/docs/users).

The app lists users with pagination and search, opens a detail screen for each, and is
structured with Clean Architecture — presentation, domain and data layers with
dependencies pointing inwards.

> **Status: data layer complete.** The domain contract and the full data stack are
> implemented and tested — 50 test cases, no network access. The presentation layer,
> design system and interactors are next.

## Requirements

| | |
|---|---|
| Xcode | 16.4+ |
| Swift | 6.1 |
| Minimum iOS | 17.6 |
| Dependencies | Alamofire (SPM) — no CocoaPods |

## Running

```bash
open CelebrateDemoiOS.xcodeproj
```

Select the **CelebrateDemoiOS** scheme and an iOS 17.6+ simulator, then run (`⌘R`).

From the command line:

```bash
xcodebuild -scheme CelebrateDemoiOS -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

Three layers. `Domain` is the centre and imports nothing — not Alamofire, not SwiftUI,
not the data layer. Dependencies point inwards, and the data layer satisfies contracts
the domain layer declares.

```
┌───────────────────── Presentation ─────────────────────┐
│   View  ──observes──▶  ViewModel                       │
│   SwiftUI, @Observable, @MainActor                     │
└─────────────────────────┬──────────────────────────────┘
                          │ depends on
┌─────────────────────────▼──────────────────────────────┐
│                       Domain                           │
│   Entities        User, UserDetails, Page, DomainError │
│   Interactors     fetch / search / details             │
│   Contracts       UserRepositoryProtocol               │
└─────────────────────────▲──────────────────────────────┘
                          │ implements
┌─────────────────────────┴──────────────────────────────┐
│                        Data                            │
│   UserRepository ─▶ UserRemoteDataSource ─▶ HTTPClient │
│   fetch, then map     owns paths + requests    Alamofire│
└────────────────────────────────────────────────────────┘
```

### Layer responsibilities

**Presentation** — SwiftUI views and their view models. A view model depends only on
interactors, holds screen state, and never sees a response model, an HTTP status code or
a networking type.

**Domain** — plain Swift. Entities, interactors, and the repository protocol.
Framework-free, so it is testable without a simulator and portable if the app ever grows
a second target.

**Data** — implements the domain's repository contract. Fetches response models, maps
them to entities, and translates transport failures into domain failures.

Every conversion is an initialiser on the domain type — `User(response:)`,
`Page(response:)`, `UserDetails(response:)`, `DomainError(httpError:)` — declared in Data
files. Extending a Domain type from Data is fine; declaring these *in* Domain would
invert the dependency rule, since the response models and `HTTPError` are Data types.

### Naming

Protocols are suffixed, implementations are not:

| Contract | Implementation |
|---|---|
| `HTTPClientProtocol` | `HTTPClient` |
| `UserRepositoryProtocol` | `UserRepository` |
| `UserRemoteDataSourceProtocol` | `UserRemoteDataSource` |

## Key decisions

### Networking is split between a client and a data source

Requests could live entirely in the remote data source, or entirely in a shared network
manager. This project does both, split by what each type knows:

| | `HTTPClient` | `UserRemoteDataSource` |
|---|---|---|
| Knows about | verbs, headers, status codes, decoding | the users resource, its paths, its response models |
| Knows nothing about | users, DummyJSON, pagination | HTTP, Alamofire, JSON |
| Reused by | every future data source | nobody — it *is* the users resource |

`HTTPClient`'s initialiser takes only Foundation types (`URL`, `URLSessionConfiguration`),
so no caller imports Alamofire — including the composition root. The library is confined
to two files, `HTTPClient.swift` and `HTTPError.swift`.

There are two testing seams rather than one: fake `HTTPClientProtocol` for unit tests,
stub the wire beneath the real client for integration tests.

No automatic retry. Failures surface through `DomainError.isRetryable` and a user-facing
retry affordance instead — silent retries double latency during a real outage and hide
the failure from the person who could act on it.

### Errors are a closed set

`HTTPError` describes transport failures and stops at the repository. `DomainError`
describes what the UI has to render. The repository translates between them, so no view
ever pattern-matches on a networking type.

### Search runs server-side

`GET /users/search?q=` rather than filtering a locally-held array, because the dataset is
larger than any single page — client-side filtering would only ever search what happened
to be loaded. Input is debounced, and in-flight requests are cancelled when superseded.

## Testing

| Tier | Tooling | Scope |
|---|---|---|
| Unit | Swift Testing | request construction, mapping, error translation, view model state |
| Integration | Swift Testing + `URLProtocol` stub | the real stack with only the wire faked |
| Snapshot | swift-snapshot-testing | design-system components, screen states, light/dark |
| E2E | XCUITest | launch → list → search → detail → animated interaction |

Unit, integration and snapshot tests run from the **CelebrateDemoiOS** scheme:

```bash
xcodebuild test -scheme CelebrateDemoiOS -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Data layer suites (implemented)

| Suite | Kind | Covers |
|---|---|---|
| `HTTPRequestTests` | unit | URL construction, percent-escaping, dropped nil query items |
| `MappingTests` | unit | response→entity degradation, date parsing, pagination arithmetic |
| `DomainErrorTranslationTests` | unit | every `HTTPError`→`DomainError` pair, retryability |
| `UserRemoteDataSourceTests` | unit | request shape and decoding against a faked transport |
| `HTTPClientIntegrationTests` | integration | real Alamofire: validation, `AFError` classification, cancellation |
| `UserRepositoryIntegrationTests` | integration | full stack: pagination across two requests, search, error translation |

**How the integration tests work.** They build the production stack — real
`UserRepository`, real `UserRemoteDataSource`, real `HTTPClient`, real Alamofire
`Session` — and replace only the wire, via a `URLProtocol` stub installed on the
session's `URLSessionConfiguration`. Everything except the socket runs for real, which is
what lets them catch a misconfigured decoder or an unmapped `AFError` branch that a faked
transport never produces.

Each test owns a private `NetworkStub`, routed by a header stamped on its session, so
there is no shared mutable state and the suites run in parallel.

Swift Testing is used rather than XCTest or a third-party matcher library; it is
first-party from Xcode 16 and needs no dependency. Fakes are hand-written protocol
implementations — Swift has no runtime mocking, and a small fake is clearer than a
generated one.

## Project layout

```
CelebrateDemoiOS/
├── CelebrateDemoiOS.xcodeproj
├── CelebrateDemoiOS/
│   ├── App/                   composition root + app entry point
│   ├── Domain/
│   │   ├── Entities/          User, UserDetails, Page, Address, Company, Gender, DomainError
│   │   └── Repositories/      UserRepositoryProtocol
│   └── Data/
│       ├── Network/           HTTPClient, HTTPError, HTTPMethod, HTTPRequest
│       ├── Remote/            UserRemoteDataSource
│       ├── Repositories/      UserRepository
│       ├── Responses/         one response model per file, each with its mapping
│       └── Support/           date parsing, string normalisation
├── CelebrateDemoiOSTests/
│   ├── Support/               URLProtocol stub, fixtures, fakes
│   └── Data/                  data layer unit + integration suites
├── CelebrateDemoiOSUITests/   XCUITest end-to-end tests
└── docs/adr/                  architecture decision records
```

## Roadmap

- [x] Xcode project, git, tooling
- [x] Composition root wiring the data stack
- [x] Domain: entities and the repository contract
- [x] Data: requests, response models, mapping, `HTTPClient`, `UserRemoteDataSource`, `UserRepository`
- [x] Unit and integration tests for the data layer
- [ ] Domain: interactors
- [ ] Design system: reusable components
- [ ] Presentation: list with pagination, pull-to-refresh and search
- [ ] Presentation: detail screen with a Reanimated-equivalent collapsible header
- [ ] Snapshot tests
- [ ] XCUITest end-to-end flow
