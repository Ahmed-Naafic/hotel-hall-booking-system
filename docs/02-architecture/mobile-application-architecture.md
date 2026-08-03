---
title: "Mobile Application Architecture"
document_type: Architecture
status: Approved
version: 1.0
owner: Ahmed (Chief Mobile Solution Architect)
last_updated: 2026-08-03
---

# Mobile Application Architecture
## Hotel Hall Booking Management System

This document defines the architecture of the Flutter mobile applications. It becomes the
official mobile architecture reference for every developer and AI assistant.

> **Relationship to other documents:** `coding-standards.md` §7 already governs Flutter
> *code-level* patterns (widget organization, UI/business-logic separation, state-management
> principles) — not repeated here beyond what's needed for context. `folder-structure.md`
> §2 already governs the Flutter feature/file structure — this document doesn't redefine it.
> `naming-conventions.md` §6 governs Flutter file naming. `api-standards.md` governs the
> REST contract both apps consume. This document is what sits above all of those: how the
> two apps are architected as a whole — navigation, offline behavior, local storage,
> notifications, and the mobile-specific application of security and performance principles.

---

## 1. Purpose

The platform's primary interfaces are two Flutter apps serving two different users with
different needs from the same backend and the same architectural foundation
(`Architecture-Principles.md` §3):

- **Customer Mobile Application** — search, reserve, and pay for Halls.
- **Hotel Manager Mobile Application** — manage a Hotel's Halls, Bookings, Payments, Staff,
  and Events.

**Both apps share architectural principles because they're built on the same platform,
consume the same API contract (`api-standards.md`), and are maintained by the same small
team** — a difference in *what* each app does for its user never justifies a difference in
*how* either app is structured. What differs between them is scope (§3), not architecture.

---

## 2. Mobile Architecture Principles

The mobile-specific application of `Architecture-Principles.md` §2–§4:

- **Feature-based architecture** — `folder-structure.md` §2; both apps organize by feature,
  never by technical layer at the top level.
- **Separation of concerns** — `coding-standards.md` §7; a widget never contains business
  logic (§5).
- **Reusable components** — genuinely shared widgets live in `shared/`
  (`folder-structure.md` §5), never duplicated between the two apps' `features/`.
- **Offline-friendly design** — the apps degrade gracefully without connectivity (§9)
  rather than becoming unusable.
- **API-first communication** — every interaction with the backend goes through the
  documented REST contract (§8, `api-standards.md`); no app assumes backend internals.
- **Security by design** — `Project-Constitution.md` §8, applied mobile-specifically (§12).
- **Responsive UI** — layouts adapt to device size and orientation, not designed against
  one fixed screen.
- **Maintainability** — `Architecture-Principles.md` §2; a change to one feature doesn't
  require understanding the whole app.
- **Scalability** — the architecture holds as features are added (§18), not just at
  today's two-app, fourteen-module scope.

---

## 3. Mobile Applications

### Customer Mobile App

- **Purpose** — let a Customer search, compare, reserve, and pay for a Hall remotely.
- **Primary users** — Customers (`Project-Glossary.md` §3; eligibility per `BDR-005`).
- **Responsibilities** — Hall search and discovery, Booking creation and management,
  Payment, Reviews, Notifications, account management.
- **Major capabilities** — Authentication, Hall browsing/search, Booking flow, Payment
  flow, Booking history, Review submission, push notifications.

### Hotel Manager Mobile App

- **Purpose** — let a Hotel Manager run their Hotel's day-to-day operations.
- **Primary users** — Hotel Managers, and Staff operating under scoped access
  (`Project-Glossary.md` §3).
- **Responsibilities** — Hall management, Booking oversight, Calendar management, Payment
  tracking, Staff management, Event detail management.
- **Major capabilities** — Authentication, Hall CRUD, Booking calendar view, Staff
  assignment, Payment records, Event management, push notifications.

Both apps exclude Administration & Platform Management, which is confirmed as web-only
(`BDR-007`) — neither mobile app is where a Platform Administrator works.

---

## 4. Feature-Based Structure

Fully governed by `folder-structure.md` §2 — not redefined here. Summary:

```
lib/features/
    authentication/
    bookings/
    payments/
    notifications/
    profile/
```

Every feature owns its presentation, application, domain, and data layers where relevant
(§5) — and its own tests, per `folder-structure.md` §7 and `testing-standards.md`.

---

## 5. Application Layers

The Flutter-specific instance of `Architecture-Principles.md` §4's layering, per
`folder-structure.md` §2:

| Layer | Responsibility |
|---|---|
| **Presentation** | Screens and widgets — renders state, captures user input, contains no business logic (`coding-standards.md` §7). |
| **Application** | Feature-specific use cases and state management (§7) — orchestrates domain/data layers for the presentation layer to consume. |
| **Domain** | The feature's client-side entities and business rules — kept minimal, since the source of business truth is the backend (`Architecture-Principles.md` §4); used for local validation and shaping, not reimplementing server-side rules. |
| **Data** | Repositories and API clients — the only place `api-standards.md`-shaped HTTP calls happen (§8). |
| **Core** | Cross-app infrastructure: routing (§6), theming, error handling scaffolding, the shared network client. |
| **Shared** | Reusable UI components/utilities genuinely used by two or more features (`folder-structure.md` §5). |

---

## 6. Navigation Architecture

- **Feature-based routing** — each feature defines its own routes, composed into the app's
  overall navigation in `core/` (mirroring `folder-structure.md` §3's pattern for the web
  app).
- **Protected routes** — the default; a route requires a valid session (§8, §12) unless
  explicitly public (e.g. login, registration).
- **Public routes** — explicitly identified, never assumed.
- **Navigation guards** — a route that requires a specific role or state (e.g. a completed
  profile before booking) is guarded at the navigation layer, not left to the destination
  screen to redirect after rendering.
- **Deep linking** *(future)* — not required for MVP; the navigation structure doesn't
  preclude adding it later, since routes are already named and feature-owned rather than
  implicit.

---

## 7. State Management Principles

No specific library is prescribed — none is approved in `technology-stack.md`; the choice
is a Technical Design decision made via ADR when the first Flutter module's work begins
(`coding-standards.md` §7, `Decision-Making-Principles.md` §7). Principles that apply
regardless of which library is chosen:

- **Single source of truth** — a piece of state has exactly one owner; it's never
  duplicated into two widgets' local state that could drift apart.
- **Predictable state changes** — state changes through explicit, traceable actions, never
  mutated in place from inside a widget's `build()` method.
- **Separation of UI state and business state** — whether a dropdown is open is UI state,
  local and disposable; a Booking's current status is business state, sourced from the
  backend via the data layer (§5).
- **Minimize global state** — state is scoped to the feature that owns it
  (`Architecture-Principles.md` §3) unless it's genuinely cross-feature (e.g. the
  authenticated user's session).
- **Feature-local state where appropriate** — the default; state is promoted to a broader
  scope only when a real second consumer needs it, not speculatively.

---

## 8. API Communication

- **REST communication** — every backend interaction follows `api-standards.md` exactly:
  envelopes (§7–§8 there), status codes (§9), pagination (§10).
- **HTTP client abstraction** — the data layer (§5) wraps the HTTP client behind a
  repository interface; no widget or application-layer code calls the HTTP client directly
  (`Architecture-Principles.md` §5, infrastructure must not leak into business logic).
- **Authentication headers** — the `Authorization: Bearer <JWT>` header (`api-standards.md`
  §12) is attached centrally by the HTTP client wrapper, not repeated per call site.
- **Token refresh** — handled centrally: a `401` triggers an automatic refresh attempt
  (`api-standards.md` §12) before the original request is retried once; a failed refresh
  routes the user to re-authentication.
- **Error handling** — the data layer translates `api-standards.md` §8's error envelope
  into typed exceptions the application layer can handle meaningfully, never surfacing raw
  HTTP/JSON details to the presentation layer.
- **Retry strategy** — transient network failures are retried with backoff for idempotent
  requests (`api-standards.md` §2) only; a non-idempotent request (e.g. Booking creation)
  is never silently retried without an idempotency mechanism.
- **Request lifecycle** — every request surfaces a loading state to the presentation layer
  and resolves to either data or a typed error — never leaves a screen in an ambiguous
  pending state indefinitely.

---

## 9. Offline Strategy

- **Cached data** — recently-viewed data (e.g. a Hall's details, a Customer's own Bookings)
  is cached locally (§10) so it remains viewable without connectivity.
- **Offline viewing where practical** — read access to already-fetched data degrades
  gracefully; write operations (creating a Booking) require connectivity and say so clearly.
- **Queued operations** *(future)* — offline write queuing is not required for MVP; not
  precluded by this architecture, introduced later if a real need is identified.
- **Synchronization strategy** — cached data is refreshed on reconnect and on relevant
  screen entry, not left silently stale.
- **Graceful degradation** — a lost connection produces a clear, actionable message
  (§13), never a silent failure or a crash.

---

## 10. Local Storage

- **Secure token storage** — JWTs and refresh tokens are stored using the platform's secure
  storage mechanism (Keychain on iOS, Keystore on Android via Flutter's secure storage
  APIs) — never in plain shared preferences (`Project-Constitution.md` §8, Secret
  management).
- **User preferences** — non-sensitive settings (language, notification preferences) may
  use standard local storage.
- **Cached application data** (§9) is stored separately from credentials, with a defined
  expiry so it doesn't silently grow unbounded.
- **Session management** — the current session's validity is checked centrally (§8); a
  logout clears all locally stored tokens and cached data, never leaving residue behind for
  the next user of a shared device.

---

## 11. Notifications

- **Firebase Cloud Messaging** — the approved provider (`technology-stack.md`, ADR-0001).
- **Foreground notifications** — handled in-app with a UI treatment appropriate to context,
  not just an OS-level banner while the app is already open.
- **Background notifications** — delivered via standard platform notification channels
  when the app isn't in the foreground.
- **Deep linking into features** — a tapped notification navigates directly to the relevant
  screen (a specific Booking, for example) via the navigation architecture (§6), not just
  opening the app to its default screen.
- **Notification preferences** — a Customer or Hotel Manager can control which
  notification types they receive, per the eventual Notification Management Business
  Specification — not assumed here.

---

## 12. Security

Principles are `Project-Constitution.md` §8 and `Architecture-Principles.md` §7. Mobile-
specific application:

- **Authentication** — JWT + Refresh Tokens (§8), per `technology-stack.md`.
- **Authorization** — the app reflects only what the authenticated role is permitted to see
  (`api-standards.md` §13) — but the mobile UI hiding an action is a UX convenience, never
  the actual security boundary, which is always enforced server-side.
- **Secure storage** — §10.
- **Session timeout** — an inactive session's refresh token eventually expires, per the
  Authentication & Account Management Technical Design's specifics; the app handles
  expiry gracefully (§8), not as a crash.
- **Biometric authentication** *(future)* — not required for MVP; the secure-storage
  approach (§10) doesn't preclude adding it later as an additional unlock factor.
- **Input validation** — client-side validation is a UX convenience for immediate feedback;
  the server-side validation (`api-standards.md` §14) is the authoritative check, always.
- **Certificate pinning** *(future)* — not required for MVP; a defense-in-depth addition
  considered once the app is closer to production release.

---

## 13. Error Handling

A consistent mobile error strategy, built on `api-standards.md` §8–§9 and
`coding-standards.md` §9:

| Error type | Handling |
|---|---|
| Network errors | A clear "check your connection" state, with retry where the failed request was idempotent (§8). |
| Authentication failures | Automatic refresh attempt (§8); on failure, routed to re-authentication, not a generic error screen. |
| Validation errors | Field-level feedback sourced from `api-standards.md` §8's `details`, shown inline, not as a generic toast. |
| Unexpected failures | A generic, user-friendly message — never a raw stack trace or exception message (`coding-standards.md` §9). |

**Retry mechanisms** apply only to idempotent operations (§8); every error message is
written for the user, not for a developer debugging the app.

---

## 14. UI Principles

- **Consistent design language** across both apps — shared visual and interaction patterns,
  even though their feature sets differ (§3).
- **Reusable widgets** — `shared/` (§5), used rather than recreated per feature.
- **Accessibility** — minimum accessibility requirements are governed by
  `docs/03-standards/ui-ux-and-accessibility-standards.md` (once authored) — not
  re-specified here.
- **Responsive layouts** — §2.
- **Loading, empty, and error states** — every screen that fetches data explicitly designs
  for all three, not just the happy-path "data arrived" state.
- **Dark mode support** *(future)* — not required for MVP; the design-language approach
  above doesn't preclude adding it later.

---

## 15. Performance

Principles are `Architecture-Principles.md` §12. Mobile-specific guidelines:

- **Lazy loading** — data and images load as needed, not all upfront (§9's cached data
  notwithstanding).
- **Image optimization** — images are requested at a size appropriate to where they're
  displayed, via the storage abstraction's capabilities (`Architecture-Principles.md` §10),
  not full-resolution originals rendered into thumbnails client-side.
- **Pagination** — list screens consume `api-standards.md` §10's pagination contract,
  never fetch an unbounded list.
- **Efficient widget rebuilding** — state changes (§7) trigger rebuilding only the widgets
  that actually depend on the changed state.
- **Memory management** — resources (image caches, streams, controllers) are disposed when
  a screen/widget is removed, not left running.
- **Smooth scrolling** — list views use lazy-building list widgets, not rendering entire
  large collections at once.

---

## 16. Testing Strategy

Governed in full by `testing-standards.md` — mobile-specific application:

- **Unit testing** — application/domain layer logic (§5), per `testing-standards.md` §5.
- **Widget testing** — presentation-layer widgets, verifying they render correctly for a
  given state without needing a real device.
- **Integration testing** — a feature's full flow against a test backend, per
  `testing-standards.md` §6.
- **Manual testing** — device/platform-specific verification automation can't fully cover
  (`testing-standards.md` §7).
- **Feature validation** — business rule validation per `testing-standards.md` §8, same as
  every other module.

---

## 17. AI Development Rules

This restates and is governed by `Project-Constitution.md` §4 and `coding-standards.md`
§15 — see those for the canonical AI rules. Mobile-specific additions only:

- **AI must follow Feature-Based Architecture** (§4) — never introducing a top-level
  layer-based grouping.
- **AI must respect approved navigation** (§6) — never adding an undocumented route or
  bypassing a navigation guard.
- **AI must never duplicate business logic** already owned by the backend (§5's domain
  layer is for shaping, not reimplementing).
- **AI must reuse shared components** (§5) rather than recreating them per feature.
- **AI must follow `coding-standards.md` and `naming-conventions.md`** exactly.
- **AI must keep UI and business logic separated** (§5) — a widget's `build()` method never
  contains business rules.

---

## 18. Future Evolution

This architecture supports, without major restructuring
(`Development-Roadmap.md` §2, Design for Extensibility):

- **Additional mobile applications** — a third app would follow the same layered,
  feature-based structure (§4–§5) and the same API contract (§8).
- **New features** — added as new `features/` folders (§4), never requiring existing
  features to be reorganized.
- **Internationalization** — the layered structure already isolates presentation (§5) from
  business logic, which is where localized strings live without touching application logic.
- **Accessibility improvements** — layered on top of §14 without restructuring.
- **Offline enhancements** — §9's "future" queued-operations capability builds on the same
  data-layer abstraction (§5) already in place.
- **Additional notification providers** — swappable behind the same abstraction principle
  already established for storage (`Architecture-Principles.md` §10–§11).

---

## 19. Mobile Architecture Checklist

- [ ] Feature isolation respected (§4).
- [ ] Layer separation respected — no business logic in the presentation layer (§5).
- [ ] Navigation follows §6, no undocumented routes.
- [ ] State management follows §7's principles.
- [ ] Security requirements met (§12).
- [ ] API integration follows `api-standards.md` and §8.
- [ ] Error handling follows §13.
- [ ] Performance guidelines followed (§15).
- [ ] Testing complete per §16 and `testing-standards.md`.
- [ ] Documentation updated to match what was actually built.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-03 | Ahmed | Initial approved Mobile Application Architecture |
