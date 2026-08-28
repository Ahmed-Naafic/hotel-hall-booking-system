---
title: "ADR-0007: Shared Media Infrastructure (Hotel + Hall)"
document_type: Architecture Decision Record
status: Proposed
last_updated: 2026-08-28
---

# ADR-0007: Shared Media Infrastructure (Hotel + Hall)

**Status:** Proposed — Approved in principle by Ahmed's architectural review 2026-08-28;
required corrections applied below; **not yet formally `Approved`** (re-presented for
sign-off, not self-approved, per that review's own explicit instruction).
**Date:** —  (not yet approved)
**Owner:** Ahmed (per `Decision-Making-Principles.md` §4, every ADR is approved by Ahmed)

## Context

`ADR-0006` (Approved, 2026-08-26) chose Supabase Storage as the platform's storage provider,
but scoped its Decision explicitly and narrowly: "**scoped initially to Hotel Logo and Hotel
Photos** (`BDR-015`, `BR-HOTEL-02`)." Its own Consequences section is explicit that extending
Supabase to any other module's media is "not scoped or assumed here." Hotel Management's own
Media Component (Technical Design §8a) was subsequently built and migrated against the real
development database (`hotel_media` table, `backend/prisma/migrations/20260826122039_hotel_media_management/`)
strictly as a **Hotel-only** module (`backend/src/modules/hotels/media.*`) — no shared media
code exists yet.

`BDR-016` (Approved, 2026-08-26) separately approved Hall Photos as an optional Hall
business-profile field, but its own Risks section is explicit that this "does NOT approve a
storage mechanism (no Hall equivalent of `ADR-0006`)." Hall Management Technical Design §8
correspondingly left Hall Photos with "no upload mechanism yet," flagging "a future Hall Media
Component, mirroring Hotel Management's Media Component" as the anticipated follow-up — i.e.
a **second, separate** module-owned media implementation was the design direction on record
until this ADR.

Ahmed has since directed a different course: **one unified media architecture for both Hotel
and Hall**, designed before either module's media implementation is finalized, rather than two
independently-built, mirrored implementations. This is squarely an ADR-level decision under
`Decision-Making-Principles.md` §7's own test — *"if two different engineers implementing two
different modules would each have to independently guess the same answer, it needed an ADR"* —
because without this decision, Hotel Management and Hall Management would each have to guess,
independently, at: which bucket, what shared code (if any) versus per-module duplication, one
metadata table or two, and where the module boundary between "shared media infrastructure" and
each module's own business ownership sits. It also amends `architecture-principles.md` §10
(Storage Principles) by introducing the platform's first genuinely shared infrastructure
component with two real consumers, and effectively supersedes `ADR-0006`'s own narrow "Hotel
only" scoping.

The full design this ADR authorizes is worked out in
`docs/02-architecture/shared-media-technical-design.md` (Draft, prepared alongside this ADR).
This ADR fixes the decisions that meet the `02-architecture/*` bar; the Technical Design
carries every mechanical/implementation-level detail `ADR-0006` itself already established
belongs at that layer, not in an ADR.

## Options Considered

Evaluated against `Decision-Making-Principles.md` §6.

1. **Status quo — two independent, module-owned media implementations.** Hotel Management
   keeps its already-built `hotels/media.*`; Hall Management builds its own separate,
   independently-designed `halls/media.*` mirroring it (the direction Hall Management
   Technical Design §8 was already anticipating).
   - *Business Value:* Equivalent outcome for end users — both entities get photo upload.
   - *Maintainability:* Two parallel implementations of the identical mechanics (magic-byte
     validation, multipart handling, upload-then-persist-with-cleanup-on-failure, storage path
     conventions) that must be kept in sync by hand as either evolves — the exact duplication
     `folder-structure.md` §5's "two or more genuine consumers → shared/" rule exists to avoid.
   - *Complexity:* Lower short-term (nothing to change about what already exists for Hotel),
     higher long-term (two codepaths to reason about, test, and fix).
   - *Risk:* Drift — a fix or hardening applied to one module's copy (e.g. a validation
     tightening) has no mechanism forcing the other module's independent copy to receive it.

2. **One shared Media Infrastructure component, two module-owned metadata tables.** A shared
   `backend/src/shared/media/` component owns storage operations, file validation, upload
   mechanics, deletion mechanics, and orphan cleanup, called by a thin per-module service in
   each of Hotel Management and Hall Management, which alone own the entity relationship,
   business rules, and authorization for their own media (per this ADR's Decision, below).
   Two Prisma models (`HotelMedia`, already migrated; new `HallMedia`) sharing one metadata
   *shape* and one shared `MediaType` enum, each with its own real foreign key — not one
   polymorphic table (`database-standards.md` §5, §10 require a real, database-enforced
   foreign key for every relationship; a single table with an `entityType`/`entityId` pair
   cannot carry a real foreign key to two different parent tables, and would be exactly the
   kind of "soft, application-only reference" §5 already prohibits).
   - *Business Value:* Equivalent to Option 1.
   - *Maintainability:* One implementation of the shared mechanics; a fix applies to both
     entities automatically. Each module still owns its own business rules independently —
     Hotel Management's later change to Logo-replacement semantics, for example, never
     requires touching Hall Management's code.
   - *Complexity:* A genuine new shared component (first of its kind at this scale in the
     codebase), but it follows an already-established pattern (`shared/providers/storageProvider.js`
     already exists and requires no change to support this — it already takes an arbitrary
     `path`, so a second module using it is not a new abstraction, just a second caller).
   - *Risk:* Low — the shared component is small (upload/validate/delete primitives), and each
     module's own authorization stays independently enforced, so a defect in the shared layer
     cannot itself grant cross-tenant access (that check happens before the shared layer is
     ever called, in each module's own service).
   - *Migration cost:* Low — no real Supabase project is configured yet in this environment
     (`SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` are both unset; `MockStorageProvider` is
     active), and the existing `hotel_media` table's shape is preserved as-is (only its `type`
     column's enum is renamed from `hotel_media_type` to a shared `media_type` — a pure rename,
     no data change, no application-visible effect).

3. **One shared, polymorphic `Media` table** (`entityType` + `entityId`, per the conceptual
   sketch Ahmed's own instruction offered as a starting point, explicitly flagged there as
   "do not blindly implement"). Rejected — `database-standards.md` §5 ("referential integrity
   is always enforced at the database level... there is no 'soft,' application-only reference
   between tables") and §10 ("Many-to-Many... never via a JSON/array column pretending to hold
   a relationship... this is what keeps referential integrity enforced by the database rather
   than by application-level convention") both directly rule this out. A polymorphic
   `entityId` cannot be a real foreign key to two different parent tables simultaneously; every
   query needing the parent's own columns (e.g. "this Hotel's media, joined to the Hotel's own
   status") would need an application-level `entityType` branch Prisma cannot type-check or
   enforce. Option 2 achieves the same practical "one shared model" outcome the instruction
   was actually after — one shared conceptual shape, one shared enum, one shared service
   contract — without giving up database-enforced integrity.

## Decision

**Proposed — Option 2.** One shared Media Infrastructure component
(`backend/src/shared/media/`) owns storage operations, file validation, upload mechanics,
deletion mechanics, orphan cleanup, and the common media error vocabulary, for both Hotel and
Hall media. Hotel Management continues to own the Hotel↔Media relationship, Hotel media
business rules (at most one active Logo; unlimited Photos), and Hotel ownership authorization.
Hall Management owns the Hall↔Media relationship, Hall media business rules (Photos only, no
Logo — `BDR-016` never introduced a Hall Logo field), and the two-step Hall ownership
authorization (Manager owns the Hotel, and the Hall belongs to that Hotel).

Supabase (`ADR-0006`) remains the storage provider, now explicitly scoped to **both** Hotel and
Hall media, realizing `ADR-0006`'s own "Future Growth" note ("Same provider could later host
other modules' media (Hall Photos...) if their own Business Specifications ever require it") —
`BDR-016` has since made that condition true for Hall Photos specifically. **The existing
`hotel-media` bucket is retained, not renamed** — per Ahmed's review correction, a bucket rename
is out of scope for this development phase unless the real environment actually requires it, and
nothing about it does (no real Supabase project is configured yet, §2 of the Consequences
below). One bucket, not two, holds both entities' objects under distinct, already
platform-neutral path prefixes (`hotels/{hotelId}/...`, `halls/{hallId}/...}`) — the bucket's own
*name* stays a historical artifact of when it was Hotel-only; nothing about bucket-level policy
differs between the two entities regardless (both Public-classified, both
public-read/service-role-write), so the name mismatch has no functional consequence. Backend-mediated upload
(`architecture-principles.md` §10-11, already `ADR-0006`'s own unstated-but-implemented
assumption) is restated explicitly for Hall: Flutter never talks to Supabase directly for
either entity, and the Supabase **service-role** credential never leaves the backend process.

The full mechanical design — storage paths, the `HallMedia` Prisma model, the shared
`media_type` enum rename, API endpoints, authorization sequencing, upload/delete/replace
sequence diagrams, validation, orphan-cleanup behavior, and every other Technical-Design-level
detail `ADR-0006` itself deliberately left to a Technical Design — is specified in
`docs/02-architecture/shared-media-technical-design.md`.

**This ADR is not yet approved.** Per this turn's explicit instruction, it is prepared for
Ahmed's review rather than self-approved — the same governance gate `Decision-Making-Principles.md`
§7 requires for every ADR, applied here without shortcutting it despite Ahmed having already
directed the high-level architectural direction this ADR formalizes.

## Consequences

- `technology-stack.md` / `system-architecture-overview.md` §8 (External Integrations): Supabase's
  documented scope is widened from "Hotel Logo/Photos" to "platform media (Hotel, Hall)," once
  approved.
- `architecture-principles.md` §10 (Storage Principles) gains its first concrete example of a
  genuinely shared infrastructure component with two real module consumers — no change to the
  principle itself, which already anticipated exactly this shape.
- `ADR-0006` is **not edited** (same append-only discipline it already applied to `ADR-0001`) —
  it gains an `Update` note pointing here, the moment this ADR is approved.
- A new Prisma migration is required (not created by this ADR — Technical-Design/implementation
  work, out of scope for this "design first" turn): adds `hall_media`, renames the
  `hotel_media_type` enum to `media_type`. No existing data is altered.
- Hotel Management Technical Design §8a is superseded in part — its mechanics move to the new
  shared Technical Design; its own document keeps only what §8a's own content already
  correctly scoped as Hotel-specific (the Hotel↔Media relationship, at-most-one-Logo rule,
  own-Hotel authorization). Not edited by this ADR — flagged as a follow-up edit for Ahmed's
  review, consistent with "no architecture document is ever silently edited... the ADR comes
  first."
- Hall Management Technical Design gains a real Media Management section (resolving its own
  previously-deferred placeholder at §8) once this ADR and the shared Technical Design are
  approved — also not edited by this ADR itself, same reason.
- **Still open, not resolved here** (recorded as Pending Business Decisions in the shared
  Technical Design, not invented): the maximum file size / supported format list as a settled
  business limit (Hotel's existing 5 MB / JPEG-PNG-WebP default was always flagged as a
  technical default, never a business decision — this ADR does not change that); whether
  Manager Mobile ever exposes photo reordering to a Hotel Manager (the `displayOrder` column
  is structurally provisioned, its editability is not decided here).
- No BDR is affected — `BDR-015` and `BDR-016` already approved the *business* fields (Hotel
  Logo/Photos, Hall Photos); this ADR is purely the technical/integration decision realizing
  both, the same distinction `ADR-0006`'s own Related section already draws.

## Related

- Amends (pending approval): `docs/02-architecture/technology-stack.md`,
  `docs/02-architecture/system-architecture-overview.md`,
  `docs/02-architecture/architecture-principles.md`
- Extends: `ADR-0006` (Hotel Media Storage Provider) — widens its scope from Hotel-only to
  Hotel + Hall; does not change its Decision (Supabase remains the provider).
- Introduces: `docs/02-architecture/shared-media-technical-design.md` (Draft — the full
  mechanical design this ADR authorizes).
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR(s): `BDR-015` (Hotel Logo/Photos), `BDR-016` (Hall Photos) — the business
  requirements this ADR's shared provider/architecture choice realizes for both.
- Supersedes (partially, pending approval): Hotel Management Technical Design §8a's mechanics
  (relocated to the shared Technical Design; Hotel-specific content stays); Hall Management
  Technical Design §8's "future Hall Media Component, mirroring Hotel Management's" direction
  (replaced by the shared-component direction this ADR establishes).

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-27 | Ahmed (directed) / prepared by AI assistant per explicit instruction | Initial `Proposed` ADR — prepared for review, not self-approved, per this turn's explicit governance instruction. |
| 1.1 | 2026-08-28 | Prepared by AI assistant, per Ahmed's architectural review ("Approved with required corrections") | Removed the `hotel-media` → `media` bucket rename from the Decision — the existing bucket is retained; only the already-platform-neutral path prefixes distinguish Hotel from Hall media. Still `Proposed`, re-presented for final sign-off, not self-approved. |
