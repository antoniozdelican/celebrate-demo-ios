# CelebrateDemoiOS

A native iOS users directory built with SwiftUI, backed by the
[DummyJSON Users API](https://dummyjson.com/docs/users).

The app lists users with pagination and search, opens a detail screen for each, and is
structured with Clean Architecture — presentation, domain and data layers with
dependencies pointing inwards.

> **Status: complete.** All four layers are implemented, the app runs against the live
> API, and 93 tests pass with no network access — 76 unit and integration, 9 snapshot,
> 8 end-to-end.

## Requirements

| | |
|---|---|
| Xcode | 16.4+ |
| Swift | 6.1 |
| Minimum iOS | 17.6 |
| Dependencies | Alamofire, swift-snapshot-testing (SPM) — no CocoaPods |

## Running

```bash
open CelebrateDemoiOS.xcodeproj
```

Select the **CelebrateDemoiOS** scheme and an iOS 17.6+ simulator, then run (`⌘R`).

There is no Android target: the brief allowed a native implementation, and this is one —
SwiftUI, Alamofire, XCUITest. The React Native equivalents map as `FlatList` → `List`,
Reanimated → SwiftUI animation, Jest + React Native Testing Library → Swift Testing, and
Detox → XCUITest.

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
│   View  ──observes──▶  ViewModel  ──▶ Interactors      │
│   SwiftUI, @Observable, @MainActor                     │
│   Navigation is a Route enum, resolved in RootView     │
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
a networking type. Each screen exposes its state as an enum — `UserListViewState`,
`UserDetailViewState` — so every case the UI must render is enumerated in one place.

**DesignSystem** — a sibling of Presentation rather than a folder inside it, because the
rule that matters is that it knows *nothing* about the domain. `DSAvatar` takes a `URL`
and initials, not a `User`; `DSStateView` takes a title, message and retry closure, not a
`DomainError`. Only SwiftUI and CoreGraphics are imported there. `UserRow`, which does
know about `User`, lives in Presentation and composes design-system components.

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

### Error handling is a closed set with per-case behaviour

Two enums and one translation point. `HTTPError` describes transport failures and stops
at the repository; `DomainError` describes what the UI has to render. `DomainError(httpError:)`
is exhaustive over `HTTPError`, so adding a transport case breaks the build until it is
mapped, and no view ever pattern-matches on a networking type.

`UserRepositoryProtocol` is declared `async throws(DomainError)`. Translation is therefore
a compiler requirement rather than a review comment — a raw `URLError` cannot reach a view
model by accident.

What each failure does, and why:

| Case | Behaviour |
|---|---|
| `.notConnected`, `.timedOut`, `.server`, `.unknown` | full-screen error with **Try again** |
| `.notFound` | its own state — "User not found", **no retry**, because retrying a deleted user fails identically every time |
| `.cancelled` | **state left untouched**. A superseded search keystroke is not a failure the user should see |
| `.invalidResponse` | error state, no retry — a malformed payload will be malformed again |

`DomainError` carries `isRetryable` and `errorDescription`, so the presentation layer
decides *how* to render a failure without re-deriving *which* failures are recoverable.

Two rules beyond the enum:

**Mapping degrades, it never fails.** A row with missing or whitespace-only fields becomes
empty strings and `nil`s rather than throwing, so one malformed record cannot blank the
whole list. Anything genuinely unusable fails at decode instead.

**A pagination failure keeps what is already on screen.** Failing to load page three sets
no error state; it stops pagination and leaves the first two pages rendered, rather than
replacing what the user is reading with a full-screen error.

No automatic retry. `RetryPolicy` was removed: silent retries double latency during a real
outage and hide the failure from the person who could act on it. Failures surface to the
user with a retry affordance instead.

### Navigation is a route enum, not a router

Rows push `NavigationLink(value: Route.userDetail(userID:))`, and `RootView` owns the one
`navigationDestination(for: Route.self)` that maps routes to screens. `UserListView`
therefore does not know `UserDetailView` exists.

A `Router` owning a `NavigationPath` was built and removed: taps go through
`NavigationLink`, so `push`/`pop` had no callers and the type only wrapped a path the
stack already manages. That seam belongs with deep linking, programmatic navigation from
a view model, or state restoration — none of which exist yet, and the `Route` enum is
already in place to build on.

### View models are protocol-backed and own their state

Each screen depends on a protocol — `UserListViewModelProtocol`,
`UserDetailViewModelProtocol` — so tests and previews can substitute one. Views are
generic over that protocol rather than holding an existential, which is what allows
`$viewModel.query` to form a binding.

Screens own their view model through `@State` with an injected initial value: the caller
supplies it, the screen keeps it for that view identity. That matters for the detail
screen, whose view model is built inside `navigationDestination` — a plain `let` would
hand it a new, empty view model each time SwiftUI re-evaluated the closure.

### The search bar is the platform's, not the design system's

`.searchable(text:prompt:)` replaced a custom `DSSearchField`. The custom field had to be
pinned outside the scroll view, which fought the large navigation title: during
rubber-band overscroll the title's frame extends over anything pinned beneath the bar.
Working around it cost a `safeAreaInset`, an inline title, a `contentMargins` override and
a pinned section header, each fixing one symptom and causing another.

`.searchable` puts the field in the navigation bar's own chrome, so it sticks while
scrolling, the large title collapses correctly, and the Cancel button, scroll-to-dismiss
keyboard and VoiceOver search semantics come for free. The design system keeps five
components, above the brief's minimum of three.

### The collapsible header is driven by scroll offset

`CollapsibleHeader` reads the scroll offset through a preference key in a named
coordinate space, maps it to a 0…1 progress over 120pt, and shrinks the avatar, scales
the name, fades the subtitle out early and tightens padding. Past 90% the name is handed
to the navigation bar. The offset is clamped, so overscroll and rubber-band cannot invert
the avatar or push opacity out of range.

The header sits beside the scroll view rather than in a `safeAreaInset`: an inset view's
height feeds the scroll view's content inset, which feeds the offset the header is driven
by, and that coupling is worth avoiding even where it is not currently misbehaving.

It lives in `Presentation/UserDetail`, not the design system. Its API is domain-free, so
it *could* move, but it has one consumer and its constants — the collapse distance, how
far the avatar shrinks — are decisions for this screen rather than tokens other screens
should inherit. Components are promoted on the second consumer.

The animation is verified end to end by `UserFlowUITests`, which asserts the name moves
into the navigation bar after scrolling. It asserts that rather than the header's frame:
`accessibilityElement(children: .combine)` makes the reported frame the union of the
header's children, not its visual height, so measuring it is misleading.

### Scalability and performance

The decisions that matter as the dataset and the UI grow, and what would matter next.

**Payload size.** List and search requests send
`select=firstName,lastName,email,image,company`, trimming each user from ~30 fields to 5.
Across 208 users that is most of the bytes and most of the decode time. The detail screen
fetches the full record, once, for one user.

**Pagination cannot run away.** `Page.nextSkip` is derived from `skip + items.count`, not
`skip + limit`, so a short page does not open a gap, and an empty page terminates even if
`total` disagrees. Without that last rule a stale `total` produces an infinite scroll loop
that keeps requesting forever.

**Superseded work is cancelled, not awaited.** Search debounce comes from
`.task(id: viewModel.query)`: changing the query cancels the previous task, so typing
"Emily" issues one request rather than five. Cancellation is a first-class `DomainError`
case that leaves state untouched, so a superseded keystroke never flashes an error.

**One client for the app's lifetime.** `HTTPClient` owns a `Session`, which owns a
`URLSession` and its connection pool. It is built once in the composition root —
rebuilding it per screen would discard connection reuse and leak sessions.

**A pagination failure keeps the rows already on screen** rather than replacing the list
with a full-screen error, so a failed page-three request does not discard what the user is
reading.

**What would actually bite first.** `AsyncImage` is the real cost in a long list: no
cache, so it refetches on every reappearance, and no downsampling, so a 128px image is
decoded at full size. That is the first thing to fix, ahead of anything about view
invalidation. `@Observable` gives per-property invalidation, but this screen's body reads
every property it publishes, so the benefit only appears once the row list is extracted
into a child view that reads just `state` — the change that makes the granularity
meaningful rather than theoretical.

**Not measured.** None of the above is profiled. At 30 rows with a lazy `List` the
expectation is that none of it is detectable; the claims are about mechanism, not
measurements.

### Search runs server-side

`GET /users/search?q=` rather than filtering a locally-held array, because the dataset is
larger than any single page — client-side filtering would only ever search what happened
to be loaded.

Debounce comes from `.task(id: viewModel.query)`: changing the query cancels the previous
task, so a keystroke that is overtaken never reaches the interactor. A cancelled load
leaves the state untouched rather than showing an error, since a superseded search is not
a failure the user should see. List and search are separate use cases —
`GetUsersInteractor` and `SearchUsersInteractor` — rather than one interactor taking a
possibly-blank query, which would make an empty string a sentinel meaning "no filter".

## Testing

| Tier | Tooling | Scope |
|---|---|---|
| Unit | Swift Testing | request construction, mapping, error translation, view model state |
| Integration | Swift Testing + `URLProtocol` mock | the real stack with only the wire faked |
| Snapshot | swift-snapshot-testing | design-system components, variants, light and dark |
| E2E | XCUITest | launch → list → search → detail → animated interaction |

93 tests, none of which touch the network. All of them run from the
**CelebrateDemoiOS** scheme, in Xcode with `⌘U` or from the command line.

**Everything:**

```bash
xcodebuild test -scheme CelebrateDemoiOS -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Unit, integration and snapshot only** (fast, no app launch):

```bash
xcodebuild test -scheme CelebrateDemoiOS -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CelebrateDemoiOSTests
```

**End-to-end only:**

```bash
xcodebuild test -scheme CelebrateDemoiOS -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CelebrateDemoiOSUITests
```

The UI tests are sensitive to simulator state: a stale device reports
"Failed to install or launch the test runner", which reads like a broken suite but is not.
Erasing and fully booting first avoids it.

```bash
xcrun simctl erase "iPhone 16" && xcrun simctl bootstatus "iPhone 16" -b
```

### Suites

| Suite | Kind | Covers |
|---|---|---|
| `HTTPRequestTests` | unit | URL construction, percent-escaping, dropped nil query items |
| `MappingTests` | unit | response→entity degradation, date parsing, pagination arithmetic |
| `DomainErrorTranslationTests` | unit | every `HTTPError`→`DomainError` pair, retryability |
| `UserRemoteDataSourceTests` | unit | request shape and decoding against a faked transport |
| `HTTPClientIntegrationTests` | integration | real Alamofire: validation, `AFError` classification, cancellation |
| `UserRepositoryIntegrationTests` | integration | full stack: pagination across two requests, search, error translation |
| `GetUsersInteractorTests` | unit | which repository call the use case makes, and at what page size |
| `SearchUsersInteractorTests` | unit | trimming, blank terms making no request, page size agreeing with the list |
| `GetUserDetailsInteractorTests` | unit | identifier passed through, failures propagated |
| `UserListViewModelTests` | unit | state machine: search, debounce cancellation, pagination, refresh, retry |
| `UserDetailViewModelTests` | unit | load-once guard, notFound versus recoverable failures, retry |
| `DSButtonSnapshotTests` | snapshot | variants, sizes, loading versus disabled, dark mode |
| `DSStateViewSnapshotTests` | snapshot | empty and failure states |
| `DSComponentSnapshotTests` | snapshot | typography scale, avatar sizes, card |
| `UserFlowUITests` | e2e | list, search and clear, no-match, tap into detail, header collapse, failure and empty scenarios |

**How the integration tests work.** They build the production stack — real
`UserRepository`, real `UserRemoteDataSource`, real `HTTPClient`, real Alamofire
`Session` — and replace only the wire, via a `URLProtocol` stub installed on the
session's `URLSessionConfiguration`. Everything except the socket runs for real, which is
what lets them catch a misconfigured decoder or an unmapped `AFError` branch that a faked
transport never produces.

Each test owns a private `NetworkMock`, routed by a header stamped on its session, so
there is no shared mutable state and the suites run in parallel.

**How the UI tests work.** They run the app out of process, so the integration tests'
`MockURLProtocol` cannot reach it — something has to live in the app target. That
something is `UITestURLProtocol`, a `#if DEBUG` protocol the composition root installs
under a `-uiTesting` launch argument, with `STUB_SCENARIO` selecting success, empty or
error.

It fakes the **wire**, not the repository, so the UI tests still run through `HTTPClient`,
the data source, decoding, mapping and error translation. An earlier version replaced the
repository and skipped all of that — those tests would have passed with a broken decoder.
Faking the wire is also what makes the error state reachable at all: the live API will
not return a failure on request.

**Naming.** Anything that stands in for a collaborator is a `*Mock` and lives in
`Tests/Mocks`. Test *data* is a `*.fixture` in `Tests/Support`. `TestStack` is neither —
it assembles the real production stack with only the wire replaced.

**How the snapshot tests work.** They cover the design system, which is what satisfies the
brief's "test at least one reusable UI component". The `DSButton` loading case pins a real
bug: `.disabled(isLoading)` applied SwiftUI's disabled styling and desaturated the accent
fill, so a loading button looked dead rather than busy.

Tolerances are deliberately below 1 — `precision: 0.99`, `perceptualPrecision: 0.98`.
Exact pixel equality fails on antialiasing differences nobody would call a regression, and
that is the usual reason snapshot suites get deleted rather than maintained.

These are the only XCTest suites in the project; everything else uses Swift Testing. Under
Swift Testing each `assertSnapshot` ran twice in this bundle, recording two references per
component. XCTest runs each once, and is the library's primary integration.

> **References were recorded on an Intel Mac, iPhone 16, iOS 18.6.** Text renders
> differently on Apple Silicon, so they will need re-recording on a different machine or
> in CI. Record with:
>
> ```bash
> SNAPSHOT_TESTING_RECORD=all xcodebuild test -scheme CelebrateDemoiOS \
>   -destination 'platform=iOS Simulator,name=iPhone 16'
> ```

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
│   │   └── UITesting/         DEBUG-only URLProtocol serving fixtures to UI tests
│   ├── Domain/
│   │   ├── Entities/          User, UserDetails, Page, Address, Company, Gender, DomainError
│   │   ├── Interactors/       GetUsers, SearchUsers, GetUserDetails
│   │   └── Repositories/      UserRepositoryProtocol
│   ├── Data/
│   │   ├── Network/           HTTPClient, HTTPError, HTTPMethod, HTTPRequest
│   │   ├── Remote/            UserRemoteDataSource
│   │   ├── Repositories/      UserRepository
│   │   ├── Responses/         one response model per file, each with its mapping
│   │   └── Support/           date parsing, string normalisation
│   ├── DesignSystem/
│   │   ├── Tokens/            spacing, radius, colour, typography
│   │   └── Components/        DSText, DSButton, DSAvatar, DSCard, DSStateView
│   └── Presentation/
│       ├── Navigation/        Route
│       ├── Root/              RootView
│       ├── Support/           scroll offset reporting
│       ├── UserList/          view, view model, state, row
│       └── UserDetail/        view, view model, state, collapsible header
├── CelebrateDemoiOSTests/
│   ├── DesignSystem/          snapshot suites + recorded references
│   ├── Mocks/                 one test double per file, all *Mock
│   ├── Support/               TestStack, JSON fixtures, entity fixtures
│   ├── Data/                  data layer unit + integration suites
│   ├── Domain/                interactor suites
│   └── Presentation/          view model suites
└── CelebrateDemoiOSUITests/   end-to-end flow
```


## Roadmap

- [x] Xcode project, git, tooling
- [x] Composition root wiring the data stack
- [x] Domain: entities and the repository contract
- [x] Data: requests, response models, mapping, `HTTPClient`, `UserRemoteDataSource`, `UserRepository`
- [x] Unit and integration tests for the data layer
- [x] Domain: interactors
- [x] Design system: tokens and reusable components
- [x] Presentation: list with pagination, pull-to-refresh and search
- [x] Presentation: detail screen and navigation
- [x] Presentation: collapsible header animation on the detail screen
- [x] XCUITest end-to-end flow
- [x] Snapshot tests for the design system

## What I would do with more time

- **Modularise into local Swift packages.** The layering is currently a convention held
  by folder structure and discipline. Domain, Data, DesignSystem and Presentation as
  separate targets would make the dependency rule a compile-time guarantee — an
  accidental `import` would fail to build rather than pass review.
- **Cache and downsample avatars.** `AsyncImage` refetches on every reappearance and
  decodes at full size. That, not view invalidation, is the real cost in a long list.
- **A Router**, once deep linking or programmatic navigation needs one.
- **Cover pull-to-refresh end to end.** It is implemented and unit-tested through
  `refresh()`, but no UI test performs the gesture, so the wiring between the gesture and
  the view model is verified only by compiling.
- **Profile the animation.** "Smooth and performant" is currently asserted by eye. A
  Core Animation trace during the header collapse would make it a measurement.
- **Contract tests against the live API**, in a scheme excluded from the default test
  action, to catch upstream drift without making pull-request runs depend on the network.
