---
title: "Architecture Principles"
document_type: Architecture
status: Approved
version: 1.0
owner: Ahmed (Chief Software Architect)
last_updated: 2026-08-02
---

# Architecture Principles
## Hotel Hall Booking Management System

This document defines the architectural philosophy and non-negotiable principles that
govern every technical decision for the lifetime of this project. It is one of the
project's core architecture documents. **Every architecture decision, Technical Design,
Implementation Plan, and code review must comply with these principles.**

This document defines **how the system must be designed** — not how any individual feature
is implemented. It contains no feature-specific examples and no implementation detail.

> **Relationship to other documents:** this project's highest-level architectural rules
> already exist, in compressed form, in `Project-Constitution.md` §2–§4, §7, and §8. This
> document does not restate them — it is their full expansion at the architecture layer,
> the same relationship `Development-Lifecycle.md` has to Constitution §5 and
> `Team-Management.md` has to §6. Where a section below covers ground the Constitution
> already states, it says so explicitly and adds only what's specific to *this system's*
> architecture, grounded in the approved technology stack
> (`docs/02-architecture/technology-stack.md`, ADR-0001). This document was previously
> planned as a subsection of `system-architecture-overview.md`; it has been separated out
> into its own document now that it has grown substantial enough to warrant one — see
> `documentation-architecture.md` §16.

---

## 1. Purpose

Architecture decisions outlive the feature that prompted them. A choice made for Booking
Management's Technical Design becomes a constraint on Payment Management's, Calendar &
Scheduling's, and every module built after — whether or not that was intended. Without a
written set of principles, each module's architecture is decided freshly, by whoever
happens to be preparing it, and consistency degrades one convenient exception at a time.

These principles exist to provide **long-term consistency** — so that a module built in the
project's first month and one built in its third year are recognizably part of the same
system — and to **guide all future design decisions** before they're made, not audit them
after. A Technical Design that conflicts with this document is not "a different style
choice"; it is non-compliant, per `Project-Constitution.md` §10 (Architecture ranks above
Technical Design in decision priority).

---

## 2. Architectural Philosophy

This section is the architecture-specific lens on `Project-Constitution.md` §2 (Project
Philosophy) and §3 (Core Principles). It does not redefine those principles — it states what
each one specifically requires of this system's architecture.

**Simplicity before complexity.** (Constitution §3, Simplicity Over Complexity.)
Architecturally: a single PostgreSQL database with Prisma, a single Express.js API, and two
Flutter mobile clients is the default shape of this system. A more complex topology
(separate services per module, multiple databases, a message bus) is not adopted
speculatively — it is adopted only when a specific, current requirement demonstrates the
simpler shape can't satisfy it.

**Long-term maintainability.** (Constitution §3, Maintainability.) Architecturally: module
boundaries (§3 below) and layer boundaries (§4) exist specifically so that a change to one
module or layer does not require understanding the whole system to make safely.

**Documentation-first development.** (Constitution §3, Documentation First, and §5.)
Architecturally: no Technical Design is authored, and no architecture changes, without the
governing process in `Development-Lifecycle.md` — architecture is never inferred from code
after the fact.

**Business-driven architecture.** (Constitution §3, Business Before Code.) Architecturally:
every module boundary, every data ownership decision, and every integration point traces to
a Business Specification. Architecture is not permitted to introduce structure the business
model doesn't require.

**AI-assisted, human-approved engineering.** (Constitution §4; §14 below.) Architecturally:
AI may draft a Technical Design against these principles, but conformance is confirmed by
independent human review (`Development-Lifecycle.md` Phase 5) — an AI cannot approve its own
architectural reasoning.

**Security by design.** (Constitution §3 and §8; §7 below.) Architecturally: authentication
(JWT + Refresh Tokens) and authorization (RBAC) are structural layers every request passes
through, not checks bolted onto individual endpoints.

**Scalability by design.** (Constitution §3, Scalability.) Architecturally: the system is
multi-tenant from its first module, not retrofitted for multiple Hotels later (§6 below).

**Quality over speed.** (Constitution §3, Quality Over Speed.) Architecturally: an
architectural shortcut taken to hit a deadline is treated the same as any other quality gate
skipped — not permitted, per `Development-Lifecycle.md` §4 (Quality Gates).

---

## 3. Modular Architecture

This expands `Project-Constitution.md` §7's "Modular architecture," "High cohesion," and
"Feature-based organization" bullets.

- **Feature-first organization.** The system is organized around what it does for the
  business — the modules defined in `Project-Overview.md` §6 — not around technical layers
  as the primary grouping. A developer or AI session working on Payment Management should
  be able to find everything relevant to Payment Management in one place.
- **High cohesion.** Everything inside a module's boundary belongs to that module's single
  concern. Logic unrelated to a module's purpose does not accumulate there for convenience.
- **Low coupling.** Modules depend on each other through narrow, explicit interfaces —
  never through shared mutable state, direct database access into another module's tables,
  or knowledge of another module's internals.
- **Independent modules.** A module can be understood, tested, and reasoned about largely on
  its own. This is what makes Round-Robin assignment (`Team-Management.md` §4) viable — two
  engineers on two different modules should rarely block each other.
- **Clear module boundaries.** Every module's data ownership and API surface is explicit,
  per `domain-model-and-bounded-contexts.md`. A module never silently reaches into another
  module's data.

**Why modules stay isolated:** this system is built by a small team plus AI assistance,
working on different modules concurrently, often without deep context on modules they didn't
prepare or implement. Isolation is what makes that safe — a mistake or a misunderstanding in
one module's implementation should not be able to silently corrupt another's.

---

## 4. Separation of Concerns

Every module is organized into the same layers, each with a single responsibility:

| Layer | Responsibility |
|---|---|
| **Presentation** | What the Customer, Hotel Manager, or Platform Administrator sees and interacts with — the Flutter mobile apps and, where applicable, the web frontend. Contains no business logic. |
| **API** | The REST surface a client calls. Translates HTTP requests into business operations and business results back into HTTP responses. Contains no business logic beyond request/response shaping. |
| **Business Logic** | Where business rules, defined in a module's Business Specification, are actually enforced. Knows nothing about HTTP, Flutter, or the database schema directly. |
| **Data Access** | How business logic reads and writes persisted data (via Prisma). Contains no business rules — only how to fetch and store what Business Logic asks for. |
| **Infrastructure** | Everything the system runs on but that isn't the system itself — the database, storage provider, notification service, containerization. Swappable in principle without touching the layers above. |

**Why each layer has a single responsibility:** a layer that mixes concerns (business rules
embedded in a database query, HTTP details leaking into business logic) can't be tested,
reasoned about, or changed independently — the whole point of layering is that a change to
one layer shouldn't require touching the others.

---

## 5. Dependency Principles

- **No circular dependencies.** Module A depending on Module B, which depends on Module A,
  is never permitted — it means the module boundary was drawn wrong (§3).
- **Shared code belongs only in shared modules.** Logic genuinely needed by multiple modules
  lives in an explicitly shared location, owned and reviewed like any other code — it is
  never copy-pasted between modules (`Project-Constitution.md` §7, No duplicated business
  logic).
- **Modules communicate through defined interfaces.** Never through direct access to
  another module's database tables or internal state.
- **Infrastructure must not leak into business logic.** Business Logic (§4) never imports a
  database client, an HTTP library, or a storage SDK directly — it depends on an interface
  that Data Access or Infrastructure implements. This is what makes §10 (Storage
  Principles) enforceable in practice.

---

## 6. Multi-Tenant Principles

Principles only — implementation lives in `data-architecture.md` and
`security-architecture.md`.

- **Complete tenant isolation.** A Hotel's data is never visible to, or modifiable by,
  another Hotel — structurally, not just by application-level convention.
- **Platform administration is separated from tenant operations.** Platform Administrator
  capabilities (`Administration & Platform Management`) operate at a different privilege
  level than any single Hotel's operations, and are never exposed through a Hotel Manager's
  access path.
- **Tenant data protection.** Every module that touches Hotel- or Customer-owned data treats
  tenant boundaries as a data protection requirement, not only an access-control one
  (`Project-Constitution.md` §8, Data privacy).
- **Tenant-aware services.** Every service that reads or writes tenant-scoped data knows
  which tenant it's operating for at all times — there is no code path where tenant context
  is ambiguous or assumed.

---

## 7. Security Principles

This restates and is governed by `Project-Constitution.md` §8 — see that section for the
canonical principle list (Least privilege, Secure defaults, Defense in depth, Input
validation, Authentication before authorization, Auditability, Data privacy, Secret
management). This section adds only what's specific to this system's architecture:

- **Authentication before authorization, structurally.** JWT-based authentication and
  RBAC-based authorization (`technology-stack.md`) are implemented as layers every request
  passes through before reaching Business Logic — never as a check an individual endpoint
  remembers to perform.
- **Refresh tokens are a distinct security boundary.** A refresh token's compromise is a
  different, longer-lived risk than an access token's — the architecture treats them with
  different lifetimes and revocation paths, not as interchangeable credentials.
  Implementation detail is out of scope here; see `security-architecture.md`.
  and `security-coding-standards.md`.
- **RBAC is a first-class architectural layer, not a per-endpoint convenience.** The same
  role model applies across every module — a role's meaning does not vary by module.
- **Least privilege intersects directly with multi-tenancy (§6).** A role's privilege is
  scoped both by *what* it may do and *which tenant's data* it may do it to.

---

## 8. API Principles

- **RESTful design.** The API surface follows REST conventions consistently across every
  module — resources, not remote procedure calls.
- **Versioned APIs.** A breaking change to the API surface is introduced as a new version,
  never as a silent change to an existing one — both mobile apps and any web frontend must
  be able to rely on a version continuing to behave as documented.
- **Documented contracts.** Every endpoint is described in OpenAPI (Swagger), per
  `technology-stack.md` — the documented contract, not the implementation, is the source of
  truth for what an endpoint does.
- **Consistent request/response formats.** The same conventions for structuring a request
  and a response apply across every module's API — no module invents its own shape.
- **Standard error handling.** Every module reports errors the same way (§13).
- **Stateless communication.** No API request depends on server-side session state between
  requests — authentication state travels with the request (via JWT), not in server memory.

---

## 9. Database Principles

- **Data integrity first.** Constraints that the database can enforce (foreign keys,
  uniqueness, non-null) are enforced there, not only in application code.
- **Transactions where required.** Any operation that must succeed or fail as a unit (e.g.
  anything touching more than one table where partial completion would leave inconsistent
  data) is wrapped in a database transaction.
- **UUID primary keys.** Every entity is identified by a UUID, not a sequential integer —
  this avoids leaking record counts across tenant boundaries and keeps IDs safe to expose
  across the API.
- **Soft delete where appropriate.** Data whose history matters for audit, dispute, or
  reporting purposes (e.g. a Booking) is soft-deleted, not physically removed — physical
  deletion is reserved for data with no such requirement.
- **Audit fields.** Every table records who created and last modified a record, and when —
  supporting `Project-Constitution.md` §8's Auditability principle structurally.
- **Explicit relationships.** Foreign keys and relations are declared in the Prisma schema,
  never inferred by application-level convention alone.
- **No duplicate business data.** A given fact is stored in exactly one place; every other
  reference to it is a relationship, not a copy — restating
  `Project-Constitution.md` §7 at the data layer.

---

## 10. Storage Principles

**Business logic must never depend on Cloudinary, or any specific storage provider,
directly.** Storage access goes through a provider-agnostic abstraction layer that Business
Logic and the API call — the concrete provider (Cloudinary is the current default, per
`technology-stack.md`) is an implementation of that abstraction, swappable without touching
any module's business logic. This is the direct application of §5's "Infrastructure must
not leak into business logic" to the storage layer specifically, and it is what makes a
future provider change (S3, Supabase, or otherwise) a §15 (Evolution) concern, not a
rewrite.

---

## 11. Integration Principles

- **External services sit behind abstraction layers.** The same pattern as §10 applies to
  every external integration — payment processing, push notifications (Firebase Cloud
  Messaging), and any future service.
- **Loose coupling.** Business Logic depends on an interface an integration implements, not
  on that integration's specific SDK or API shape.
- **Graceful failure.** An external service being unavailable degrades the relevant feature
  predictably — it does not silently corrupt data or crash unrelated functionality.
- **Retry strategy.** Transient failures in an external integration are retried according to
  a defined policy, not left to fail on first attempt or retried indefinitely.
- **Replaceable integrations.** Any external integration can be replaced by implementing the
  same abstraction — no module is written assuming one specific provider is permanent.

---

## 12. Performance Principles

- **Optimize only when necessary.** Performance work is justified by a measured requirement
  (`Decision-Making-Principles.md` §6, Performance criterion) or a known scale target
  (`Project-Overview.md`'s multi-tenant, multi-hall growth expectation) — never spent
  speculatively against `Project-Constitution.md` §3's Simplicity Over Complexity.
- **Efficient database queries.** Queries fetch what's needed, not more — avoiding
  unnecessary joins or over-fetching is a default expectation, not an optimization pass.
- **Pagination.** Any endpoint that can return an unbounded number of records is paginated
  by default, not only once it becomes a problem.
- **Lazy loading.** Data is loaded when it's needed, not preloaded speculatively across
  module or layer boundaries.
- **Caching where justified.** Caching is introduced for a specific, identified cost — never
  as a default architectural layer every module must account for.

---

## 13. Error Handling Principles

- **Consistent error responses.** Every module's API reports errors in the same structure
  (§8), so a client (mobile or web) handles errors the same way regardless of which module
  it called.
- **No internal implementation leakage.** An error response never exposes stack traces,
  database error text, or internal file paths to a client — only what the caller needs to
  understand what happened.
- **Meaningful logging.** What's hidden from the client is captured in logs with enough
  context to diagnose, tying back to `Project-Constitution.md` §8's Auditability principle.
- **Recoverable failures where possible.** A failure that can be retried or corrected by the
  caller is distinguished, in both the response and the logs, from one that can't.

---

## 14. AI Development Principles

This restates and is governed by `Project-Constitution.md` §4 — see that section for the
canonical rules (AI never invents requirements, never changes approved architecture, never
skips documentation, always follows approved business rules, explains uncertainty, preserves
consistency). This section adds only the architecture-specific application:

- **AI follows this document exactly** when drafting or reviewing a Technical Design — not
  a remembered summary of it.
- **AI must not bypass architecture.** If a Technical Design AI is drafting seems to require
  deviating from an approved principle here, that is a signal to stop and propose an ADR
  (§15), never to quietly implement the deviation and note it in passing.
- **AI-generated Technical Designs require independent human review**
  (`Development-Lifecycle.md` Phase 5) — the same as human-authored ones, with no exception
  for AI-authored architecture reasoning being self-approved.
- **AI must preserve consistency across modules.** An AI session working on one module's
  Technical Design does not introduce a pattern (a different error format, a different
  layering approach) that the rest of the system doesn't already use, even if the new
  pattern seems locally better — that kind of change is a §15 evolution decision, not a
  unilateral one.

---

## 15. Evolution Principles

- **Architecture changes require review.** No architectural principle in this document, or
  decision recorded in `docs/02-architecture/*`, changes without going through
  `Decision-Making-Principles.md` §5 (the standard decision process).
- **Significant architectural changes require an ADR**, approved by Ahmed
  (`Decision-Making-Principles.md` §7), before any Technical Design may rely on the change.
- **Backward compatibility is considered**, not guaranteed unconditionally — a breaking
  change to an API (§8) or a data model (§9) is deliberate, documented, and versioned, per
  `Project-Constitution.md` §7.
- **Breaking changes are minimized.** Where a non-breaking path exists to achieve the same
  outcome, it is preferred — but never at the cost of `Project-Constitution.md` §3's
  Simplicity Over Complexity when the breaking change is genuinely the simpler, correct
  design.

---

## 16. Guiding Statement

This system is built once and lived in for years. Every principle in this document exists
so that the architecture a module is built against today is still recognizable, trustworthy,
and worth extending after a hundred more modules than exist right now — not because
consistency is a virtue in the abstract, but because a three-person, AI-assisted team can
only move quickly and safely on a system whose shape they can still hold in their heads.
Maintainability, scalability, and security are not competing with simplicity here — they are
what simplicity, applied consistently over time, actually produces.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial approved Architecture Principles; separated out of the planned `system-architecture-overview.md` merge (see `documentation-architecture.md` §16), grounded in the technology stack approved by ADR-0001 |
