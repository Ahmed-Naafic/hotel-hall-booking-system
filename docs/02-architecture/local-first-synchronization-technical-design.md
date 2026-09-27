---
title: "Local-First Synchronization — Technical Design"
document_type: Technical Design (Cross-Cutting)
status: Draft — pending business decisions and independent review
version: "0.1"
owner: Ahmed
last_updated: 2026-09-27
---

# Local-First Synchronization — Technical Design
## Hotel Hall Booking Management System

**Status:** Draft, partially implemented.

- **Phase 0** (change-detection substrate) — implemented and verified. Commit `34d3c12`,
  26 migrations applied to the Neon test database and a local PostgreSQL 17 container.
- **Phase 1 backend** (`GET /api/v1/sync/:collection`, Manager scope) — **implemented**, 23
  integration tests, full suite green. No migration was required.
- **Phase 1 client** (local database in Manager Mobile) — not started. §16 states the contract it
  must satisfy; the choice of Dart storage engine is a client decision.
- **Phases 2–3** — design only.

This document still requires review by someone other than its author before the client work begins
(`documentation-architecture.md` §4). §20 records the author's own adversarial pass, which is not a
substitute for that.

**Consumers:** Authentication (Module 1), Customer Management (2), Hotel Management (3), Hall
Management (4), Booking Management (5), Calendar & Scheduling (6), Communication & Notification
(10), Administration & Platform Management (13). A cross-cutting document, not a 15th module —
the module list is fixed at 14 (`documentation-architecture.md` §2). It sits in
`docs/02-architecture/` for the same reason `shared-media-technical-design.md` does.

**Derives from:** the backend architecture assessment of 2026-09-25 and its implementation plan,
both of which this document supersedes where they disagree.

---

## 1. Purpose & Scope

Defines what the backend must provide so that Customer Mobile, Manager Mobile and Admin Web can
serve reads from a local replica instead of a round trip, and how that is done without weakening
any existing authorization, transaction, locking or availability protection.

**In scope:** the synchronization model, its cursor semantics, per-collection scoping, tombstones,
derived-visibility propagation, conflict rules, the new API surface, and the security and
performance consequences.

**Out of scope, deliberately:** offline Booking creation (no approved decision exists — §14);
local marketplace search (would amend `BDR-020` — §14); any change to booking concurrency, Hotel
lifecycle, Hall visibility, payment or availability rules; the choice of client-side database,
which is a client concern this document only constrains (§16).

---

## 2. The Three Facts That Shape This Design

Everything below follows from three properties of the existing system, each verified against the
code rather than assumed.

**2.1 Timestamps cannot order changes.** Prisma's `@updatedAt` is stamped when the statement is
built, not when the transaction commits. A transaction that starts earlier can become visible
later, so a client scanning `updated_at > lastSync` can miss a row permanently. This system is
more exposed than most: `createBooking` and `createBlock` run inside 10-second transactions that
take `pg_advisory_xact_lock` first.

**2.2 Hall visibility is derived, never stored.** `visibility.service.js#computeVisibility` returns
`eligible === true && isActive === true` for a non-owner, where `eligible` means the owning Hotel
is `APPROVED_ACTIVE`. Suspending a Hotel writes exactly one row — `hotels.status` — while hiding
every Hall and photo beneath it. No timestamp or sequence on those rows moves.

**2.3 Booking state changes with the clock, on read.** `booking.service.js#advanceLifecycle` expires
overdue unpaid Bookings and completes ended ones, scoped to the caller, on every list and get. A
client cannot compute `EXPIRED` or `COMPLETED` locally, and the server only advances a Booking when
somebody asks for it.

---

## 3. Synchronization Model

Two channels, and the separation is the whole design.

| Channel | Carries | Mechanism |
| --- | --- | --- |
| **Sync** | reads, and owner-edits to uncontended fields | `GET /sync/:collection`, plus the existing write endpoints for replay |
| **Commands** | everything whose validity depends on database state the device cannot see | the existing authenticated endpoints, unchanged |

A local-first client here is **local reads, replicated owner-edits, and remote commands** — not
"everything syncs". Conflating the two is how such systems double-book; the reason it cannot happen
here is that exclusivity lives in a database constraint, not in application code (§12).

---

## 4. `syncSeq` Semantics

**Definition.** Every syncable table carries `sync_seq BIGINT`, drawn from a single shared
PostgreSQL sequence `sync_seq`. One sequence for the whole database, not one per table.

**Guarantees.**

1. **Assigned on insert** by the column default `nextval('sync_seq')`.
2. **Advanced on every update** by a `BEFORE UPDATE` trigger (`sync_seq_bump()`), installed on all
   13 syncable tables.
3. **Globally unique** — verified across 4,552 backfilled rows, zero duplicates. Numbers never
   collide between collections, which keeps a combined feed possible later without renumbering.
4. **Monotonic in commit order**, because `nextval` is evaluated during the write itself.
5. **Gaps are normal** and carry no meaning. A client must never infer "rows are missing" from a
   gap, only from a cursor older than the retention floor (§8).

**Why a trigger rather than repository-layer assignment.** The implementation plan originally
specified the repository layer. That was wrong on two counts, and this document corrects it:
Prisma cannot express `sync_seq = nextval(...)` in an `update`/`updateMany` payload at all, so it
would require rewriting ~25 write paths as raw SQL — including the `updateMany` sweeps that run on
every booking read; and the plan's stated objection (not visible in the same transaction, needs
introspection to test) is false for a `BEFORE` trigger. The trigger also cannot be forgotten by a
future write path, which the repository approach could. Same precedent as the hand-added `EXCLUDE`
constraints.

**What `syncSeq` is not.** Not a version number for optimistic concurrency, not a business field,
never exposed in an API response body except as an opaque cursor.

---

## 5. Entity Scope

13 syncable tables. `users`, `sessions`, `verification_requests`, `password_reset_requests` and
`device_tokens` are **never** replicated.

| Collection | Direction | Scope predicate | Writable by client |
| --- | --- | --- | --- |
| `hotel` (public) | S→C | `status = APPROVED_ACTIVE AND deletedAt IS NULL` | no |
| `hall` (public) | S→C | above, plus `isActive` | no |
| `hotelMedia` / `hallMedia` | S→C | inherits its parent's visibility | no |
| `review` | S→C | public per Hotel | append-only, via existing endpoint |
| `hotel` (own) | S→C | `registeredByUserId = :me` | profile fields only, existing endpoint |
| `hall` (own) | S→C | `hotelId IN (own)` | profile + `isActive`, existing endpoint |
| `hallAvailabilityBlock` | S→C | `hallId IN (own Hotel's Halls)` | **no — command only** |
| `booking` (own Hotel) | S→C | `hotelId IN (own)` | **no — command only** |
| `booking` (own) | S→C | `customerUserId = :me` | **no — command only** |
| `notification` | S→C; read-state C→S | `recipientUserId = :me` | `status` only |
| `chatMessage` | S→C; send + read-state C→S | participant in that Booking | append + `readAt` |
| `savedHotel` | bidirectional | `customerUserId = :me` | yes |
| `customerProfile` | bidirectional | `userId = :me` | yes |
| `hotelApplication` | S→C | own Hotel, or administrator | **no — command only** |
| `criticalInformationChangeRequest` | S→C | own Hotel, or administrator | **no — command only** |

**Popularity and proximity are not entities.** There is no `bookingCount` column and no distance
column; `hotel.service.js` computes both per request. They sync as **ordered id lists** (§13), not
as data.

**Booking customer contact details are excluded from Phase 1.** A Manager legitimately sees the
`fullName` and `mobileNumber` of customers who booked their Hotel — that is approved, and Manager
Mobile shows it today. Durably replicating it onto a device is a different act: `mobileNumber` is
Restricted under `data-architecture.md` §13 and `BR-AUTH-02`, and no approved rule covers local
retention of it. Phase 1 therefore syncs Bookings **without** contact fields, and Manager Mobile
fetches them from the existing endpoint when a Manager opens a Booking. This preserves the approved
rule while inventing no retention policy, and defers a genuine business decision (§14) without
blocking delivery.

---

## 6. Tenant Isolation and Authorization

**Principle:** the scope predicate belongs in the query, never in a filter applied after fetching,
and is derived from `req.identity` only — never from a request parameter. A client asking to sync
"hotel X's bookings" is answered from the Hotels `registeredByUserId` says it owns.

**Mechanism:** one named resolver per collection, in an explicit allowlist. There is no
`GET /sync/:table` that accepts an arbitrary table name. Each resolver reuses the repository
function that already enforces that ownership today (`findForCustomer`, `findForHotel`,
`findByIdForUser`, `findByIdForHotel`) with one additional `syncSeq > :since` clause.

**Scope identity.** Every response carries `scopeId`, a stable hash of
`(userId, accountType, owned hotel ids)`. `accountType` is a token claim, so a device holding data
synced under a role it no longer has would otherwise keep it. A client that sees `scopeId` change
must discard its replica and resync.

**Anonymous sync** uses `optionalAuthenticate`, which already degrades an expired token to the
anonymous view. That is correct for the public marketplace and must never be the path serving a
private collection.

---

## 7. Cursor Semantics, Initial and Incremental Sync

**Query shape.** `WHERE <scope> AND sync_seq > :since ORDER BY sync_seq ASC LIMIT :n`.

**Initial sync** is `since` omitted — the same scan from zero. There is no separate bootstrap path.

**Incremental sync** is `since` = the client's high-water mark.

**The mark advances to the highest `syncSeq` actually received**, never to `serverTime` and never to
a value the client computed. A page is a *consistent prefix*, not a snapshot: a related row may
arrive in a later page, so a client must tolerate temporary referential incompleteness mid-sync and
must not delete a row merely because its parent has not arrived yet.

**Pagination** is bounded, default 20 per `coding-standards.md` §6. `hasNext` is computed the way
every existing list does it — fetch `limit + 1`, return `limit`.

**Ordering is total**, because `syncSeq` is unique. This is deliberately unlike the existing
`createdAt`-ordered cursors, which needed an `id` tiebreaker added (Phase 0/S-01) after measurement
showed eight rows sharing a `created_at` returned seven at `limit=1`.

---

## 8. Resync, Too-Old Cursors, Tombstones and Soft Deletes

**Tombstones.** `hotel_media`, `hall_media` and `hall_availability_blocks` were the only tables
deleting rows outright. They now soft-delete, and every read filters `deletedAt IS NULL` — 13 read
sites. A deletion travels as an ordinary change because the soft delete is an UPDATE, so the
trigger advances `syncSeq`.

**The constraint consequence.** `hall_availability_blocks_no_overlap` had no `WHERE` clause. Once
blocks became tombstones it kept enforcing periods of blocks already deleted — measured: create,
delete, re-block the same period → 409 while `hasOverlap` correctly reported it free. It is now
scoped `WHERE (deleted_at IS NULL)`, mirroring `bookings_no_blocking_overlap`'s own status filter.
**Any future soft delete must check for an unscoped constraint on the same table.**

**Retention floor.** Tombstones are purged after a retention window, and the purge records the
highest `syncSeq` it removed. A `since` below that floor cannot be answered incrementally and
returns a typed `SYNC_CURSOR_EXPIRED` error meaning "discard and resync fully". **It must never be
an empty success** — that is indistinguishable from "nothing changed" and would leave a client
silently wrong forever.

The window length is a business decision (§14). Until it is set, no purge runs and no floor exists,
so `SYNC_CURSOR_EXPIRED` is unreachable — which is safe, and is why retention moved out of Phase 0.

**`updatedAt` requirements.** Six tables lacked it and now have it, with `@default(now()) @updatedAt`
so the database default covers code that predates the column. `syncSeq` is the sync mechanism;
`updatedAt` exists for display and for conflict resolution (§11), not for change detection.

---

## 9. Hotel → Hall Visibility Changes

**The problem** is §2.2: suspending a Hotel changes no Hall row.

**Rejected:** denormalising eligibility onto `Hall`. It would create a second source of truth for a
rule `architecture-principles.md` §5 requires be computed in exactly one place, and
`visibility.service.js` exists specifically to honour that.

**Adopted:** `lifecycle.service.js#transition` bumps `syncSeq` on the Hotel's Halls, `hall_media`
and `hotel_media` in a single statement, so the derived change travels as ordinary changes. Bounded
by one Hotel's Hall count, on an action a Platform Administrator performs rarely. Implemented and
tested in Phase 0.

**The unresolved tension, stated plainly.** Clients must still apply `computeVisibility` themselves
to decide what to show, which means the rule is implemented in the backend and in each client. That
is duplication of a rule this project commits to centralising. Two honest options:

1. **Accept it**, with the backend predicate normative and client implementations tested against the
   same cases. Requires the public Hotel projection to carry `status`, which it does not today.
2. **Ship a precomputed `isVisibleToCustomers` per Hall**, maintained by the lifecycle service.
   Removes the duplication and creates the second source of truth option 1 avoids.

**This document adopts option 1** and records the cost. Option 2 trades a principle for
convenience; option 1 trades convenience for a principle, and the principle is written down.

---

## 10. Media, Notification and Chat Synchronization

**Media.** Already sync-friendly and unchanged. The database stores `storagePath`, never a URL, and
`media.mapper.js` derives a **public, non-expiring** Supabase URL at read time. Therefore: sync
`storagePath` and derive the URL on the client — storing the derived URL would bake in the bucket
host and strand every cached row if the provider changed. There are no signed URLs and so no
expiry concern. Clients cache bytes keyed by `storagePath` and must treat a missing object as
"not yet synced", never an error: `deleteMedia` removes the Supabase object before the row.

**Notifications.** The cleanest collection. Notification V1's rules already state that the row is
the source of truth (Rule 2/13) and push is best-effort and never authoritative (Rule 14/15) —
which maps exactly onto local-first: the local database becomes the display source, and push
becomes a hint to sync. Push already carries `notificationId` and `type`, enough for a targeted
sync. `unreadCountForUser` becomes a local `COUNT`, removing a request made on every launch.

**Chat.** Append-only with a mutable `readAt` set only on the *other* participant's rows, so there
is no write contention. Sends are idempotent on a client-generated UUID. Scope is participation in
the Booking, derived from the same predicates `findForCustomer`/`findForHotel` already use — never
a `bookingId` the client supplies.

---

## 11. Conflict Handling

| Data | Rule | Why it is safe |
| --- | --- | --- |
| `customerProfile.profileData` | last-write-wins per field | single writer — only the Customer |
| `savedHotel` add/remove | add wins over a stale remove | commutative; DB-unique on `(customerUserId, hotelId)` makes replay idempotent |
| `notification.status` | union of reads | monotonic — `markRead` returns early when already `READ`; `markAllReadForUser` is an idempotent `updateMany` |
| `chatMessage.readAt` | earliest wins | monotonic, set only on the other party's rows |
| `chatMessage` send | idempotent on client UUID | append-only |
| everything else | **server authoritative** | §12 |

No server-side merge logic is required for any of the above. That is a property of the existing
rules, not a simplification of them.

---

## 12. Server Authority

These are validated against current PostgreSQL state on every attempt and may **never** be
satisfied from a replica:

Booking creation · Booking confirmation · Booking rejection · Booking cancellation (either party) ·
Complete / No-show · Payment report · Payment verification/rejection · Availability check ·
Availability block create/update/delete · Hotel approve/reject/suspend/deactivate/reactivate ·
Hotel application submit/withdraw · Review submission · Authentication and token refresh · Media
upload and delete.

**Protections that must not be bypassed, and are not:**

- `bookings_no_blocking_overlap` — `EXCLUDE USING gist` over `[startsAt, endsAt)` where status is
  `PENDING`/`CONFIRMED`. The strongest guarantee in the system, and in the right place: no client
  change can weaken it. A queued booking would produce a 409, never a double booking.
- `pg_advisory_xact_lock(hashtext(hallId))` — serializes schedule writes per Hall.
- `assertConfirmable` — re-checks Hotel eligibility, **current** Hall capacity and a fresh
  availability check at confirmation, because all three can drift after creation.
- `createBooking`'s verified-Customer, eligibility, `isActive`, capacity and complete-terms checks.

**Offline behaviour.** Availability and booking creation require connectivity and are presented as
such. Manager decisions (confirm, reject, verify payment) *may* be queued in a later phase — they
are single-writer per Booking and the server rejects an illegal transition with a 409 — but Phase 1
does not queue them, and the app must show "sending" rather than "confirmed" if it ever does.

**Retry, idempotency and failure recovery.** Every queued mutation carries a client-generated
idempotency key, deduplicated server-side, so a retry after an ambiguous timeout cannot apply
twice. Existing DB constraints already make several replays safe (`savedHotel` unique pair,
`review.bookingId` unique, the booking `EXCLUDE`). Server rejections surface as first-class UI:
`ConflictError` → 409 and `BusinessRuleError` → 422 carry distinct messages and a sync layer must
not flatten them.

**The lifecycle-sweep dependency.** A sync response for Bookings must run `advanceLifecycle` for
that scope first, once per request and never per page, or clients hold Bookings stuck `PENDING`
past `paymentDeadlineAt`. The sweep creates `BOOKING_EXPIRED` Notifications, so it must stay
outside any transaction that could roll back — as the existing code is already careful to do.

---

## 13. Discovery, Partial Sync and Performance

**Do not replicate the marketplace.** A Customer's working set is:

1. a geographic window around the device's last known location, generous enough to cover the fixed
   5 km Nearby rule with margin;
2. **unconditionally**, every Hotel the Customer has saved, reviewed, or has a Booking against —
   regardless of window or eligibility, because `SavedHotel`'s own schema comment says a Hotel stays
   saved when it becomes ineligible, and Booking History must render for suspended Hotels;
3. a bounded recency cap, so a cold start is one request.

Manager Mobile needs none of this: its working set is one Hotel, which is why Phase 1 starts there.

**Rankings stay server-side.** Popular aggregates Bookings across all Customers over a rolling 90
days — data no client may hold. Large Halls is inherently global: a device holding 200 of 5,000
Halls would show "the largest of my 200", silently wrong. Both return ordered id lists the client
renders from local rows.

**Measured performance (2,000 Hotels / 1,976 Halls, local PostgreSQL 17, median of 5):**

| Endpoint | Before | After | Change |
| --- | --- | --- | --- |
| `GET /hotels/public/nearby` | 169 ms | **83 ms** | lean candidates, hydrate survivors |
| `GET /halls/large-capacity` | 110 ms | 110 ms | unchanged — see below |
| `GET /hotels/public?limit=20` | 16 ms | 16 ms | already paginated |
| `GET /halls?limit=20` | 15 ms | 15 ms | already paginated |

Nearby was loading every approved Hotel **with its media joined** to answer a question only
coordinates can answer, then keeping ~38 rows. It now selects `id` + `profileData` and joins media
only for the Hotels that survive the radius — the same shape `listLargeHalls` already used.

**Large Halls is deliberately not optimised.** Its candidate query is already lean (four columns).
The remaining cost is the scan itself plus one batched eligibility lookup. The sanctioned fix is
named in Hall Management Technical Design §18 Item 5 — an additive "list eligible Hotels" mode on
Hotel Management's Eligibility Query Interface — and pushing `status` into `hall.repository`
instead would duplicate the eligibility rule, which §9 rejects for the same reason. 110 ms at 2,000
Halls is not yet a measured requirement (`architecture-principles.md` §12), and the linear growth
characteristic is recorded here rather than solved speculatively.

**What local-first does and does not buy.** It buys latency and offline capability. It does **not**
reduce database work — the same queries run on a sync schedule instead of per screen, and total load
may rise because a sync scan fetches rows nobody reads. The documented `GET /halls` N+1 is already
fixed in code (`filterVisible` batches through `getEligibilityForMany`), so Hall Management
Technical Design §18 Item 5 and its Implementation Plan risk register are both out of date on that
point.

---

## 14. Business Decisions Required

Phase 1 needs none of these. They are listed because Phases 2–3 do.

| # | Decision | Blocks | Current approved position |
| --- | --- | --- | --- |
| 1 | May local search return only locally-held Hotels? | Phase 3 | `BDR-020` — search is server-authoritative against **every** Approved/Active Hotel |
| 2 | How stale may discovery data be before the app refuses it? | Phase 3 | none — nothing has ever been cached |
| 3 | May a device durably hold a Booking customer's `fullName`/`mobileNumber`, and for how long? | Phase 2 | disclosure to the Manager is approved; local retention is not addressed. Phase 1 avoids this by excluding the fields (§5) |
| 4 | How long may a device be offline and still trust its replica? | tombstone purge | none |
| 5 | May a Booking be created offline and queued? | Phase 2 | not an approved capability; §12 assumes no |
| 6 | Is Admin Web in scope at all? | Phase 3 | none — it has the best connectivity and the most sensitive data |

None of these may be resolved by implementation choice. Where a phase needs one, the phase stops.

---

## 15. Migration Strategy and Backward Compatibility

**Applied (Phase 0, commit `34d3c12`, 7 migrations):** six `updatedAt` columns; the `sync_seq`
sequence, 13 columns and their backfill; 17 indexes each leading with the scope predicate its
resolver will use; tombstone columns and partial indexes; the `sync_seq_bump()` trigger; the scoped
block-overlap constraint.

**Rules that made those safe, and that later phases must follow:**

1. Set the column `DEFAULT` **before** backfilling and before `SET NOT NULL`. This is not
   theoretical — the first attempt at the `updatedAt` migration failed on inserts arriving
   mid-migration.
2. Every statement idempotent (`IF NOT EXISTS`, `WHERE ... IS NULL`), so a partial failure can be
   re-run.
3. Keep the `updatedAt` defaults rather than dropping them, and declare `@default(now()) @updatedAt`
   in the schema to match, so **application code predating a column keeps inserting successfully**
   until it is redeployed.
4. Verify migration state before and after, and verify the objects themselves — not just the
   migration log.

**Backward compatibility.** Every Phase 0 change is additive and unread by any client; no API
response changed. Phase 1 adds routes and changes none. A deployed app that knows nothing about any
of it continues to work — which was demonstrated, not assumed: the deployed application kept serving
throughout.

---

## 16. Client Requirements

Stated as a contract so any local database can be evaluated against it. **RxDB is not assumed** —
it is a JavaScript library with no Dart implementation, so it could serve Admin Web but neither
Flutter app. A single protocol across all three clients must therefore be plain HTTP + JSON that
each platform's own storage layer consumes.

1. A monotonic, commit-ordered change token per collection.
2. Deletions and de-visibility expressed as **positive change records** — absence is not detectable.
3. Stable, client-generatable row identity — UUID v4 primary keys already satisfy this.
4. A scope identity in every response, so a permission change forces a wipe.
5. Bounded pages with a resumable cursor.
6. A typed too-old-cursor error, never an empty success.
7. Explicit server time; clients never use their own clock for sync state.
8. Idempotency keys on every queued mutation.
9. Commands separate from sync, with typed rejections preserved.
10. The same `SuccessEnvelope`/`ErrorEnvelope` as today (`api-standards.md` §7–§8) — sync does not
    invent a second envelope.

---

## 17. API Design

One route, an explicit collection allowlist, one resolver each.

### `GET /api/v1/sync/:collection` — implemented

Files: `sync.routes.js`, `sync.controller.js`, `sync.validation.js`, `sync.service.js`,
`sync.collections.js` (registry), `sync.repository.js` (the only place Prisma is called),
`sync.scope.js` (tenant resolution), `sync.cursor.js`, `sync.mapper.js`.

Registered collections (Manager scope): `hotel`, `hall`, `hotelMedia`, `hallMedia`,
`availabilityBlock`, `booking`, `notification`, `hotelApplication`. Customer and public collections
are deliberately **not** registered, so no half-scoped resolver is reachable.

| Aspect | Specification |
| --- | --- |
| Purpose | changes to one collection since the client's mark, including tombstones |
| Authorization | `optionalAuthenticate` for public collections; `authenticate` plus the collection's scope predicate for private ones. Scope from `req.identity` only |
| Request | `collection` from a fixed allowlist; `since` (omit for initial); `limit` (bounded, default 20); a working-set parameter for geographic collections |
| Response | `{ data, deleted: [ids], pagination: { hasNext, nextCursor }, scopeId, serverTime }` inside the existing `SuccessEnvelope` |
| Pagination | `syncSeq > since ORDER BY syncSeq ASC LIMIT n`; `nextCursor` is the highest `syncSeq` **in the returned page** |
| Failure | existing `ErrorEnvelope`. `SYNC_CURSOR_EXPIRED` for a mark below the retention floor. Unknown collection → 400 before any query runs |
| Consistency | read-committed suffices given a commit-ordered sequence. A page is a consistent prefix, not a snapshot |

### Queued owner-edits — no new endpoint

Replay goes through the **existing** endpoints (`PATCH /customers/me/profile`,
`POST /notifications/:id/read`, `PUT`/`DELETE /favorites/hotels/:id`), which already carry the
right authorization. Three writable collections do not justify a batch protocol with its own
authorization model. Revisit only if that set grows materially.

---

## 18. Testing Requirements

Phase 1 is not complete without all of these, against a real database:

**Per collection:** insert, update, soft delete each appear exactly once and in order; initial sync;
incremental sync; multiple pages; cursor continuation; empty result; stale cursor; repeated sync is
idempotent.

**Authorization, the highest-value tests here:** a wrong-tenant caller receives nothing, **per
collection**, written before the resolver. The existing suites already test ownership this way —
extend that pattern rather than inventing one. Cross-tenant attempts, role-change invalidation, and
an expired token on a private collection.

**Behavioural:** Hotel suspension and reactivation propagate to Halls and media; Hall `isActive`
toggle; media deletion; notification read-state converging across two simulated devices; retry and
duplicate request.

**Mechanism:** `syncSeq` advances on insert, update, `updateMany` and soft delete — `updateMany`
specifically, because it is the shape a repository-layer implementation would most easily have
missed.

**Regression:** the full backend suite, plus `EXPLAIN` confirming index use for each sync query
shape.

---

## 19. Review Record

Second-pass review findings are recorded in §20 of this document. Per
`documentation-architecture.md` §4 this document additionally requires review by someone other than
its author before Phase 1 implementation begins.

---

## 20. Self-Review Findings

A genuine adversarial pass over §§1–18, recorded rather than silently fixed.

**Corrected during review:**

1. **§4 contradicted the Implementation Plan** on repository-vs-trigger assignment. The plan was
   wrong and is superseded here, with the reasoning stated rather than the change made quietly.
2. **§9 originally understated the duplication cost.** The first draft implied the fan-out solved
   the visibility problem completely. It does not — clients still reimplement `computeVisibility`.
   Now stated as an unresolved tension with both options and the cost of the chosen one.
3. **§5 originally included Booking customer contact fields**, which would have required business
   decision #3 before Phase 1 could ship. Excluding them defers the decision without weakening the
   approved disclosure rule.
4. **§8 gained the constraint-interaction warning.** The block-overlap regression was found by test,
   not by design review, which means the design was incomplete. Generalised: any future soft delete
   must check for an unscoped constraint on the same table.

**Accepted risks, not defects:**

- §13's working-set strategy means a Customer's local replica is a partial marketplace. Local
  *search* over it would amend `BDR-020` and is out of scope (§14 #1), but any locally-rendered
  list is still partial by construction. Phase 3 must surface data age (§14 #2).
- §12's lifecycle-sweep coupling means a sync request performs writes. Unavoidable without changing
  `advanceLifecycle`, which is a Booking Management decision, not this document's.

**Found during implementation review, after the first draft of this document:**

5. **The registry called Prisma directly**, eight times, violating `coding-standards.md` §5 ("the
   only place Prisma Client is called" is the repository). Every other module obeys this. Fixed by
   extracting `sync.repository.js`; the registry is now declarative over it.
6. **`sync.scope.js` imported Hotel Management's repository**, violating
   `architecture-principles.md` §5 — a module must not query another module's data directly. Fixed
   by adding `listOwnedHotelIds` to the existing **Hotel Ownership Query Interface**
   (`ownership.service.js`), which already answered the inverse question and whose own contract
   says ids may cross the boundary but records may not.
7. **The first integration-test helper inserted a Hotel at `APPROVED_ACTIVE`** and was correctly
   refused by `lifecycle.service.js` (`Cannot move a Hotel from PROFILE_COMPLETE to
   APPROVED_ACTIVE`). The test was wrong, not the lifecycle; it now goes through the real endpoints.
   Worth recording because it is evidence the state machine holds against a caller that tries to
   skip it.

**Open question for the independent reviewer:** §9 option 1 vs option 2 is the single decision most
worth a second opinion. This document chose the principle over the convenience; a reviewer who
disagrees should say so before Phase 1 client work begins.
