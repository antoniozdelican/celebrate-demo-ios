# CelebrateDemoiOS

A native iOS users directory built with SwiftUI, backed by the
[DummyJSON Users API](https://dummyjson.com/docs/users).

The app lists users with pagination and search, opens a detail screen for each, and is
structured with Clean Architecture — presentation, domain and data layers with
dependencies pointing inwards.

> **Status: scaffolding.** The Xcode project is set up; feature code is not written yet.
> This README describes the target design, and is updated as each layer lands.

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
│   maps DTO→entity     owns endpoints         Alamofire │
│   maps HTTPError→DomainError                           │
└────────────────────────────────────────────────────────┘
```

### Layer responsibilities

**Presentation** — SwiftUI views and their view models. A view model depends only on
interactors, holds screen state, and never sees a DTO, an HTTP status code or a
networking type.

**Domain** — plain Swift. Entities, interactors, and the repository protocol.
Framework-free, so it is testable without a simulator and portable if the app ever grows
a second target.

**Data** — implements the domain's repository contract. Fetches DTOs, maps them to
entities, and translates transport failures into domain failures.

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
| Knows about | verbs, headers, status codes, decoding, retry | the users resource, its endpoints, its DTOs |
| Knows nothing about | users, DummyJSON, pagination | HTTP, Alamofire, JSON |
| Reused by | every future data source | nobody — it *is* the users resource |

Consequences: Alamofire stays confined to the client, so replacing it is a change behind
an unchanged protocol; cross-cutting policy (retry, pinning, logging) is written once;
and there are two testing seams instead of one — fake the client for unit tests, stub the
wire beneath the real client for integration tests.

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
| Unit | Swift Testing | interactors, mapping, error translation, view model state |
| Integration | Swift Testing + `URLProtocol` stub | the real stack with only the wire faked |
| Snapshot | swift-snapshot-testing | design-system components, screen states, light/dark |
| E2E | XCUITest | launch → list → search → detail → animated interaction |

Unit, integration and snapshot tests run from the **CelebrateDemoiOS** scheme:

```bash
xcodebuild test -scheme CelebrateDemoiOS -destination 'platform=iOS Simulator,name=iPhone 16'
```

Swift Testing is used rather than XCTest or a third-party matcher library; it is
first-party from Xcode 16 and needs no dependency. Fakes are hand-written protocol
implementations — Swift has no runtime mocking, and a small fake is clearer than a
generated one.

## Project layout

```
CelebrateDemoiOS/
├── CelebrateDemoiOS.xcodeproj
├── CelebrateDemoiOS/          app sources
├── CelebrateDemoiOSTests/     unit, integration and snapshot tests
├── CelebrateDemoiOSUITests/   XCUITest end-to-end tests
└── docs/adr/                  architecture decision records
```

## Roadmap

- [x] Xcode project, git, tooling
- [ ] Domain: entities and the repository contract
- [ ] Data: endpoints, DTOs, mapping, `HTTPClient`, `UserRemoteDataSource`, `UserRepository`
- [ ] Domain: interactors
- [ ] Design system: reusable components
- [ ] Presentation: list with pagination, pull-to-refresh and search
- [ ] Presentation: detail screen with a Reanimated-equivalent collapsible header
- [ ] Snapshot tests
- [ ] XCUITest end-to-end flow
