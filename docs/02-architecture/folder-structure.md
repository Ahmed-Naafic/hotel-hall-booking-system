---
title: "Folder Structure"
document_type: Architecture
status: Approved
version: 1.3
owner: Ahmed (Lead Software Architect)
last_updated: 2026-08-03
---

# Folder Structure
## Hotel Hall Booking Management System

This document defines the official repository structure for the entire project — the
single source of truth for where code lives. It is one of the project's core architecture
documents. **Every developer and every AI assistant must follow this structure.**

This document operationalizes `Architecture-Principles.md` §3 (Modular Architecture) and §4
(Separation of Concerns) at the level of actual folders and files — the same relationship
`Team-Management.md` has to `Project-Constitution.md` §6. It does not re-argue those
principles; see that document for the reasoning. This document contains no business logic
and no code.

**No implementation code exists yet** (`Project-Overview.md` §21). This document describes
the repository's required shape. Per **ADR-0003**
(`docs/02-architecture/adr/0003-repository-initialization-scaffolding.md`), the **top-level
skeleton only** — `apps/customer-mobile/`, `apps/manager-mobile/`, `apps/admin-web/`,
`backend/`, `shared/`, `docker/`, `scripts/`, each containing nothing but a placeholder
`README.md` — is created once, at repository initialization. Every **module or feature
subfolder** inside that skeleton (e.g. `backend/src/modules/bookings/`,
`apps/customer-mobile/lib/features/booking/`), every dependency manifest, and all
application code are still created only as each module reaches `Development-Lifecycle.md`
Phase 8 (Implementation), not before — writing that ahead of an approved Business
Specification and Technical Design would itself violate `Project-Constitution.md` §5.

---

## Architectural Decision: Feature-Based, Not Layer-Based

The entire project — the repository, the backend, both Flutter apps, and the web app — uses
**Feature-Based Modular Architecture**. A traditional layered structure (all controllers in
one folder, all services in another, spanning every feature) is explicitly rejected.

**This does not contradict `Architecture-Principles.md` §4**, which defines five
responsibility layers (Presentation, API, Business Logic, Data Access, Infrastructure).
Those layers still exist — but *inside* each feature module, not as top-level folders. A
feature's controller, service, and repository live together, in that feature's own folder,
not scattered across three unrelated top-level directories. §4 defines what each layer is
responsible for; this document defines where that responsibility physically lives.

---

## 1. Repository Structure

```
/
├── apps/                       Client applications
│   ├── customer-mobile/        Flutter — Customer app
│   ├── manager-mobile/         Flutter — Hotel Manager app
│   └── admin-web/               React + Vite — Administration & Platform Management
│                                 (confirmed by BDR-007, see §3)
├── backend/                    Node.js + Express.js API — feature-based modules (§4)
├── shared/                     Code genuinely reusable across apps and/or backend (§5)
├── docker/                     Containerization: Dockerfiles, compose files
├── scripts/                    Repo- and environment-level scripts (§6)
├── docs/                       Documentation (already finalized — see §8)
└── README.md
```

| Folder | Purpose |
|---|---|
| `apps/` | Every client-facing application, one subfolder per app, each internally feature-based (§2, §3). |
| `backend/` | The single Express.js API serving every app, organized as feature modules (§4). |
| `shared/` | Code reusable across multiple apps or across backend and apps — not specific to one feature or one app. Deliberately kept small (§5). |
| `docker/` | Containerization assets: one Dockerfile per app/service, plus compose files for local development. Stays at the repository root, not nested under `backend/`, since it may need to build more than one app. |
| `scripts/` | Scripts that operate on the repo or environment as a whole (seeding, migrations, CI helpers) — never business logic (§6). |
| `docs/` | Governed exhaustively elsewhere (`documentation-architecture.md`); not redefined here. |

---

## 2. Mobile Applications (Flutter)

Both `customer-mobile/` and `manager-mobile/` follow the same internal shape:

```
lib/
├── features/
│   └── <feature_name>/
│       ├── presentation/       UI: screens, widgets, view controllers
│       ├── application/        Feature-specific use cases / state management
│       ├── domain/              Feature's entities and client-side business rules
│       └── data/                 Feature's repositories, API clients, local data sources
├── core/                        Cross-app infrastructure: routing, theming, error handling,
│                                  network client setup
└── shared/                      Reusable UI components/utilities used by 2+ features
```

- A feature owns its presentation/application/domain/data layers **where relevant** — a
  simple, read-heavy feature may not need a dedicated domain layer. Nothing is added for
  symmetry alone (`Architecture-Principles.md` §2, Simplicity before complexity).
- `core/` is infrastructure every feature depends on, not feature logic — the same
  distinction `Architecture-Principles.md` §5 draws for the backend, applied client-side:
  `core/` provides the plumbing; `features/` never reimplements it.
- Feature folder names match the module names used everywhere else (§9).
- The two apps do **not** share a `features/` folder — each includes only the features
  relevant to its role. Where both apps touch the same module (e.g. both display Hall
  availability), the *folder name* is expected to repeat across apps; the underlying *logic*
  is not duplicated — it lives in the backend, or in `shared/` only if it must run
  client-side in both apps (§5).

---

## 3. Admin Web Application (React + Vite)

**Scope note:** this app's existence is confirmed by `BDR-007` (`Approved`) in
`docs/04-business/business-decision-register.md` — a Platform Administration dashboard
only, not a Customer- or Hotel-Manager-facing app.

```
src/
├── features/
│   └── <feature_name>/
│       ├── components/         Feature-specific UI components
│       ├── hooks/                Feature-specific React hooks
│       ├── services/             Feature-specific API calls
│       └── routes/                Feature-specific route definitions
├── core/                         App shell: routing setup, layout, global providers
└── shared/                       Reusable components/hooks used by 2+ features
```

- **Not** organized by top-level `pages/`, `components/`, or `services/` folders — that
  grouping scatters one feature's code across three unrelated places, which is exactly the
  layer-based approach this project rejects.
- A feature owns its own components, hooks, services, and routes **where it needs them** —
  not every feature needs all four.
- Scoped to Administration & Platform Management (`BDR-007`), so `features/` here is
  expected to stay small relative to the mobile apps.

---

## 4. Backend (Node.js + Express.js)

```
backend/src/
└── modules/
    ├── authentication/
    ├── customers/
    ├── hotels/
    ├── halls/
    ├── calendar/
    ├── bookings/
    ├── payments/
    ├── events/
    ├── staff/
    ├── notifications/
    ├── reviews/
    ├── reports/
    ├── administration/
    └── security/
```

**Note on this list:** these fourteen folders map exactly to the fourteen approved modules
in `Project-Overview.md` §6 — a folder structure traces to approved scope, it does not
introduce new concepts unreviewed. `calendar/` is Calendar & Scheduling Management. A
`branches/` module is **not** included, and per `BDR-008` (`Approved`,
`docs/04-business/business-decision-register.md`) it stays that way for the foreseeable
future: one Hotel account represents exactly one physical location; a hotel chain
registers multiple Hotel accounts. This is a confirmed scope decision, not a placeholder.

Each module contains only its own implementation — nothing about another module. A module's
typical internal shape:

```
modules/<module_name>/
├── <module_name>.routes.js         Route definitions for this module's endpoints
├── <module_name>.controller.js     HTTP request → business call (API layer)
├── <module_name>.service.js        This module's business logic (Business Logic layer)
├── <module_name>.repository.js     Data access via Prisma, scoped to this module's tables
│                                     (Data Access layer)
├── <module_name>.validation.js     Input validation schemas for this module's endpoints
└── <module_name>.types.js          Module-specific types/DTOs, if applicable
```

**Not every module needs every file.** A module with no complex validation doesn't get an
empty `validation.js` created for symmetry — these filenames are the common shape a module
*may* need, not a mandatory checklist (`Architecture-Principles.md` §2). Functionality used
by two or more modules never lives inside a module folder — it belongs only in `shared/`
(§5).

---

## 5. Shared Layer

`shared/` — at the repository root, and inside each app — holds only code that is
**genuinely** reusable, not a catch-all:

- **middleware** — cross-cutting Express middleware (auth verification, error handling,
  request logging)
- **utilities / helpers** — generic functions with no business meaning (date formatting,
  string helpers)
- **constants** — values used across modules (e.g. role names, statuses shared per
  `Project-Glossary.md`) — a module-specific value stays in that module
- **errors** — the shared error types and response shape
  (`Architecture-Principles.md` §13, consistent error responses)
- **validators** — genuinely cross-module validation (e.g. a shared UUID or pagination
  validator) — a module's own business validation stays in that module's `validation.js`
- **shared services** — services more than one module legitimately needs (e.g. a
  notification-dispatch client used by several modules) — never a business-logic shortcut

**Distinguishing rule:** if removing something from `shared/` would only break one module,
it doesn't belong in `shared/` — it belongs inside that module. This is
`Architecture-Principles.md` §5 ("shared code belongs only in shared modules") applied
literally: **two or more current, real consumers required** — never a hypothetical future
one (`Architecture-Principles.md` §2, Simplicity before complexity).

---

## 6. Infrastructure

```
backend/
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── config/                       Environment-driven configuration — no secrets committed
├── logs/                         Local log output (gitignored)

docker/
├── backend.Dockerfile
├── docker-compose.yml

scripts/
├── seed/                         Database seeding scripts
├── migrate/                       Migration helper scripts
└── ci/                             CI/CD helper scripts
```

- `prisma/` is backend-only — the schema and migrations are the single source of truth for
  the database structure (`Architecture-Principles.md` §9, Database Principles).
- `config/` holds *how* the app is configured, never secret values themselves
  (`Project-Constitution.md` §8, Secret management).
- `scripts/` never contains business logic — a script needing business logic calls into
  `backend/` code, it does not reimplement it (`Architecture-Principles.md` §5).

---

## 7. Testing

Tests mirror feature structure — there is no separate parallel taxonomy:

```
backend/modules/bookings/
└── __tests__/
    ├── bookings.service.test.js        (unit)
    └── bookings.integration.test.js    (integration)

backend/test/
└── utils/                               Shared test utilities (factories, fixtures) —
                                           same "genuinely shared only" rule as §5
```

- Unit and integration tests live beside the module they test, using the same feature name
  — distinguished by filename, not by a separate top-level `unit/`/`integration/` tree. This
  keeps a feature's tests as close to its code as its code is to itself
  (`Architecture-Principles.md` §3, High cohesion).
- Test utilities genuinely shared across modules follow the same §5 rule as any other shared
  code.
- Coverage expectations and required test types are governed by
  `docs/03-standards/testing-standards.md` — this section defines only where tests live.

---

## 8. Documentation

Documentation already mirrors this exact feature structure — this was true before this
document existed (`documentation-architecture.md` §2). Every module's Business
Specification, Technical Design, Implementation Plan, and Validation Report live under an
identically-named slug folder:

```
docs/04-business/modules/<module-slug>/business-specification.md
docs/05-technical-design/modules/<module-slug>/technical-design.md
docs/06-implementation-planning/modules/<module-slug>/implementation-plan.md
docs/07-validation-and-qa/modules/<module-slug>/validation-report.md
```

**Documentation and code use identical feature names**, per the mapping in §9. A Technical
Design that introduces a code module not traceable to its Business Specification's module
has skipped a step, per `Development-Lifecycle.md`.

---

## 9. Naming Conventions

- **File-level and code-identifier naming** (case conventions for files, variables,
  classes, database columns, API fields, and more) is governed by
  `docs/03-standards/naming-conventions.md` — this section covers only *where things live
  and what folders are called*, not what individual files or identifiers are named.
  Language-level code style (formatting, control flow) is `coding-standards.md`.
- **Backend module folders are plural** (`bookings`, `hotels`, `payments`) — a backend
  module represents a collection of that resource. **Flutter/React feature folders are
  singular** (`booking`, `hotel`, `payment`) — a feature represents one area of
  functionality, not a collection. This is a deliberate, complete exception to "identical
  names everywhere": the underlying module is the same across every layer; only this one,
  documented, plural/singular distinction differs by platform idiom.
- **Module names trace to the approved modules** in `Project-Overview.md` §6. A new
  top-level module folder, in any app or in the backend, is never created without a
  corresponding approved module, or an approved addition to that list per
  `Development-Roadmap.md` §9.
- **Shared folders are always named `shared/`** — never `common/`, `lib/`, or `utils/` at
  the top level — so "where's the shared code" always has one answer.
- **Documentation slugs** use the full `NN-kebab-case-module-name` form already established
  (`documentation-architecture.md` §2). Code folders use the shorter form above. The mapping
  between the two is exhaustive and never ambiguous — see §8.

---

## 10. Ownership Rules

These restate `Architecture-Principles.md` §3 (Modular Architecture) and §5 (Dependency
Principles), applied specifically to where code lives — see those sections for the
reasoning behind each:

- Every business capability belongs to exactly one feature module — never split across two.
- Shared code belongs only in `shared/` (§5), and only once it has two or more genuine
  consumers.
- Cross-module dependencies are avoided wherever possible; where a real dependency exists,
  it goes through that module's defined interface, never its internals.
- Modules communicate through defined interfaces — a module never imports another module's
  repository or reaches into its database tables directly.
- Business logic is never duplicated across modules — if two modules need it, one owns it
  and the other consumes it through `shared/` or an explicit interface.

---

## 11. Future Growth

New features are added the same way every existing one was: a new approved module
(`Development-Roadmap.md` §9, Change Management) gets a new `features/<name>/` or
`modules/<name>/` folder, following §2–§4's shape, without moving or renaming anything that
already exists. This is the direct payoff of feature-based organization: the repository's
*shape* doesn't change as it grows, only its *contents* — the same property
`documentation-architecture.md` §2 already guarantees for the documentation tree.

A restructuring of this document's top-level layout is itself a significant architectural
decision and requires an ADR (`Decision-Making-Principles.md` §7).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial approved Folder Structure |
| 1.1 | 2026-08-02 | Ahmed | BDR-007 and BDR-008 resolved — `admin-web/` and `branches/` exclusion now confirmed, not provisional |
| 1.2 | 2026-08-03 | Ahmed | §9 now points to `naming-conventions.md` for file/identifier naming, not `coding-standards.md` |
| 1.3 | 2026-08-03 | Ahmed | Per ADR-0003, the top-level skeleton is now created at repository initialization (placeholder `README.md` only in each folder); module/feature subfolders and all code still wait for each module's Phase 8, unchanged |
