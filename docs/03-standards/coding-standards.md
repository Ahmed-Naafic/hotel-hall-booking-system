---
title: "Coding Standards"
document_type: Standard
status: Approved
version: 1.2
owner: Ahmed (Lead Software Architect)
last_updated: 2026-08-03
---

# Coding Standards
## Hotel Hall Booking Management System

This document defines the mandatory coding standards every developer and AI assistant must
follow. It is one of the project's core standards documents. **Every line of code in this
project must comply with this document.**

> **Relationship to other documents — read this first, it saves re-reading elsewhere:**
> this document covers language-level style, control flow, and framework usage patterns —
> the mechanics of *how code is written*. It deliberately does not repeat:
> - **What things are named** — `naming-conventions.md` (files, identifiers, DB, API).
> - **Where code lives** — `folder-structure.md` (feature-based structure, module file list).
> - **Why the architecture looks this way** — `architecture-principles.md` (layers,
>   dependency rules, multi-tenancy, security, performance, error-handling *principles*).
> - **The full security checklist** — `security-coding-standards.md` (once authored) is the
>   authoritative, exhaustive security checklist; this document states only the security
>   habits that are inseparable from writing code correctly in the first place (§12).
> - **The formal review sign-off** — `review-checklists.md`'s Implementation section is the
>   approval gate; this document's §16 is what a reviewer looks for while reading code, not
>   the record of approval itself.
>
> Where this document is silent on a topic another document owns, that document governs —
> this one is not a second, competing copy of any of them.

---

## 1. Purpose

Three engineers plus AI assistance write code for the same system. Without a shared
standard, each person's (and each AI session's) code reads differently, and every code
review starts by re-litigating style before it can evaluate substance.

Coding standards exist to make code **readable, maintainable, consistent, secure, and
scalable** — and to make code review actually about the code, not about formatting
preferences. **Consistency is more important than personal preference.** A developer who
disagrees with a rule here follows it anyway; disagreement is raised as a proposed change to
this document (`Decision-Making-Principles.md` §5), never expressed as a one-off exception
in a pull request.

This document is also written for AI-generated code specifically: an AI session has no
"house style" of its own to fall back on, so an explicit, enforceable standard is what
keeps AI-authored and human-authored code indistinguishable in quality and shape.

---

## 2. General Coding Principles

This is the code-level application of `Project-Constitution.md` §3 (Core Principles) — the
same principles `Architecture-Principles.md` §2 applies at the system level. Three lenses
on one set of rules: Constitution (philosophy) → Architecture Principles (system design) →
this document (line-by-line practice).

- **Keep code simple.** The simplest implementation that correctly satisfies the Business
  Specification is the correct one (Constitution §3, Simplicity Over Complexity).
- **Readability over cleverness.** Code is read far more often than it's written. A clever
  one-liner that requires re-reading twice loses to three plain lines every time.
- **Small, focused functions.** A function does one thing. If describing what it does needs
  the word "and," it's two functions.
- **Single Responsibility Principle.** Applies at every scale — a function, a class, a
  module (§3) — one reason to change.
- **DRY, where appropriate.** Duplication of *business logic* is never acceptable
  (Constitution §3, Reusability). Duplication of *incidental* structure (two similar-looking
  but independently-varying validation blocks) is fine — premature abstraction to avoid
  looking repetitive is its own defect (Constitution §3, Simplicity Over Complexity).
- **KISS.** The same principle as "keep code simple," restated as the reviewer's question:
  could this be simpler without losing correctness?
- **Avoid premature optimization.** Correctness and clarity come first; optimize only
  against a measured need (§13, `Architecture-Principles.md` §12).
- **Self-documenting code.** Names (`naming-conventions.md`) and structure should make a
  comment unnecessary in most cases. Where a comment is needed, it explains *why*, never
  *what* — the code already says what it does.

---

## 3. Feature-Based Development

Full detail — the module file list and folder shape — is governed by `folder-structure.md`
§4 (backend) and §2–§3 (Flutter/React); the reasoning is `Architecture-Principles.md` §3.
This section states the one coding-level consequence:

**Every feature owns its own controller, service, repository, routes, validation, and
tests. Business logic never leaves its owning feature.** A service in `bookings/` never
contains logic that actually belongs to `payments/` — it calls into `payments/` through a
defined interface (`Architecture-Principles.md` §5), or the logic hasn't been placed in the
right feature yet. If a change requires touching two features' internals to express one
business rule, that's a signal the module boundary needs revisiting, not a signal to reach
across it.

---

## 4. JavaScript Standards

Casing conventions are in `naming-conventions.md` §7. This section governs syntax and
control-flow patterns:

| Topic | Standard |
|---|---|
| `const` vs `let` | `const` by default; `let` only when a binding is genuinely reassigned. `var` is never used. |
| Functions | Arrow functions for callbacks and short functions; named function declarations for top-level module functions (better stack traces, hoisting is not relied upon). |
| Async code | `async`/`await` exclusively. No raw `.then()` chains and no callback-style async APIs in new code. |
| Promise handling | Every `await` is inside a `try`/`catch`, or the function's caller is documented as propagating the rejection. A Promise is never left unhandled. |
| Destructuring | Used for extracting multiple properties (`const { id, status } = booking`), not forced onto single-property access. |
| Optional chaining (`?.`) | Used when a property's absence is an expected, valid state — not as a substitute for validating input that should already be guaranteed present (§11). |
| Nullish coalescing (`??`) | Used for "this may be `null`/`undefined`, default it" — never `||`, which also catches `0`, `""`, and `false` incorrectly. |
| Module imports/exports | ES module syntax (`import`/`export`) throughout, one module per file's primary export named to match the file (`naming-conventions.md` §6). |
| Equality | Strict equality (`===`/`!==`) always. Loose equality (`==`/`!=`) is never used. |
| Template literals | Used for any string interpolation or multi-line string — string concatenation with `+` is not used for building dynamic strings. |

Outdated patterns (`var`, callback pyramids, loose equality, `arguments` object,
prototype-chain manipulation) are never introduced in new code, and are replaced
opportunistically when touched in existing code.

---

## 5. Express Standards

Layer responsibilities are defined in `Architecture-Principles.md` §4; the file list is
`folder-structure.md` §4. This section is what each layer is, and is not, allowed to do:

- **Routes** (`*.routes.js`) — map an HTTP method + path to a controller function. Nothing
  else. No business logic, no direct data access.
- **Controllers** (`*.controller.js`) — read the request, call the service, shape the
  response. A controller never calls Prisma directly, and never contains a business rule —
  if a controller has an `if` statement deciding business outcome rather than HTTP shape
  (status code, response format), that logic belongs in the service.
- **Services** (`*.service.js`) — where business logic actually lives. A service never
  imports `req`/`res` or anything HTTP-specific; it receives plain arguments and returns
  plain data or throws a typed error (§9). This is what makes a service testable without an
  HTTP server.
- **Repositories** (`*.repository.js`) — the only place Prisma Client is called. A
  repository has no business logic — it takes parameters, runs a query, returns data.
- **Middleware** — cross-cutting concerns that apply across routes (authentication,
  centralized error handling, request logging). Feature-specific logic is never implemented
  as middleware; if it only applies to one feature, it belongs in that feature's controller
  or service.
- **Validation** (`*.validation.js`) — schema-based request validation, run before the
  controller's logic executes (§11).

---

## 6. Prisma Standards

Naming (model/field/table mapping) is `naming-conventions.md` §8; the underlying principles
(UUID primary keys, soft delete, audit fields, no duplicated data) are
`Architecture-Principles.md` §9; schema *design* (keys, relationships, constraints,
migrations) is `database-standards.md`. This section governs how queries are actually
written:

- **Transactions.** Any operation touching more than one table where partial completion
  would leave inconsistent data is wrapped in `prisma.$transaction(...)` — never executed
  as separate, sequential queries that could partially fail.
- **Queries use `select`, not blanket fetches.** A query specifies the fields it actually
  needs (`select`) rather than returning entire rows by default — this is also how N+1 and
  over-fetching are avoided (§13).
- **Relationships are loaded via `include`/`select` nesting**, not via a separate query per
  related record in application code — a loop that queries the database once per iteration
  is always a defect, not a style choice.
- **Pagination** uses cursor-based pagination (`cursor` + `take`) for any list that can grow
  large or is user-scrolled; offset-based (`skip`/`take`) is acceptable only for small,
  bounded, page-numbered admin views. The exact API-facing contract for both modes is
  `api-standards.md` §10 — the Prisma query strategy and the API contract are chosen
  together, per endpoint.
- **Migrations** are generated via `prisma migrate dev` during development and applied via
  `prisma migrate deploy` in every other environment — a schema change is never applied by
  hand against a running database.
- **Soft delete** is implemented as a `deletedAt` (nullable timestamp) field, per
  `Architecture-Principles.md` §9; every query against a soft-deletable model filters
  `deletedAt: null` unless explicitly querying deleted records for an audit purpose.
- **Raw SQL is avoided.** Prisma's query builder covers the overwhelming majority of needs;
  `$queryRaw`/`$executeRaw` is used only when the query builder genuinely cannot express the
  query, and is treated as a Technical Design decision (documented, not casually reached
  for) — never used to work around parameterization (§12).

---

## 7. Flutter Standards

Feature/file organization is `folder-structure.md` §2 and `naming-conventions.md` §6. This
section covers coding patterns:

- **Widget organization.** A screen (`*_screen.dart`) composes smaller widgets; a widget
  that grows past doing one visible thing is split, the same "small, focused" rule as §2.
- **Separation of UI and business logic.** A widget's `build()` method never contains
  business rules, direct API calls, or data transformation — it reads already-prepared
  state and renders it. Business logic and API calls live in the feature's
  `application`/`data` layers (`folder-structure.md` §2).
- **Reusable widgets** live in `shared/` only once genuinely used by two or more features —
  the same "genuinely shared only" rule as `folder-structure.md` §5, applied to Flutter
  widgets specifically.
- **State management principles** (not a specific library — none is approved yet in
  `technology-stack.md`; the choice is a Technical Design decision for the first Flutter
  module, made via ADR when that work begins, per `Decision-Making-Principles.md` §7):
  - State changes are explicit and traceable, never mutated in place from inside a widget.
  - A feature's state is owned by that feature (§3) — no feature reaches into another
    feature's state directly.
  - Whatever library is chosen applies uniformly across both mobile apps once decided —
    not selected per feature.

---

## 8. React Standards

Feature/file organization is `folder-structure.md` §3 and `naming-conventions.md` §6.
Admin Web is scoped to Platform Administration only (`BDR-007`). This section covers
coding patterns:

- **Feature-first structure**, per `folder-structure.md` §3 — never a top-level `pages/`,
  `components/`, or `services/` grouping spanning features.
- **Component responsibilities.** A page component (`*Page.jsx`) composes feature
  components and wires up routing/data-fetching; presentational components
  (`*Card.jsx`, `*Table.jsx`) receive data via props and contain no data-fetching of their
  own.
- **Hooks** (`use*.js`) encapsulate reusable stateful logic; a hook used by only one
  component may still live alongside that component rather than being extracted
  prematurely (§2, avoid premature abstraction).
- **Routing** is feature-owned — a feature's routes are defined in that feature's
  `routes/` (`folder-structure.md` §3), composed into the app shell in `core/`, not
  scattered through a single global route file.
- **State organization.** Local component state stays local; state genuinely needed by
  multiple components within a feature is lifted no higher than that feature's boundary —
  it never becomes implicit global state to avoid prop-passing.
- **Reusable UI components** live in `shared/` only once used by two or more features —
  same rule as Flutter (§7) and `folder-structure.md` §5.

---

## 9. Error Handling

Principles are `Architecture-Principles.md` §13. This section is the implementation
pattern:

- **Never ignore exceptions.** An empty `catch` block, or a `catch` that only logs without
  either recovering or re-throwing a meaningful error, is never acceptable.
- **Centralized error handling.** Express uses a single error-handling middleware that
  every route's errors flow into (via `next(error)` or an async-wrapper); individual
  controllers do not each format their own error responses.
- **Consistent API errors.** Every error response uses the same shape
  (`naming-conventions.md` §9's response-field conventions apply to error bodies too) —
  an error code, a human-readable message, and nothing implementation-specific.
- **No internal implementation leakage.** Stack traces, Prisma error internals, and file
  paths never reach the client — they go to logs (§10) only.
- **Recoverable vs. non-recoverable** failures are distinguished in the error type/code, so
  a client can tell "retry this" from "this will never succeed as sent."

---

## 10. Logging

- **Error logs** — an unexpected failure, always with enough context (module, operation,
  correlation/request ID) to diagnose without reproducing.
- **Warning logs** — a handled-but-notable condition (a retried operation, a fallback path
  taken).
- **Information logs** — significant business events worth an operational record (a Booking
  reaching Confirmed, a Hotel approved) — not routine request/response noise.
- **Development debugging** — verbose, local-only logging that is never enabled in a
  deployed environment by default.

**Never log sensitive information** — passwords, tokens, full payment details, or personal
data beyond what's operationally necessary — per `Project-Constitution.md` §8 (Data privacy,
Secret management). If a log line would ever need to be redacted before sharing with a
teammate, it shouldn't have been logged in that form.

---

## 11. Validation

- **All external input is validated** — anything from a Customer, a Hotel Manager, or
  another system — before it reaches business logic (`Architecture-Principles.md` §7).
- **Request validation happens before business logic**, in the module's `*.validation.js`
  (§5), rejecting malformed input before a controller or service ever runs.
- **Business validation belongs in services**, not in request-validation schemas — a
  request-shape check ("is this a valid date") is request validation; a business-rule check
  ("is this date available for this Hall") is business validation, and lives in the service
  where the business rule is actually enforced.

---

## 12. Security

The full, exhaustive security checklist is `docs/03-standards/security-coding-standards.md`
(once authored) — this section states only what's inseparable from writing code correctly
in the first place. Principles: `Project-Constitution.md` §8 and `Architecture-Principles.md`
§7.

- **Never trust client input** — this is §11 restated as a security rule, not just a
  correctness one.
- **Parameterized queries, always** — Prisma's query builder parameterizes by default
  (§6); this is exactly why raw SQL is avoided except where unavoidable, and why raw SQL
  never uses string interpolation to build a query.
- **Passwords are hashed**, never stored or logged in plain text, using the algorithm
  specified once Authentication & Account Management's Technical Design is written.
- **Authorization checks happen server-side**, always — a client-side check (hiding a
  button) is a UX convenience, never a security boundary.
- **Least privilege and secure defaults** — restated from `Project-Constitution.md` §8;
  applied at the code level as: a new endpoint defaults to requiring authentication and the
  narrowest role that can use it, and is *opened up* deliberately, never *locked down* as
  an afterthought.

---

## 13. Performance

Principles are `Architecture-Principles.md` §12. This section is the code-level habit:

- **Avoid unnecessary database queries** — a loop that queries per-iteration is the most
  common violation (§6).
- **Pagination** on every endpoint that can return an unbounded list (§6, §9 of
  `naming-conventions.md` for the query-parameter shape).
- **Efficient loops** — no nested loops over the same collection where a single pass (or an
  indexed lookup) would do.
- **Lazy loading** — data is fetched when needed, not preloaded speculatively across feature
  boundaries (§3).
- **N+1 prevention** — the Prisma `include`/`select` pattern in §6 is the primary defense;
  a code review (§16) specifically checks for a query inside a loop.

---

## 14. Code Quality

- **Function complexity** — if a function needs more than a sentence to describe what it
  does, or nests more than 2–3 levels of conditionals/loops, it's a signal to extract a
  named helper (§2, small focused functions). This is a signal to notice, not a hard
  linter-enforced number.
- **Avoid duplicated logic** — restated from §2; a reviewer treats duplicated business
  logic as a defect, not a style note.
- **Composition over duplication** — when two functions/components are almost identical,
  extract the shared part and compose, rather than copy-pasting and adjusting.
- **Refactor before complexity grows**, not after — if a change to a module is made harder
  by its current shape, that's addressed as part of the change, not deferred to a future
  "cleanup" task that competes with new feature work for priority.

---

## 15. AI Coding Rules

This restates and is governed by `Project-Constitution.md` §4 and `Architecture-Principles.md`
§14 — see those for the canonical rules (AI never invents requirements, never bypasses
architecture, always requires independent human review). This section adds only the
code-generation-specific rules not stated elsewhere:

- **AI must never violate any standard in this document** — an AI session under deadline
  pressure does not relax a rule here any more than a human would.
- **AI must generate maintainable code** — code a human reviewer can understand and modify
  without re-deriving the AI's reasoning from scratch.
- **AI must leave existing approved code's style consistent** — a refactor or addition
  matches the surrounding code's patterns, it does not introduce a competing style
  "because it's better," per `Architecture-Principles.md` §14.
- **AI must never silently rename an approved business concept.** If `Project-Glossary.md`
  defines a term, generated code uses it exactly (`naming-conventions.md` §2) — an AI
  session does not "clean up" `Booking` to `Reservation` or `Order` because it reads more
  naturally in a given context.

---

## 16. Code Review Checklist

This is what a reviewer looks for while reading a diff — the formal approval gate and its
recorded outcome are `docs/07-validation-and-qa/review-checklists.md`'s Implementation
section and `Development-Lifecycle.md` Phase 9. This checklist is a reading aid, not a
separate sign-off.

- [ ] **Architecture compliance** — respects module boundaries and layering (§3, §5;
      `Architecture-Principles.md` §3–§5).
- [ ] **Business compliance** — matches the approved Business Specification exactly, no
      invented behavior.
- [ ] **Security** — §12 and `security-coding-standards.md` followed.
- [ ] **Validation** — external input validated before use (§11).
- [ ] **Error handling** — no swallowed exceptions, consistent error shape (§9).
- [ ] **Performance** — no obvious N+1 queries or unbounded lists (§13).
- [ ] **Readability** — names and structure need no more than the necessary comments (§2).
- [ ] **Testing** — coverage matches `testing-standards.md` and naming matches
      `naming-conventions.md` §13.
- [ ] **Documentation updates** — any doc this change should have updated actually was
      (`Project-Constitution.md` §5).

---

## 17. Do & Don't Examples

Structural examples only — no business rules are implied by the specifics below.

**Layering**

```
✗  Don't: controller queries Prisma directly
   router.get('/bookings/:id', async (req, res) => {
     const booking = await prisma.booking.findUnique({ where: { id: req.params.id } });
     res.json(booking);
   });

✓  Do: controller calls the service; the service calls the repository
   router.get('/bookings/:id', bookingController.getById);
   // controller: const booking = await bookingService.getById(req.params.id);
   // service:    const booking = await bookingRepository.findById(id);
```

**Async handling**

```
✗  Don't: unhandled promise, mixed callback/async style
   function getBooking(id) {
     bookingRepository.findById(id).then(b => { return b; });
   }

✓  Do: async/await, explicit error handling
   async function getBooking(id) {
     try {
       return await bookingRepository.findById(id);
     } catch (err) {
       throw new NotFoundError('Booking', id);
     }
   }
```

**Avoiding N+1**

```
✗  Don't: a query per iteration
   for (const booking of bookings) {
     booking.hotel = await prisma.hotel.findUnique({ where: { id: booking.hotelId } });
   }

✓  Do: load the relation in one query
   const bookings = await prisma.booking.findMany({
     include: { hotel: true },
   });
```

**Duplication vs. premature abstraction**

```
✗  Don't: copy a business rule into two services
   // bookings.service.js and payments.service.js both recompute the same fee logic

✓  Do: one owner, one consumer
   // payments.service.js owns fee calculation; bookings.service.js calls it
```

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-03 | Ahmed | Initial approved Coding Standards |
| 1.1 | 2026-08-03 | Ahmed | §6 points to `api-standards.md` §10 for the exact pagination contract |
| 1.2 | 2026-08-03 | Ahmed | §6 points to `database-standards.md` for schema-design standards |
