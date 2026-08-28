---
title: "ADR-0006: Hotel Media Storage Provider (Supabase)"
document_type: Architecture Decision Record
status: Approved
last_updated: 2026-08-26
---

# ADR-0006: Hotel Media Storage Provider (Supabase)

**Status:** Approved
**Date:** 2026-08-26
**Owner:** Ahmed (per `Decision-Making-Principles.md` §4, every ADR is approved by Ahmed)

## Context

`BDR-015` (Required Hotel Business-Profile Content, `Approved` 2026-08-26) approves Hotel
Logo and Hotel Photos as optional Hotel profile fields (Hotel Management Business
Specification §7 `BR-HOTEL-02`). Building the actual upload path requires a concrete
storage provider — `ADR-0001` established a **provider-agnostic storage abstraction** with
**Cloudinary as its default provider**, but nothing in the codebase has actually implemented
that abstraction yet (`backend/src/` has no storage/media module of any kind — confirmed
while preparing Hotel Management's Manager Mobile profile screen). Hotel media is therefore
the *first* real consumer of the storage abstraction, not a change to an already-built
integration.

A separate request specified **Supabase** for Hotel media, conflicting with `ADR-0001`'s
Cloudinary default. That conflict was surfaced and left unresolved in Hotel Management
Technical Design v1.6 §17 pending this decision. This ADR resolves it. It meets the
`Decision-Making-Principles.md` §7 bar because it changes `technology-stack.md` and
`system-architecture-overview.md` (both `docs/02-architecture/*`).

## Options Considered

Evaluated against `Decision-Making-Principles.md` §6. Both options sit behind the same
provider-agnostic abstraction `Architecture-Principles.md` §10–§11 already requires — the
choice is which concrete implementation of that abstraction ships first, not whether the
abstraction exists.

1. **Status quo — Cloudinary** (`ADR-0001`'s existing default). Purpose-built media CDN/
   transformation service; would be a net-new integration and net-new credential set, since
   nothing currently consumes it.
   - *Business Value:* Equivalent to Option 2 for this use case — either unblocks Hotel Logo/
     Photo upload.
   - *Complexity/Developer Experience:* A second external account/credential set alongside
     Supabase, which is otherwise not used anywhere in this stack.
   - *Cost:* Usage-based; comparable shape to Option 2 for MVP-scale media volume.
   - *Risk:* None specific — mature, widely-used provider.

2. **Supabase Storage.** Object storage bucket product, part of the Supabase platform.
   - *Business Value:* Directly enables Hotel Logo/Photo upload (`BDR-015`).
   - *Security:* Access control via Row Level Security policies on the storage bucket,
     enforced server-side, the same authorization model already governing this project's
     Postgres data; credentials handled per `naming-conventions.md` §10 like any other
     secret. The **anon/public key** is safe for client-side use by Supabase's own design
     (RLS is the actual gate, not key secrecy) — the **service-role key**, which bypasses
     RLS, is never shipped to the Flutter apps, consistent with this decision's own
     constraint against exposing privileged credentials client-side.
   - *Maintainability:* One fewer external account/vendor relationship for a three-person
     team to manage if the project's Postgres hosting or auth ever also considers Supabase —
     not assumed or decided here, just a lower-friction adjacent surface.
   - *Scalability:* Usage-based; adequate for MVP-scale Hotel media volume.
   - *Performance:* Adequate for profile-image-scale assets (not a video/streaming use case).
   - *Complexity:* Low — a single new provider integration behind the existing abstraction,
     no different in shape from Option 1.
   - *Cost:* Usage-based, comparable to Option 1.
   - *Risk:* Low — a widely-used, well-documented provider.
   - *Developer Experience:* Straightforward SDK; comparable to Option 1.
   - *Future Growth:* Same provider could later host other modules' media (Hall Photos,
     Event media) if their own Business Specifications ever require it — not scoped or
     assumed here.

## Decision

**Approved — Option 2 (Supabase Storage).** Supabase is the approved storage provider
realizing the provider-agnostic storage abstraction `ADR-0001`/`Architecture-Principles.md`
§10 already requires, scoped initially to Hotel Logo and Hotel Photos (`BDR-015`,
`BR-HOTEL-02`). This supersedes Cloudinary as the *default* named in `ADR-0001` — Cloudinary
was never actually implemented against, so this is a clean replacement, not a migration.
Decided by Ahmed, 2026-08-26, per `Decision-Making-Principles.md` §4.

The **specific upload mechanism** (bucket/path layout, whether Flutter uploads directly to
Supabase under an RLS-scoped anon key or the backend mediates every upload, presigned-URL
vs. direct-upload flow) is **not decided by this ADR** — that is Technical Design-level detail
for Hotel Management's own document to specify before implementation begins, consistent with
this ADR only fixing the *provider*, the same relationship `ADR-0005` has to Authentication &
Account Management's Technical Design for Twilio.

## Consequences

- `technology-stack.md` §"Storage Provider Abstraction" and its stack-summary row are updated:
  Supabase replaces Cloudinary as the named default provider.
- `system-architecture-overview.md` §8 (External Integrations) and its two diagrams are
  updated: Supabase replaces Cloudinary.
- `Architecture-Principles.md` §10's illustrative example is updated to name Supabase as the
  current default, Cloudinary as a hypothetical future swap (the two examples trade places).
- `ADR-0001` is **not edited** — its original Decision text is left intact per this project's
  own rule against silently rewriting an `Approved` decision (`business-decision-register.md`
  §6, applied here to ADRs by the same governance discipline); it instead gains an `Update`
  section pointing to this ADR, the same pattern `ADR-0001` already uses for its own prior
  resolved question.
- Hotel Management Technical Design (§17) is updated: the Cloudinary-vs-Supabase conflict it
  flagged as open is now resolved — Supabase is the provider once upload implementation
  begins.
- **Still open, not resolved here:** the actual upload mechanism (bucket structure,
  client-vs-backend-mediated upload, credential/RLS design) — required before
  `HotelProfileFormScreen`'s Logo/Photo placeholders can become functional. Tracked as a
  follow-up Technical Design task, not invented in this ADR.
- No BDR is affected — this is a technical/integration decision, not a business one, the same
  distinction `ADR-0005`'s own Related section draws.

## Related

- Amends: `docs/02-architecture/technology-stack.md`,
  `docs/02-architecture/system-architecture-overview.md`,
  `docs/02-architecture/architecture-principles.md`
- Supersedes (partially): `ADR-0001`'s storage-provider default (Cloudinary → Supabase); the
  rest of `ADR-0001`'s stack decision is unaffected.
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR(s): `BDR-015` (Required Hotel Business-Profile Content — the business
  requirement this ADR's provider choice realizes)
- Unblocks: `docs/05-technical-design/modules/03-hotel-management/technical-design.md` §17
  (resolved); actual Flutter/backend upload implementation (still requires its own Technical
  Design addendum for the upload mechanism, per Consequences above).

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-26 | Ahmed | Initial `Approved` ADR — Ahmed directed Supabase directly, resolving the conflict Hotel Management Technical Design v1.6 §17 had flagged as open. Per `Decision-Making-Principles.md` §4, architecture decisions are Ahmed's to both propose and approve; the Options Considered analysis is still recorded in full, per the same section's "still requires the full ADR process." |
