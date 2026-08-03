---
title: "ADR-0001: Initial Technology Stack"
document_type: Architecture Decision Record
status: Approved
last_updated: 2026-08-02
---

# ADR-0001: Initial Technology Stack

**Status:** Approved
**Date:** 2026-08-02
**Owner:** Ahmed

## Context

The project needed an approved technology stack before any Technical Design could be
authored — `docs/02-architecture/technology-stack.md` had been a placeholder since project
start, and `Project-Overview.md` §13 explicitly deferred every layer as `TBD`. This decision
records the initial stack as provided by the Chief Software Architect.

## Options Considered

Not applicable in the usual sense — this ADR records an initial stack decision made
directly by the Chief Software Architect (Ahmed), rather than a choice among evaluated
alternatives. It is recorded as an ADR regardless, because it meets the test in
`Decision-Making-Principles.md` §7: every module's Technical Design would otherwise have to
independently guess the same answers.

## Decision

Approved, as detailed in `docs/02-architecture/technology-stack.md`:

- **Mobile frontend:** Flutter (Customer and Hotel Manager apps)
- **Web frontend:** React + Vite
- **Backend:** Node.js + Express.js
- **Database:** PostgreSQL, via Prisma ORM
- **Authentication:** JWT + Refresh Tokens, with RBAC
- **Storage:** Provider-agnostic abstraction; Cloudinary is the default provider
- **API:** REST, documented with OpenAPI (Swagger)
- **Containerization:** Docker
- **Push notifications:** Firebase Cloud Messaging
- **Version control:** GitLab

## Consequences

- Every future Technical Design works within this stack unless a new ADR changes it.
- `Project-Overview.md` §13's technology stack table is updated from `TBD` to these values.
- ~~Open question, not resolved by this ADR: the inclusion of a React + Vite web frontend
  is not consistent with `Project-Overview.md` §7...~~ **Resolved 2026-08-02 — see Update
  below.**
- The storage layer must be built behind a provider abstraction from the start — Cloudinary
  is a default, not a hard dependency (`Architecture-Principles.md` §10).

## Update — 2026-08-02

`BDR-007` (`docs/04-business/business-decision-register.md`) is now **`Approved`**: React +
Vite serves the **Platform Administration** web dashboard only. Customers and Hotel
Managers remain mobile-only. `Project-Overview.md` §7 has been updated to state this
explicitly as the one approved exception to mobile-application-first scope. This ADR's
Decision (the stack itself) is unchanged — only the previously-open scope question is now
resolved.

## Related

- Amends: `docs/02-architecture/technology-stack.md`
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR: `BDR-007` (Approved — web frontend scope)
