# ADR-0009: Client-Side Local Database for Local-First Synchronization

- Status: Proposed
- Date: 2026-09-27
- Decision owner: Ahmed

## Context

The Local-First Synchronization Technical Design introduces a backend that serves incremental
changes (`GET /api/v1/sync/:collection`, implemented, Manager scope). Consuming it requires a
client-side store: today the Flutter apps hold nothing between screens — each controller fetches on
construction and loses its data on dispose — and `technology-stack.md` names no client database.
The only client persistence approved so far is `flutter_secure_storage`, for tokens.

Manager Mobile is the first consumer (Technical Design §13: a Manager's working set is one Hotel,
which is bounded, unlike a Customer's view of the marketplace).

The store must hold eight collections of relational rows, apply upserts and tombstones keyed by
`id`, query by scope (`hotelId`, `hallId`, `recipientUserId`), and persist one cursor per
collection plus the `scopeId` those cursors were fetched under. Three client platforms exist, so the
choice must not assume a JavaScript runtime — `RxDB`, named in early discussion, has no Dart
implementation and is therefore not a candidate for either Flutter app.

## Decision

**`sqflite` (SQLite) for both Flutter apps, with hand-written SQL confined to a repository layer.**

Rejected alternatives:

- **`drift`** — typed queries, migrations and reactive streams, which suit replacing the current
  fetch-on-build controllers. Rejected because it requires `build_runner` codegen, and neither
  Flutter app has any codegen today. Adding a code-generation step to the toolchain is a larger
  change than the problem warrants (`Project-Constitution.md` §3, Simplicity Over Complexity), and
  it can be adopted later over the same SQLite files if typed queries become the constraint.
- **`Isar`** — fast, but a NoSQL model for data that is relational, and its maintenance position has
  been unsettled. A dependency this central should not carry that risk.
- **`Hive`** — key-value only. Queries like "the Halls of this Hotel, newest first" would be
  implemented by loading and filtering in Dart, which is the pattern `BDR-020` already rejected
  server-side and which local-first is meant to avoid, not relocate.
- **Serialized JSON files** — no query capability, whole-file rewrites on every sync page, and no
  atomicity across a multi-page sync.

SQLite is also the closest structural match to the backend: rows with ids, queries by scope, and a
repository as the only place a query is written (`coding-standards.md` §5). The same rule applies
client-side, so the local store is a repository, not a store scattered across controllers.

Testing uses `sqflite_common_ffi`, which supplies a platform implementation under `flutter test` —
the same reason `LocationService` is injectable, since geolocator has none.

## Consequences

- One new runtime dependency per Flutter app (`sqflite`) and one dev dependency
  (`sqflite_common_ffi`). No codegen, no build step, no change to how either app is built.
- Local schema becomes a versioned migration concern on the client, independent of Prisma's. A
  schema change ships with an app release, so the store must tolerate being dropped and resynced —
  which is already required for a `scopeId` change or an over-old cursor (Technical Design §8).
- Replicated rows are stored unencrypted. `sqflite` provides no at-rest encryption, and this is why
  the Booking projection excludes `mobileNumber` (Restricted, `data-architecture.md` §13) rather
  than relying on device storage being private. Any future decision to replicate Restricted data
  would need encryption addressed first, and is a business decision (Technical Design §14 #3).
- Reads stop being network-bound; writes are unaffected. Every command keeps its existing endpoint
  and the database stays authoritative (Technical Design §12).
- Existing authentication, booking, lifecycle, visibility, payment and availability behavior are
  unchanged. This ADR adds a cache, not a rule.
- **The replica is wiped when the session ends** (sign-out, expiry, or a different user signing in),
  not only on a `scopeId` mismatch — unencrypted data must not outlive the session it belongs to.
  A device that merely started offline keeps it (Technical Design §16, item 11).
- A collection is replicated only once something reads it. Manager Mobile replicates `hotel`,
  `hall`, `hotelApplication`, `booking`, `notification` and `chatMessage` (Technical Design §16).
  Schema version 3 adds a lifted `booking_id` column and a small `sync_cache` table for the last
  response of a server aggregate; like everything else, it belongs to the owner and is wiped with
  the replica.
- If `sqflite` cannot open on a platform, the replica reports itself unavailable and every reader
  falls back to the network path it used before. Local-first is an optimisation of reads, never a
  precondition for the app to work.

## Implementation Status

Implemented in Manager Mobile on 2026-09-28 (`lib/core/sync/`, `LocalHallRepository`,
`HallListController`), tested against a real SQLite through `sqflite_common_ffi`. The status stays
**Proposed** until the decision owner accepts it alongside the Technical Design's human review
(`documentation-architecture.md` §4).
