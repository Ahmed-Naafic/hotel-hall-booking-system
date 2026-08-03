---
title: "ADR-0004: Workspace Initialization"
document_type: Architecture Decision Record
status: Approved
last_updated: 2026-08-03
---

# ADR-0004: Workspace Initialization

**Status:** Approved
**Date:** 2026-08-03
**Owner:** Ahmed (per `Decision-Making-Principles.md` §4, every ADR is approved by Ahmed)

## Context

`ADR-0003` authorized an empty top-level repository skeleton at repository initialization,
explicitly excluding dependency manifests and application code — those still require a
module to reach `Development-Lifecycle.md` Phase 8.

Workspace initialization (installing Express, Prisma, React, Flutter, and configuring
lint/format/test tooling for the backend and every app) goes further than ADR-0003 covers:
it requires real `package.json`/`pubspec.yaml` files, installed dependencies, and minimal
runnable entry points. Under the literal original rule this would have to wait for Module 1
(Authentication & Account Management) to individually reach Phase 8 — but the toolchain,
lint/format configuration, Prisma connection setup, and Docker dev configuration are not
specific to Authentication or to any single module. They are shared engineering
infrastructure every module's eventual Phase 8 will run inside.

This meets the `Decision-Making-Principles.md` §7 ADR test: without this decision, the first
module to reach Phase 8 (Authentication) would be implicitly responsible for bootstrapping
the entire monorepo's tooling as a side effect of implementing one feature — exactly the kind
of question every future module would otherwise have to independently re-decide.

## Options Considered

1. **Status quo — no dependency installation or runnable code until Module 1 reaches Phase
   8.** Keeps the literal original rule, but means "workspace initialization" as a task has
   nothing to actually do beyond non-toolchain config files, and bundles unrelated tooling
   setup into Authentication's own Implementation Plan.
2. **Initialize all workspaces now, as a cross-cutting engineering-environment milestone,
   strictly bounded to tooling and bootstrap — no feature code.** Install real dependencies
   (Express, Prisma, React, Flutter and their dev tooling) and create the minimal entry point
   each workspace needs to compile/start, with **no routes, no controllers, no services, no
   repositories, no Prisma models, no screens, no pages, no components, no business logic,
   and no authentication implementation** — those remain strictly gated behind each module's
   own approved Business Specification, Technical Design, and Implementation Plan reaching
   Phase 8.

## Decision

**Option 2.** Workspace initialization is a one-time, cross-cutting milestone, distinct from
any single module's Phase 8:

- **Backend:** Node.js project bootstrapped, Express and Prisma installed, a minimal
  `src/index.js` entry point that starts the server with no routes registered, environment
  loading (`dotenv`) and a logging placeholder (`winston`, per ADR-0002) configured, ESLint
  and Prettier configured per `coding-standards.md` §4.
- **Prisma:** initialized and connected to PostgreSQL via `DATABASE_URL` — no models, no
  migrations.
- **Admin Web:** React + Vite project bootstrapped with a minimal placeholder entry
  component — no features, pages, or components beyond the framework's own bootstrap file.
- **Customer Mobile / Hotel Manager Mobile:** Flutter projects bootstrapped with a minimal
  placeholder home widget — no features, screens, or authentication.
- **Docker:** development-only placeholders for the backend and PostgreSQL — not
  production-optimized.
- **Root tooling:** monorepo-aware scripts (`install`, `dev`, `lint`, `format`, `test`).

Every module's own Phase 8 still governs its actual feature work built inside this now-ready
workspace — this decision does not grant any module an earlier start.

## Consequences

- `Project-Overview.md` §21 is updated to record that workspace initialization (ADR-0004)
  is complete, distinct from any module reaching `Feature Accepted`.
- The Feature Assignment Register (`Team-Management.md` §7) and Development Roadmap
  (`Development-Roadmap.md` §7) are unaffected — no module's `Documentation Status` or
  `Implementation Status` changes; Module 1 (Authentication) still starts at Phase 2
  (Business Discovery), not Phase 8.
- Future Implementation Plans assume a ready workspace and do not include tooling bootstrap
  in their own scope.
- Any code beyond this ADR's bounded list (a route, a controller, a screen, a Prisma model,
  an authentication flow) is out of scope for workspace initialization and requires the
  normal Phase 0–7 process for its owning module.

## Related

- Amends: `docs/Project-Overview.md` §21; extends `docs/02-architecture/adr/0003-repository-initialization-scaffolding.md`
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR: none — a process/sequencing decision, not a business-scope question.
