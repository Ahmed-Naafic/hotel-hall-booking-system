---
title: "ADR-0002: Infrastructure Additions — Reverse Proxy and Logging"
document_type: Architecture Decision Record
status: Approved
last_updated: 2026-08-03
---

# ADR-0002: Infrastructure Additions — Reverse Proxy and Logging

**Status:** Approved
**Date:** 2026-08-03
**Owner:** Ahmed

## Context

ADR-0001 recorded the initial technology stack but did not include a reverse proxy or a
logging framework. Both have since been stated as part of the "Approved Technology Stack"
in two separate inputs to this project (the Project Foundation Presentation brief and the
System Architecture request) — consistently enough to treat as confirmed rather than
provisional, and both meet the `Decision-Making-Principles.md` §7 test: every Technical
Design touching deployment or logging would otherwise have to independently guess the same
answer.

## Options Considered

Recorded directly, the same way ADR-0001 was — not a choice among evaluated alternatives.

## Decision

Approved, extending `docs/02-architecture/technology-stack.md`:

- **Reverse proxy:** Nginx — sits in front of the Express API (and, once applicable,
  serves the Admin Web static build), per `system-architecture-overview.md` §12
  (Deployment Overview).
- **Logging:** Winston — the structured logging library backing
  `coding-standards.md` §10's logging principles (error/warning/info/debug levels,
  correlation IDs).

## Consequences

- `technology-stack.md` is updated to include both.
- `coding-standards.md` §10 (Logging) now has a concrete implementation to reference for
  future Technical Designs, though the principles there remain unchanged.
- `system-architecture-overview.md`'s deployment view (§12) places Nginx explicitly between
  client traffic and the Express API.
- Neither addition changes any approved architectural principle — both are implementations
  of principles already established (Error Handling, `Architecture-Principles.md` §13;
  deployment, §12 of `system-architecture-overview.md`).

## Related

- Amends: `docs/02-architecture/technology-stack.md`
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR: none — purely a technical/infrastructure decision, no business-scope question involved.
