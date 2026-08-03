---
title: "Naming Conventions"
document_type: Standard
status: Approved
version: 1.1
owner: Ahmed (Lead Software Architect)
last_updated: 2026-08-03
---

# Naming Conventions
## Hotel Hall Booking Management System

This document defines the official naming standards for this project — documentation,
source code, database, API, git, infrastructure, and testing. It is one of the project's
core standards documents. **Every developer, reviewer, and AI assistant must follow these
conventions.**

> **Relationship to other documents:** naming was originally folded into
> `coding-standards.md` (see `documentation-architecture.md` §16) because it was expected to
> stay thin. It has grown enough to warrant its own document — the same reason
> `architecture-principles.md` was separated from `system-architecture-overview.md`.
> `coding-standards.md` still owns language-level style (formatting, control flow,
> project-structure conventions); this document owns *what things are called*.
>
> This document also does **not** repeat folder/module naming already governed in
> `docs/02-architecture/folder-structure.md` §9 — that section is authoritative for folder
> structure; this document cross-references it (§4–§5) and covers everything folder-structure.md
> explicitly left out: files, code identifiers, the database, the API, environment
> variables, git, documentation, and tests.

---

## 1. Purpose

Three engineers plus AI assistance are producing documentation and code in parallel, across
14 (and eventually more) feature modules. If the same concept gets named differently in the
database, the API, the backend module, and the Flutter app, tracing a bug or reviewing a
Technical Design becomes a translation exercise before it can even become an evaluation.

Consistent naming exists so that:

- **Readability** — a name says what it is without needing the surrounding code as context.
- **Maintainability** — a rename is a decision, not an accident of whoever touched the file
  last.
- **Team collaboration** — Ahmed, Mohamed, and Abukar (and whoever joins later) can predict
  a name before they see it, because the same rule applied everywhere before.
- **AI-assisted development** — an AI session generating code or documentation has one
  correct answer to "what do I call this," not a precedent to guess from nearby files.

---

## 2. General Principles

- **Use meaningful names.** A name describes what something is or does, not how it was
  implemented or when it was added.
- **Avoid abbreviations** unless universally understood in context (`id`, `url`, `api`) —
  never invent a project-local abbreviation (`bkg` for booking, `hm` for Hotel Manager).
- **Be consistent.** The same concept uses the same name everywhere it appears — across
  documentation, code, the database, and the API (§14 shows this end to end).
- **Clarity over brevity.** A longer, unambiguous name is always preferred to a short,
  ambiguous one.
- **One concept, one name.** `Booking`, `Reservation`, and `Order` never coexist as
  synonyms for the same thing in this codebase — `Project-Glossary.md` §6 already
  establishes **Booking** as the one official term; that rule extends to every layer named
  in this document.

---

## 3. Project Naming

| Item | Convention | Example |
|---|---|---|
| Repository | kebab-case, descriptive | `hotel-hall-booking-system` |
| Applications (`apps/*`) | kebab-case, `<role>-<platform>` | `customer-mobile`, `manager-mobile`, `admin-web` |
| Top-level areas | kebab-case, single word where possible | `backend`, `shared`, `docker`, `scripts`, `docs` |
| Backend packages (if the backend is ever split into publishable packages) | kebab-case, scoped if applicable | `@hotel-hall/shared` |

These match the repository layout already approved in `folder-structure.md` §1 — this
table is a naming reference, not a second definition of the structure itself.

---

## 4. Feature Module Naming

Full detail, including the plural/singular rule and why, is governed by
`folder-structure.md` §9. Summary, for reference alongside the rest of this document:

```
authentication · customers · hotels · halls · calendar · bookings · payments ·
events · staff · notifications · reviews · reports · administration · security
```

- **Backend module folders are plural**; **Flutter/React feature folders are singular**
  (`bookings` vs. `booking`) — the one documented exception to identical naming everywhere.
- These fourteen names trace exactly to the fourteen approved modules in
  `Project-Overview.md` §6. There is no `branches` module — per `BDR-008`
  (`Approved`, `docs/04-business/business-decision-register.md`), one Hotel account
  represents exactly one physical location; this is a confirmed decision, not an omission.
- A new module name is never introduced without a corresponding approved module
  (`Development-Roadmap.md` §9).

---

## 5. Folder Naming

Also governed by `folder-structure.md` §9 — restated here only for completeness:

- Folders are lowercase; multi-word folders use kebab-case (`customer-mobile`, not
  `customerMobile` or `customer_mobile`).
- Feature names stay consistent across every application and the backend, subject only to
  the plural/singular rule in §4.
- `shared/` is the only name ever used for shared code, at any level.

---

## 6. File Naming

### Backend (Node.js + Express.js)

One file per concern, named `<module_name>.<concern>.js` — lowercase, dot-separated:

```
booking.routes.js         Route definitions
booking.controller.js     HTTP request → business call (API layer)
booking.service.js        Business logic
booking.repository.js     Data access (Prisma)
booking.validation.js     Input validation schemas
booking.mapper.js         Data-shape translation (e.g. Prisma result → API response)
booking.types.js          Module-specific types/DTOs, if applicable
```

Per `folder-structure.md` §4, not every module needs every file — this is the common
vocabulary, not a checklist.

### Flutter

`snake_case`, suffixed by role, one concept per file:

```
booking_screen.dart       A presentation-layer screen/page
booking_provider.dart     State management for a feature
booking_repository.dart   Data access
booking_model.dart        A domain entity
```

### React (Admin Web)

`PascalCase` for components, `camelCase` for everything else:

```
BookingPage.jsx           A route-level page component
BookingTable.jsx          A reusable UI component
BookingCard.jsx           A reusable UI component
useBooking.js             A hook
bookingService.js         An API-calling service
```

### Documentation

Documentation file naming is **already fully established** — this section is a pointer, not
a new rule:

- **Root-level foundational documents** use `PascalCase-With-Hyphens.md`
  (`Project-Overview.md`, `Development-Roadmap.md`).
- **Everything inside a category folder** (`00-governance/`, `02-architecture/`,
  `03-standards/`, etc.) uses `lowercase-with-hyphens.md`
  (`documentation-architecture.md`, `folder-structure.md`, this document).
- **Per-module documents** use one of exactly four fixed, lowercase names
  (`business-specification.md`, `technical-design.md`, `implementation-plan.md`,
  `validation-report.md`) inside a folder named after the module
  (`NN-kebab-case-module-name/`, `documentation-architecture.md` §2). There is no file
  literally named `Booking-Management.md` — the module name lives in the *folder*, not the
  file.
- **ADRs** use `NNNN-kebab-case-title.md` (`0001-initial-technology-stack.md`).
- **Business Decisions** are entries, not files — `BDR-NNN` inside
  `business-decision-register.md` (`Project-Glossary.md` §4).

---

## 7. JavaScript Naming

| Kind | Convention | Example |
|---|---|---|
| Variables & functions | `camelCase` | `bookingId`, `getBookingById()` |
| Booleans | `camelCase`, `is`/`has`/`can` prefix | `isConfirmed`, `hasDeposit` |
| True constants (fixed, global values) | `UPPER_SNAKE_CASE` | `MAX_HOLD_DURATION_MINUTES` |
| Ordinary `const` bindings (not fixed values) | `camelCase`, same as variables | `const booking = ...` |
| Classes | `PascalCase` | `BookingService`, `BookingRepository` |
| Object instances | `camelCase` | `const bookingService = new BookingService()` |
| Enums (plain-object, frozen) | `PascalCase` name, `UPPER_SNAKE_CASE` members | `BookingStatus.CONFIRMED` |
| Interfaces | Not applicable — the approved stack (`technology-stack.md`) is plain JavaScript, not TypeScript. If TypeScript is ever adopted (a stack change requiring an ADR, per `Decision-Making-Principles.md` §7), interfaces use `PascalCase` with no `I` prefix. |

Enum values mirror any corresponding Prisma `enum` (§8) exactly — the JS-side and
database-side vocabulary for a status never drifts apart.

---

## 8. Database Naming

| Item | Convention | Example |
|---|---|---|
| Tables | `snake_case`, plural | `bookings`, `hotel_managers` |
| Columns | `snake_case` | `created_at`, `hotel_id`, `status` |
| Foreign keys | `<singular_referenced_table>_id` | `hotel_id` on `halls`, `customer_id` on `bookings` |
| Indexes | `idx_<table>_<column(s)>` | `idx_bookings_hotel_id` |
| Constraints | `<table>_<column>_<type>` | `bookings_status_check`, `uq_hotels_slug` |
| Prisma models | `PascalCase`, singular | `model Booking { ... }` |
| Prisma fields | `camelCase` in schema, mapped to `snake_case` columns | `createdAt` mapped via `@map("created_at")` |
| Prisma enums | `PascalCase` name, `UPPER_SNAKE_CASE` values | `enum BookingStatus { HELD CONFIRMED CANCELLED }` |

**Relationship between Prisma models and table names:** the Prisma schema stays
JS-idiomatic (`PascalCase` singular models, `camelCase` fields) because that's what Prisma
Client generates into application code (§7) — while the underlying PostgreSQL table stays
SQL-idiomatic (`snake_case` plural). The mapping is explicit and mandatory:
`@@map("bookings")` on the model, `@map("created_at")` on each multi-word field. A
Technical Design never leaves this mapping implicit.

---

## 9. API Naming

RESTful resource naming, consistent with `Architecture-Principles.md` §8:

| Item | Convention | Example |
|---|---|---|
| Endpoints | `/api/v{n}/<resource>`, plural, kebab-case for multi-word resources | `/api/v1/bookings`, `/api/v1/hotel-managers` |
| Path parameters | The resource's own identifier is `:id`; a reference to another resource is `<resource>Id` | `/api/v1/bookings/:id`, `?hotelId=...` |
| Query parameters | `camelCase`; pagination/filtering parameter names are governed in full by `api-standards.md` §10–§11 | `?hotelId=...&startDate=...&page=1&limit=20` |
| Request body fields | `camelCase`, matching Prisma Client's generated field names exactly | `{ "hotelId": "...", "startDate": "..." }` |
| Response body fields | `camelCase`, same rule | `{ "id": "...", "status": "CONFIRMED" }` |

This keeps one casing convention (`camelCase`) unbroken from the Prisma Client through the
API to both Flutter (Dart is `camelCase`-idiomatic) and React — only the raw PostgreSQL
columns are `snake_case`, and that boundary is exactly where the Prisma `@map` in §8 lives.

---

## 10. Environment Variables

`UPPER_SNAKE_CASE`, prefixed by concern where it disambiguates:

```
DATABASE_URL
JWT_SECRET
JWT_REFRESH_SECRET
FCM_SERVER_KEY
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
```

Environment variables are never committed with real values — `folder-structure.md` §6
(`config/` holds *how* the app is configured, never secrets) and
`Project-Constitution.md` §8 (Secret management) govern this; this section governs only
naming.

---

## 11. Git Naming

This section defines **naming format only**. Full workflow (when to branch, PR
requirements, merge strategy) is governed by `docs/03-standards/git-workflow-and-branching.md`.

**Branches:** `<type>/<module>-<short-description>`, kebab-case, using the singular module
name from §4:

```
feature/booking-hold-expiry
bugfix/payment-validation
hotfix/login-error
```

**Commits:** [Conventional Commits](https://www.conventionalcommits.org/)-style prefixes:

```
feat:      a new feature
fix:       a bug fix
docs:      documentation only
refactor:  code change that neither fixes a bug nor adds a feature
test:      adding or correcting tests
chore:     tooling, dependencies, non-product changes
```

---

## 12. Documentation Naming

Already fully established elsewhere — this section is the index, not a new rule:

| Document type | Naming rule | Governed by |
|---|---|---|
| Business Specification | `business-specification.md`, inside `04-business/modules/<module-slug>/` | `documentation-architecture.md` §10.2 |
| Technical Design | `technical-design.md`, inside `05-technical-design/modules/<module-slug>/` | `documentation-architecture.md` §11 |
| Implementation Plan | `implementation-plan.md`, inside `06-implementation-planning/modules/<module-slug>/` | `documentation-architecture.md` §12 |
| Validation Report | `validation-report.md`, inside `07-validation-and-qa/modules/<module-slug>/` | `documentation-architecture.md` §13.2 |
| Decision Records | `BDR-NNN` (register entry) / `NNNN-kebab-case-title.md` (ADR file) | `Project-Glossary.md` §4 |

**Documentation and code use identical feature names**, per `folder-structure.md` §8 — the
`<module-slug>` above (e.g. `05-booking-management`) and the code module name (e.g.
`bookings/`) both trace to the same approved module (§4); only the surrounding naming
convention differs by where each one lives.

---

## 13. Testing Naming

Placement (tests live beside the code they test, not in a parallel tree) is governed by
`folder-structure.md` §7. This section covers file and identifier naming:

```
bookings.service.test.js          Unit test for booking.service.js
bookings.integration.test.js      Integration test for the bookings module
bookings.fixture.js               Reusable test data for bookings
bookings.mock.js                  Mocked dependencies for bookings tests
```

- Test files are named after what they test, with `.test.js` (or `.integration.test.js`)
  appended — never a generic `test1.js`.
- Fixtures and mocks are named after the module they support, not the specific test that
  first needed them, since they're expected to be reused (the "genuinely shared only"
  reasoning from `folder-structure.md` §5 applies here too).
- Test descriptions (`describe`/`it` blocks) name the behavior being verified in plain
  language, not the function name alone — `it("releases the Hold after the configured
  duration expires")`, not `it("test hold expiry")`.

---

## 14. Complete Example — Booking Management

The same feature, named consistently across every layer:

| Layer | Name |
|---|---|
| Documentation folder | `04-business/modules/05-booking-management/` |
| Backend module folder | `backend/src/modules/bookings/` |
| Backend files | `bookings.controller.js`, `bookings.service.js`, `bookings.repository.js` |
| Flutter feature folder | `lib/features/booking/` |
| Flutter files | `booking_screen.dart`, `booking_provider.dart` |
| React feature folder (if applicable to Admin Web) | `src/features/booking/` |
| Database table | `bookings` |
| Prisma model | `model Booking` |
| API endpoint | `/api/v1/bookings` |
| API response field | `{ "id": "...", "hotelId": "...", "status": "CONFIRMED" }` |
| Environment variable (if needed) | `BOOKING_HOLD_DURATION_MINUTES` |
| Git branch | `feature/booking-hold-expiry` |
| Git commit | `feat: add hold expiry to booking service` |
| Test file | `bookings.service.test.js` |

One concept — Booking — with exactly one name per layer, and an exhaustive, documented rule
for why each layer's spelling differs from the others.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial approved Naming Conventions; separated out of the planned `coding-standards.md` merge (see `documentation-architecture.md` §16) |
| 1.1 | 2026-08-03 | Ahmed | §9 pagination example aligned to `api-standards.md`'s formal contract (`limit`, not `pageSize`) |
