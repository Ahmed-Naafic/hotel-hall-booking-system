---
title: "Local-First Synchronization — Technical Design"
document_type: Technical Design (Cross-Cutting)
status: Draft — independently reviewed (model reviewer); human review by Mohamed or Abukar pending
version: "0.2"
owner: Ahmed
last_updated: 2026-09-28
---

# Local-First Synchronization — Technical Design
## Hotel Hall Booking Management System

**Status:** Draft, Phase 1 implemented.

- **Phase 0** (change-detection substrate) — implemented and verified. Commit `34d3c12`.
- **Phase 1 backend** (`GET /api/v1/sync/:collection`, Manager scope) — implemented (`6dd8644`),
  then **corrected** after independent review: the cursor is now a snapshot window (§4, §7), because
  the original `sync_seq` cursor could skip a late-committing row permanently. Two migrations
  (`20260928100000`, `20260928110000`), applied to the Neon test database and a local PostgreSQL 17
  container. 40 sync integration tests; full backend suite green.
- **Phase 1 client** (Manager Mobile) — implemented: SQLite replica (ADR-0009), sync engine, and
  the Hall list reading locally (§16).
- **Phases 2–3** — design only.

**Review.** `documentation-architecture.md` §4 requires review by Mohamed or Abukar before this
becomes `Approved`. An independent review by a separate model reviewer, with no authorship context,
was carried out on 2026-09-28 and is recorded in §19; it found three blockers, all resolved. It is
not a substitute for the human review, which remains outstanding.

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

**2.1 Neither timestamps nor sequences order changes by commit.** Prisma's `@updatedAt` is stamped
when the statement is built, not when the transaction commits. A transaction that starts earlier can
become visible later, so a client scanning `updated_at > lastSync` can miss a row permanently.
**A sequence has exactly the same defect**: `nextval()` is drawn when the row is written, and the
row becomes visible at COMMIT. Version 0.1 of this document missed that (§20, finding 8). This
system is more exposed than most: `createBooking` and `createBlock` run inside 10-second
transactions that take `pg_advisory_xact_lock` first. The only correct ordering is visibility
itself — which transactions had committed as of a snapshot (§4).

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

## 4. `syncSeq`, `syncTxid` and Snapshot Windows

**Definition.** Every syncable table carries two columns:

- `sync_seq BIGINT NOT NULL`, drawn from one shared PostgreSQL sequence `sync_seq` — one sequence
  for the whole database, not one per table.
- `sync_txid BIGINT`, the top-level transaction that last wrote the row
  (`pg_current_xact_id()`, a 64-bit `xid8` that never wraps). NULL only for rows last written
  before the column existed.

**Guarantees.**

1. **Assigned on insert** by column defaults (`nextval('sync_seq')`, `pg_current_xact_id()`).
2. **Both advanced on every update** by a `BEFORE UPDATE` trigger (`sync_seq_bump()`), installed on
   all 13 syncable tables.
3. **`sync_seq` is globally unique** — verified across 4,552 backfilled rows, zero duplicates.
4. **`sync_seq` is NOT commit-ordered.** Version 0.1 claimed it was, and that was false: `nextval`
   is drawn at write time, visibility happens at COMMIT, and a transaction holding a lower number
   can commit after one holding a higher number. Reproduced on PostgreSQL 17 before the fix (§20,
   finding 8). `sync_seq` is therefore used **only** to order and page rows *within* one batch.
5. **Delivery is ordered by visibility instead.** A batch is bounded by two PostgreSQL snapshots,
   `lo` and `hi`, and contains exactly the rows whose `sync_txid` is visible in `hi` and was not
   visible in `lo` (`pg_visible_in_snapshot`). Consecutive batches share their boundary
   (`next.lo = this.hi`), so every committed write falls in exactly one batch, whatever order
   transactions commit in. This is the design PgQ/Skytools uses for the same problem.
6. **A long transaction delays only its own rows.** They are not yet visible in `hi`, so they
   arrive in a later batch. Nobody else's sync stalls — unlike the alternative of serving only rows
   older than the oldest running transaction, which lets any idle-in-transaction session freeze
   every client.
7. **Gaps in `sync_seq` are normal** and carry no meaning. A client never infers "rows are missing"
   from anything but `SYNC_CURSOR_EXPIRED` (§8).

**A media change is a change to its parent.** A synced Hall or Hotel embeds its photos (§10), so an
`AFTER` trigger on `hall_media`/`hotel_media` bumps the parent whenever a column the parent's
mapped shape contains changes (`type`, `storage_path`, `display_order`, `deleted_at`, the parent
key). Bumps that change only `sync_seq` — the lifecycle fan-out in §9 — are excluded by the
trigger's `WHEN` clause, so they do not cascade once per photo.

**Lock order: children before parents.** A photo delete locks the media row, then (through that
trigger) its parent. The lifecycle fan-out therefore bumps `hall_media`, `hotel_media`, `halls` in
that order and, inside a transaction, before the Hotel's own status write — the reverse order can
deadlock (40P01) against a concurrent photo delete (§20, finding 13).

**Why a trigger rather than repository-layer assignment.** The implementation plan originally
specified the repository layer. That was wrong on two counts, and this document corrects it:
Prisma cannot express `sync_seq = nextval(...)` in an `update`/`updateMany` payload at all, so it
would require rewriting ~25 write paths as raw SQL — including the `updateMany` sweeps that run on
every booking read; and the plan's stated objection (not visible in the same transaction, needs
introspection to test) is false for a `BEFORE` trigger. The trigger also cannot be forgotten by a
future write path, which the repository approach could. Same precedent as the hand-added `EXCLUDE`
constraints.

**What `syncSeq` is not.** Not a version number for optimistic concurrency, not a business field,
and not a cursor. Each synced row carries it (as a decimal string) so a client can tell two
versions of one row apart; a client must never build a cursor from it.

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
Mobile shows it today. Durably replicating it onto a device is a different act: customer contact
details are **Confidential** under `data-architecture.md` §13, and no approved rule covers local
retention of them. (Version 0.1 called them "Restricted" and cited `BR-AUTH-02`; Restricted is
credentials and tokens, and `BR-AUTH-02` is mobile-number verification, not retention — §20,
finding 16. The conclusion is unchanged.) Phase 1 therefore syncs Bookings **without** contact fields, and Manager Mobile
fetches them from the existing endpoint when a Manager opens a Booking. This preserves the approved
rule while inventing no retention policy, and defers a genuine business decision (§14) without
blocking delivery.

For the same reason the synced Hotel omits `registeredBy`, which carries the Manager's own mobile
number: Manager Mobile takes its identity from the session, so the field had no reader, and it could
not stay fresh — renaming a user bumps no Hotel row.

**Classification of what Phase 1 replicates** (`data-architecture.md` §13 requires one per entity):

| Collection | Classification | Note |
| --- | --- | --- |
| `hotel`, `hall`, `hotelMedia`, `hallMedia` | Public / Internal | profile data is public once Approved; own-Hotel status and inactive Halls are Internal |
| `availabilityBlock` | Internal | |
| `booking` | Internal | contact fields excluded, which is what keeps it out of Confidential; money figures are the Hotel's own |
| `notification` | Internal | addressed to the caller only |
| `hotelApplication` | Internal | the Hotel's own review history |

---

## 6. Tenant Isolation and Authorization

**Principle:** the scope predicate belongs in the query, never in a filter applied after fetching,
and is derived from `req.identity` only — never from a request parameter. A client asking to sync
"hotel X's bookings" is answered from the Hotels `registeredByUserId` says it owns.

**Mechanism:** one named scope predicate per collection, in an explicit allowlist
(`sync.collections.js`, `sync.repository.js`). There is no `GET /sync/:table` that accepts an
arbitrary table name, and no table name or SQL fragment ever comes from the request. Owned Hotel ids
are resolved through Hotel Management's Ownership Query Interface (`listOwnedHotelIds`), never its
repository; child collections (`hallMedia`, `availabilityBlock`) are scoped through their Hall's
owning Hotel, never a `hallId` from the client. An empty scope matches nothing
(`= ANY('{}')`), asserted by test rather than assumed.

**Scope identity.** Every response carries `scopeId`, a stable hash of
`(userId, accountType, owned hotel ids)`. `accountType` is a token claim, so a device holding data
synced under a role it no longer has would otherwise keep it. A client that sees `scopeId` change
must discard its replica and resync.

**Anonymous sync** uses `optionalAuthenticate`, which already degrades an expired token to the
anonymous view. That is correct for the public marketplace and must never be the path serving a
private collection.

---

## 7. Cursor Semantics, Initial and Incremental Sync

**The cursor is an opaque token** encoding `{ lo, hi, after }`: the batch's lower and upper
snapshots (`pg_snapshot` text) and a `sync_seq` keyset position inside the batch. Clients store
exactly what the server returned as `nextCursor` and send it back; they never construct, parse or
compare one. `api-standards.md` permits opaque cursors. A malformed or forged token is a `400`,
never a `500` — every field is shape-checked before any SQL sees it.

**Query shape.**

```sql
SELECT id, sync_seq FROM <table>
 WHERE <scope>
   AND (sync_txid IS NULL OR pg_visible_in_snapshot(sync_txid::text::xid8, :hi))  -- committed by hi
   AND sync_txid IS NOT NULL                                                      -- only when lo is
   AND NOT pg_visible_in_snapshot(sync_txid::text::xid8, :lo)                     --   set: not by lo
   AND sync_seq > :after                                                          -- within the batch
 ORDER BY sync_seq ASC LIMIT :n + 1
```

then the page's ids are hydrated through the owning modules' existing Prisma queries and mappers.
Paging and the next cursor are computed from the window rows, never the hydrated ones: a row written
again between the two queries hydrates with a newer `syncSeq`, and keying off that would skip the
rows in between. That newer write also lands in the next batch; applying a row twice is idempotent.

**Initial sync** omits `since`: `lo` is empty, so the first batch is everything committed by `hi`.
There is no separate bootstrap path.

**Opening and continuing a batch.** A cursor without `hi` opens the next batch: the collection's
`prepare` runs (the Booking lifecycle sweep, §12), *then* `hi` is taken, so the sweep's writes are
inside the batch. A cursor with `hi` continues its batch and does neither.

**Advancing.** While a batch has more rows, `nextCursor` stays in it after the last row returned.
When it is exhausted, `nextCursor` opens the next batch from this one's `hi`. `nextCursor` is
therefore **always present**, including on an empty page — a client with nothing new still advances
and never re-reads. A retried request with the same cursor returns the same rows (tested).

**Pagination** is bounded, default 20, maximum 100 (`coding-standards.md` §6), fetching `limit + 1`
to compute `hasNext`.

**A page is a consistent prefix, not a whole-database snapshot**: a related row (a Hall's parent
Hotel) may arrive in another collection's batch, so a client tolerates temporary referential
incompleteness and never deletes a row because its parent has not arrived yet.

---

## 8. Resync, Too-Old Cursors, Tombstones and Soft Deletes

**Tombstones.** `hotel_media`, `hall_media` and `hall_availability_blocks` were the only tables
deleting rows outright. They now soft-delete, and every read filters `deletedAt IS NULL` — 13 read
sites. A deletion travels as an ordinary change because the soft delete is an UPDATE, so the
trigger advances `syncSeq` and records its transaction. `hotels` and `halls` already soft-deleted;
a soft-deleted Hall or Hotel arrives as a tombstone too (tested).

**A tombstoned parent takes its children with it, on the client.** The server does not tombstone a
soft-deleted Hall's photos or blocks separately — they become unreachable through it, not deleted —
so the client store deletes rows whose lifted `hall_id`/`hotel_id` points at a tombstoned parent,
in the same transaction as the tombstone.

**The constraint consequence.** `hall_availability_blocks_no_overlap` had no `WHERE` clause. Once
blocks became tombstones it kept enforcing periods of blocks already deleted — measured: create,
delete, re-block the same period → 409 while `hasOverlap` correctly reported it free. It is now
scoped `WHERE (deleted_at IS NULL)`, mirroring `bookings_no_blocking_overlap`'s own status filter.
**Any future soft delete must check for an unscoped constraint on the same table.**

**Retention floor.** Tombstones are purged after a retention window, and the purge records the
newest transaction whose tombstones it removed. A cursor whose lower snapshot does not yet see that
transaction cannot be answered incrementally and
returns a typed `SYNC_CURSOR_EXPIRED` error meaning "discard and resync fully". **It must never be
an empty success** — that is indistinguishable from "nothing changed" and would leave a client
silently wrong forever.

The window length is a business decision (§14). Until it is set, no purge runs and no floor exists,
so no *purge* can expire a cursor yet — which is safe. `SYNC_CURSOR_EXPIRED` (HTTP 409, "conflicts
with the database's current state") is nonetheless reachable today in two cases, both tested:

- **A cursor from another cursor version** — genuinely issued, just not continuable. A 400 there
  would repeat on every run and wedge that collection forever.
- **A cursor ahead of the database.** A point-in-time restore or a Neon branch reset moves the
  transaction counter backwards; a device's snapshot would then count every new write as already
  seen and skip it silently, forever. Any cursor whose snapshot `xmax` exceeds the database's
  current one is therefore refused.

The client discards that collection and resyncs it from nothing (tested); it does the same on a
`400` whose detail is `since`, so no stored cursor can wedge a collection. With snapshot cursors the
future retention floor is a transaction id, not a `syncSeq`.

**`updatedAt` requirements.** Six tables lacked it and now have it, with `@default(now()) @updatedAt`
so the database default covers code that predates the column. `syncSeq` is the sync mechanism;
`updatedAt` exists for display and for conflict resolution (§11), not for change detection.

---

## 9. Hotel → Hall Visibility Changes

**The problem** is §2.2: suspending a Hotel changes no Hall row.

**Rejected:** denormalising eligibility onto `Hall`. It would create a second source of truth for a
rule `architecture-principles.md` §5 requires be computed in exactly one place, and
`visibility.service.js` exists specifically to honour that.

**Adopted:** `lifecycle.service.js#transition` bumps `syncSeq` on the Hotel's `hall_media`,
`hotel_media` and Halls (children first — §4, lock order), so the derived change travels as ordinary
changes. Bounded by one Hotel's Hall count, on an action a Platform Administrator performs rarely.
Inside a transaction the bumps precede the status write; outside one they follow it, because each
statement then commits alone and a sync between them must not see the Halls re-published under the
old status.

**Who applies the visibility rule.** Version 0.1 offered two options and chose the first:

1. Clients apply `computeVisibility` themselves — the rule duplicated on every platform, and the
   public Hotel projection would have to expose `status`.
2. A stored `isVisibleToCustomers` per Hall — a second source of truth for eligibility.

The independent review (§19) rejected both, correctly, and proposed a third, which this document
**adopts** for the public collections (Phase 3):

3. **The server applies the visibility predicate inside the public resolver, and emits every row in
   the batch that is no longer visible as a tombstone** (`deleted`). The fan-out above is what puts
   those rows in the batch at all. Eligibility is still computed in exactly one place
   (`visibility.service.js` through the Eligibility Query Interface), no client implements it, no
   visibility is stored, and `status` never needs to be public. It is also what §16.2 already
   requires: de-visibility as a positive change record.

Version 0.1's option 1 also contradicted §16.2 and §5's own server-side public scope predicate — a
defect of the document, now removed (§20, finding 15).

**Phase 1 is unaffected**: a Manager is the owner, and owner visibility is always true — a Manager
sees their own suspended Hotel's Halls, exactly as the REST endpoints show them.

---

## 10. Media, Notification and Chat Synchronization

**Media.** The database stores `storagePath`, never a URL, and `media.mapper.js` derives a
**public, non-expiring** Supabase URL at read time. Version 0.1 said to sync `storagePath` and derive
the URL on the client. That was wrong for this system: a device does not know the bucket host, and
teaching it would put a provider detail in three client codebases. **Sync rows use each module's own
REST mapper** (`sync.mapper.js`), so a synced Hall or Hotel carries its `photos` (and a Hotel its
`logo`) with server-derived URLs, exactly as the REST endpoints return them — which is also what keeps
the client's existing model parsers correct (a raw row parses into a Hall with no photos and empty
booking terms, silently).

Two consequences, both handled:

- **A photo change must re-publish its parent**, or the embedded list goes stale — the `AFTER`
  trigger in §4.
- **One source of truth per client.** The parent's embedded `photos` is what Manager Mobile renders;
  it does not replicate `hallMedia`/`hotelMedia` at all (§16). Those collections stay registered for
  a client that needs media rows on their own.

If the storage provider's host ever changes, a server-side bump of the affected parents re-publishes
their URLs; there are no signed URLs and so no expiry concern. A missing object is "not yet synced",
never an error: `deleteMedia` removes the Supabase object before the row.

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

**The lifecycle-sweep dependency.** A sync of Bookings must run `advanceLifecycle` for that scope
first — once per *batch*, when the batch opens and before its upper snapshot is taken, never per
page — or clients hold Bookings stuck `PENDING` past `paymentDeadlineAt`. (Version 0.1 said "once
per request", which with one request per page meant up to one sweep per page of a cold start; §20,
finding 17.) The sweep creates `BOOKING_EXPIRED` Notifications, so it must stay
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

**Sync query plans** (`EXPLAIN ANALYZE`, local PostgreSQL 17, 929 Halls / 97,250 Notifications):

| Window query | Plan | Time |
| --- | --- | --- |
| `hall`, one Hotel | Bitmap Index Scan on `idx_halls_hotel_sync_seq` | 0.35 ms |
| `hallMedia`, one Hotel (through `halls`) | index on `halls`, then a seq scan of `hall_media` — the planner's choice at 178 rows | 0.64 ms |
| `notification`, one recipient, with a lower snapshot | Index Scan on `idx_notifications_recipient_sync_seq` | 9.0 ms at 1,045 rows for that recipient |

The lower-snapshot test (`NOT pg_visible_in_snapshot(...)`) cannot use an index, so an incremental
batch scans the caller's whole scope — linear in *one tenant's* rows, not the table's. At Manager
scale that is milliseconds. An index on `(scope, sync_txid)` would bound it and is recorded here for
Phase 2/3, where a Customer's Notification history may grow, rather than added speculatively.

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

**Applied (Phase 1 correction, 2 migrations), to the Neon test database and local PostgreSQL 17:**

- `20260928100000_sync_seq_bump_media_parent` — the media→parent `AFTER` triggers (§4, §10).
- `20260928110000_sync_snapshot_windows` — `sync_txid` on all 13 tables with its default,
  `sync_seq_bump()` extended to set it, and `sync_seq SET NOT NULL`. The `NOT NULL` step checks
  every table for NULLs first and refuses with a named table rather than failing half-way; there
  were none. No backfill: a NULL `sync_txid` means "written before the column existed" and is
  treated as visible in every snapshot.

Verified after applying, on the objects rather than the log: 13 `sync_txid` columns, 13 `NOT NULL`
`sync_seq` columns, 4 parent triggers, the new `sync_seq_bump()` body, and unchanged row counts.

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
response changed. Phase 1 adds a route and changes no existing one. The Phase 1 correction changed
the sync cursor's format from a decimal to an opaque token; no deployed client had consumed the
endpoint, so there was nothing to stay compatible with. A deployed app that knows nothing about any
of it continues to work — which was demonstrated, not assumed: the deployed application kept serving
throughout.

---

## 16. Client Requirements

Stated as a contract so any local database can be evaluated against it. **RxDB is not assumed** —
it is a JavaScript library with no Dart implementation, so it could serve Admin Web but neither
Flutter app. A single protocol across all three clients must therefore be plain HTTP + JSON that
each platform's own storage layer consumes.

1. A resumable change token per collection that no commit order can skip — an opaque snapshot
   window (§4), never a timestamp or a bare sequence.
2. Deletions and de-visibility expressed as **positive change records** — absence is not detectable.
3. Stable, client-generatable row identity — UUID v4 primary keys already satisfy this.
4. A scope identity in every response, so a permission change forces a wipe.
5. Bounded pages with a resumable cursor.
6. A typed too-old-cursor error, never an empty success.
7. Clients never build sync state from a clock — theirs or the server's; `serverTime` is
   informational.
8. Idempotency keys on every queued mutation.
9. Commands separate from sync, with typed rejections preserved.
10. The same `SuccessEnvelope`/`ErrorEnvelope` as today (`api-standards.md` §7–§8) — sync does not
    invent a second envelope.
11. **The replica is wiped when the session ends** — sign-out, expiry, or a different user signing
    in — not merely on the next `scopeId` mismatch. The replica is unencrypted (ADR-0009), and a
    second person on the same device must never read the first one's data. A device that merely
    *started offline* keeps its replica: its session is intact, only unreachable.

### Manager Mobile (Phase 1) — implemented

- `SyncDatabase` / `SyncStore` — SQLite via `sqflite` (ADR-0009): one table keyed by
  `(collection, id)` with `hotel_id`/`hall_id` lifted into indexed columns; each page applied in
  one transaction together with its cursor; a tombstoned parent removes its children.
- `SyncEngine` — read-only puller. Stores the server's cursor verbatim. Restarts **every**
  collection after a scope wipe (not just the one that noticed), resets a collection on
  `SYNC_CURSOR_EXPIRED`, stops on a cursor that fails to advance, and lets concurrent callers share
  one run.
- `LocalReplica` — app-wide: opens the database (and degrades to "unavailable" if it cannot),
  syncs on sign-in and on returning to the foreground, and wipes per item 11. Three rules, each from
  a defect found in review (§20, findings 21–23):
  - **One queue** for every sync, wipe and ownership check, so a wipe never lands between two pages
    of a sync.
  - **`sync()` starts after it is called** — it joins a queued run, never one already under way,
    whose snapshot could predate the command the caller just sent.
  - **The owner is persisted with the rows** (`sync_owner`). Until the signed-in user is confirmed
    as the owner, or the replica is wiped for them, nothing reads it — so a restart, an offline
    start, or a failed first sync cannot expose one Manager's rows to another.
- **What reads locally: the Hall list** — list, name search, Active/Inactive filter and chip counts,
  ordered as the server orders them (`createdAt` desc). It syncs only `hall`: a synced Hall carries
  its photos, and a collection is replicated when a screen reads it, never speculatively (§13). Until
  the replica has synced, the list reads the network exactly as before. Commands (activate, create,
  edit) remain server calls; the list re-reads after a forced sync. Offline, the synced list stays on
  screen with a notice, and commands fail visibly rather than pretending.
- **Next candidates**, each an ordinary engineering change against this same contract:
  Notifications (the unread badge becomes a local `COUNT`, §10) and the Calendar's Bookings. Booking
  contact details stay network-only until business decision #3.

---

## 17. API Design

One route, an explicit collection allowlist, one scope predicate each.

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
| Request | `collection` from a fixed allowlist; `since` = an opaque cursor from a previous response (omit for initial); `limit` (1–100, default 20); a working-set parameter for geographic collections (Phase 3) |
| Response | `data: { changed: [rows], deleted: [ids], scopeId, serverTime }` and `pagination: { limit, hasNext, nextCursor }` in the existing `SuccessEnvelope`. Rows use the owning module's REST shape plus `syncSeq` |
| Pagination | snapshot window + `sync_seq` keyset within it (§7). `nextCursor` is always present |
| Failure | existing `ErrorEnvelope`. Malformed/forged cursor (including anything `pg_snapshot_in` would reject), unknown collection or bad limit → 400 before any query runs. Expired/invalid token → 401. Wrong account type → 403. `SYNC_CURSOR_EXPIRED` → 409 for a cursor that cannot be continued (§8) |
| Consistency | read committed. Correctness comes from snapshot visibility, not from the isolation level or from sequence order |

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

**Concurrency:** a transaction that draws its `sync_seq` first and commits last must still be
delivered — the test holds one open across a sync.

**Status (2026-09-28).** Backend: 40 sync integration tests covering every item above, including
the commit-order test, an expired token on every collection, forged cursors, a retried page,
two-device read-state convergence, a tenant-isolation test that seeds a foreign row in *every*
collection and checks every id (tombstones included), Hall tombstones, and the media→parent
triggers (insert, delete through the real service, no cascade from a bare `sync_seq` bump, cascading
hard delete). Full backend suite 542/542 on PostgreSQL 17; sync suite also run against the Neon test
database. Manager Mobile: engine, store, replica, local Hall repository and local-first Hall list
tests against a real SQLite (`sqflite_common_ffi`); full app suite 263/263. `EXPLAIN`: §13.

---

## 19. Review Record

| Date | Reviewer | Scope | Outcome |
| --- | --- | --- | --- |
| 2026-09-27 | author (self) | §§1–18 | seven findings, §20 items 1–7 |
| 2026-09-28 | independent model reviewer — a separate agent given the repository and this document, with no authorship context, instructed to verify claims against the code | this document, the sync module, its migrations and tests, the Manager Mobile sync foundations, ADR-0009 | 3 blockers, 5 major, 4 minor. All resolved; §20 items 8–19 |
| 2026-09-28 | second independent model reviewer, same terms, on the final code | sync module, migrations, lifecycle fan-out, Manager Mobile sync, replica and Hall list, their tests | no blocker; the snapshot-window logic, SQL binding and lock-order claim confirmed by inspection. 4 major, 5 minor — §20 items 21–27, all resolved or recorded |
| pending | Mohamed or Abukar | whole document, against `review-checklists.md` | required by `documentation-architecture.md` §4 before `Approved` |

`docs/07-validation-and-qa/review-checklists.md` is still a placeholder, so the 2026-09-28 review
used `architecture-principles.md`, `data-architecture.md`, `coding-standards.md`,
`api-standards.md` and the Business Decision Register instead.

The model review is recorded as what it is. It reached its conclusions from the code rather than
from the author's reasoning, and it disagreed with the author on §9 and prevailed — but it is not a
member of the team, and it does not satisfy §4.

---

## 20. Review Findings

Every finding, from the author's own adversarial pass and from the independent review, recorded
rather than silently fixed.

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

**Found by the independent review of 2026-09-28 (§19), all resolved:**

8. **Blocker — `sync_seq` is not commit-ordered** (§4 guarantee 4 of version 0.1 was false). A
   transaction holding a lower number could commit after a client had advanced past it; that row
   was then never delivered. The author also reproduced it on PostgreSQL 17. Replaced by snapshot
   windows (§4, §7), with a test that holds a transaction open across a sync. The reviewer proposed
   an "oldest running transaction" horizon instead; it was not adopted because a single
   idle-in-transaction session would stall every client's sync, whereas a snapshot window delays
   only the late transaction's own rows.
9. **Blocker (governance) — review status.** Client work had begun before any independent review.
   Recorded in §19; human review remains outstanding.
10. **Blocker — §9 contradicted §16.2 and §5.** Resolved by adopting server-side de-visibility
    tombstones (§9 option 3).
11. **Major — §10 described URL derivation the implementation no longer did.** Rewritten.
12. **Major — the media→parent triggers were undocumented.** Documented in §4, §10, §15.
13. **Major — lock-order deadlock** between a Hotel status change (parents, then children) and a
    photo delete (child, then parent via trigger). `touchSyncDependents` now bumps children first in
    separate statements, and `transition` runs it before the status write inside a transaction.
14. **Major — the tenant-isolation test was partly vacuous.** Mapped media and block rows carry only
    `hallId`, so comparing `hotelId` could not catch their leak, and no foreign Booking or
    Application existed to leak. It now seeds every collection and checks every id.
15. **Major — the device kept one Manager's data after sign-out**, and the engine left collections
    synced earlier in a run empty after a mid-run wipe. §16 item 11; the engine restarts the run.
16. **Minor — misclassified data** (§5). Contact details are Confidential; the conclusion stands.
17. **Minor — "once per request" sweep ran once per page.** Now once per batch.
18. **Minor — `sync_seq` was nullable**; a NULL row would have produced an unusable cursor. `NOT
    NULL` now, after checking every table.
19. **Minor — loose ends:** a soft-deleted Hall's children stayed in the replica (client cascade,
    §8); photos arrived both embedded and as `hallMedia` (one source named, §10); the local Hall
    list ordered by `sync_seq`, jumping an edited Hall to the top (now `createdAt`, as the server).
    The reviewer also noted `toBooking` emits `review: null` under sync because the review relation
    is not loaded — accepted and recorded: no client reads Bookings from the replica yet, and the
    Booking collection's shape must be revisited when one does.

**Found during client implementation:**

20. **A background re-read could make the Manager's own load look superseded.** The Hall list's
    replica listener took a new request generation, so a `load()` in flight returned with nothing
    rendered. The listener now yields to a load rather than superseding it. Found by test.

**Found by the second independent review (code, 2026-09-28), resolved:**

21. **Major — a command's own sync could join an older run.** `sync()` returned a run already under
    way, whose snapshot predated the command; the toggle appeared to revert, and the freshness
    window then suppressed the correction for 30 s. `sync()` now joins only a queued run. Test: a
    command sent while a gated sync is in flight.
22. **Major — a wipe could land between two pages of a sync**, after which the engine stored an
    advanced cursor over deleted rows: a permanent hole behind `hasSynced = true`. One queue now
    orders every sync and wipe. Test: a wipe requested while page 2 is pending.
23. **Major — the replica's owner lived only in memory.** After a restart or an offline start,
    another Manager signing in could read the previous one's rows until a sync noticed the scope —
    indefinitely if it never succeeded. The owner is persisted and checked before anything reads.
    Test: a new process, a second user, the network down.
24. **Major — a restored or branched database would silently skip every new write** for a device
    holding a cursor from before the rewind. Such cursors are now `SYNC_CURSOR_EXPIRED`; so is a
    cursor of another version, which was a 400 that would have wedged the collection.
25. **Minor — shape-valid snapshots that `pg_snapshot_in` rejects** (`xmin > xmax`, out-of-range or
    unsorted in-progress ids, beyond 64 bits, an `after` beyond int8) reached SQL as 500s. Now 400s;
    each has a test.
26. **Minor — `sync()` could throw** on a local database error despite promising not to; the list
    kept a wiped replica's rows on screen; and a sync failing for a reason other than connectivity
    showed stale rows with no notice. All three fixed.
27. **Minor — test gaps.** Rows with a NULL `sync_txid` across a later batch: now tested. The lock
    order (finding 13): verified by the reviewer across every `$transaction` and advisory lock in the
    codebase, but not tested — a deadlock needs an interleaving inside a single statement that a test
    cannot force deterministically. Recorded rather than papered over with a test that could not fail.

**Accepted risks, not defects:**

- **Outside a transaction, a Hotel status change and its dependents' bumps are separate commits.**
  A crash between them leaves some Halls not re-published until their next write. Every current
  caller that changes eligibility on a Customer-visible path is either an administrator action that
  can be repeated or already inside a transaction; recorded, not engineered around.

- **Starting the app offline shows the sign-in screen**, because `AuthController.restoreSession`
  treats an unreachable server as signed out (while keeping the stored session). The replica
  survives it, so local-first helps from the moment a signed-in session loses connectivity, not on
  an offline cold start. Changing that is an Authentication behaviour change, outside this document.

- §13's working-set strategy means a Customer's local replica is a partial marketplace. Local
  *search* over it would amend `BDR-020` and is out of scope (§14 #1), but any locally-rendered
  list is still partial by construction. Phase 3 must surface data age (§14 #2).
- §12's lifecycle-sweep coupling means a sync request performs writes. Unavoidable without changing
  `advanceLifecycle`, which is a Booking Management decision, not this document's.

**The open question put to the independent reviewer** — §9 option 1 vs option 2 — was answered
with a third option, which this document adopted (finding 10).
