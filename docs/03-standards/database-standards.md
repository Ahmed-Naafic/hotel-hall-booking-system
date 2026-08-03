---
title: "Database Standards"
document_type: Standard
status: Approved
version: 1.0
owner: Ahmed (Lead Database Architect)
last_updated: 2026-08-03
---

# Database Standards
## Hotel Hall Booking Management System

This document defines the official database standards for this project. **Every database
table, Prisma model, migration, query, and relationship must comply with this document.**

> **Relationship to other documents:** `Architecture-Principles.md` §9 already states the
> database *principles* (data integrity first, UUID keys, soft delete, audit fields, no
> duplicated data) — this document is their full operational standard. `naming-conventions.md`
> §8 already governs table/column/Prisma naming exhaustively; this document does not repeat
> it, only extends it (e.g. junction tables, §6). `coding-standards.md` §6 already governs
> how Prisma *queries* are written (transactions, `select`/`include`, pagination mode,
> migration commands); this document governs what the *schema itself* looks like — table
> shape, constraints, indexes, relationship design — not how it's queried. `data-architecture.md`
> (once authored) governs *architectural* data ownership and cross-module access rules; this
> document governs the *standard* every table follows regardless of which module owns it.

---

## 1. Purpose

Fourteen modules, built by three engineers plus AI assistance, all share one PostgreSQL
database. Without a shared standard, each module's tables would be shaped by whoever wrote
that migration first — inconsistent constraints, inconsistent audit trails, inconsistent
soft-delete behavior — and every cross-module query would need to account for those
differences individually.

Database standards exist to ensure **data integrity, consistency, maintainability,
performance, security, scalability, and reliable migrations** — so that a query against any
table can rely on the same guarantees (an `id` is a UUID, a soft-deleted row is `deleted_at
IS NOT NULL`, a timestamp is named `*_at`) without checking that table's specific history.

---

## 2. General Database Principles

The code-level application of `Architecture-Principles.md` §9 — see that section for the
canonical principle list. This section states what following it actually looks like:

- **Data integrity first.** Constraints the database can enforce (§13) are enforced there —
  never left to application code alone to get right every time.
- **Normalize appropriately.** Data is structured to avoid redundancy by default; a
  deliberate denormalization (e.g. a cached total for performance) is documented in the
  relevant Technical Design, not introduced silently.
- **Avoid duplicate business data.** A fact lives in exactly one table; every other
  reference to it is a relationship (§10), never a copy (`Project-Constitution.md` §7).
- **Prefer explicit relationships.** A foreign key (§5), never an implicit convention (e.g.
  matching IDs across tables with no declared relation).
- **Business rules should not rely solely on the database.** A `CHECK` constraint (§13) is
  a safety net for true data-integrity invariants — the business rule itself is enforced in
  the service layer (`coding-standards.md` §11), where it can be tested, versioned, and
  explained in a Business Specification.
- **Keep the schema simple and maintainable.** A table is added because a Business
  Specification requires it (§18) — not speculatively, and not more normalized or more
  denormalized than the current, real query patterns justify.

---

## 3. Prisma Standards

Query-writing patterns (transactions, `select`/`include`, pagination mode, migration
commands, when raw SQL is acceptable) are fully governed by `coding-standards.md` §6 — not
repeated here. This document governs the schema those queries run against:

- **Models** — one Prisma `model` per table, named per `naming-conventions.md` §8
  (`PascalCase` singular, mapped via `@@map` to a `snake_case` plural table).
- **Relations** — declared explicitly in the schema (`§10`); Prisma's relation fields are
  what make a join a compile-time-checked operation instead of a manually-joined query.
- **Enums** — a Prisma `enum` is used whenever a field's valid values are a fixed, known
  set (e.g. a status) — never a free-text string field validated only in application code.
- **Raw SQL** — as `coding-standards.md` §6 states, avoided except where the query builder
  genuinely cannot express the query; this is always a Technical Design decision, never a
  default reached for out of convenience.

---

## 4. Primary Keys

- **UUID (v4) for every business entity table.** Generated via Prisma's `@default(uuid())`.
  No auto-increment integer IDs are used for business tables — sequential IDs leak record
  counts across tenant boundaries and are unsafe to expose across the API
  (`Architecture-Principles.md` §9; `naming-conventions.md` §8).
- **The primary key column is always named `id`**, per `naming-conventions.md` §8.
- **Pure junction tables** (§6) — a many-to-many link with no attributes of its own beyond
  the relationship — may use a **composite primary key** of the two foreign keys instead of
  a surrogate UUID, since a surrogate key would carry no meaning. A junction table that
  *does* carry its own attributes (timestamps, a status, who created the link) gets a
  regular UUID `id` like any other table.

---

## 5. Foreign Keys

Naming (`<singular_referenced_table>_id`) is fully governed by `naming-conventions.md` §8.

- **Referential integrity is always enforced at the database level** — a Prisma `relation`
  creates a real foreign key constraint; there is no "soft," application-only reference
  between tables.
- **Cascade behavior is chosen deliberately per relationship, not defaulted blindly:**
  - **`RESTRICT`** — the default preference. Prevents deleting a parent that still has
    children, forcing an explicit decision rather than silent data loss (e.g. a Hotel with
    existing Halls cannot be deleted outright).
  - **`SET NULL`** — used for genuinely optional relationships, where the child record
    remains meaningful without the parent (e.g. a Booking's assigned Staff member being
    removed unassigns the Booking rather than invalidating it).
  - **`CASCADE`** — used sparingly and only where the child record has no meaning at all
    without the parent, *and* soft delete (§9) isn't the more appropriate answer — which it
    usually is for business-significant data. `CASCADE` is most appropriate for genuinely
    disposable child records (e.g. line-item detail that only exists to describe its
    parent).

---

## 6. Table Naming

Fully governed by `naming-conventions.md` §8 (`snake_case`, plural, descriptive —
`bookings`, `hotel_managers`). This section extends it with the one case that document
doesn't cover:

**Junction tables** — named `<table_a_singular>_<table_b_singular>`, both sides singular,
ordered by logical/reading sense rather than alphabetically forced:

```
hall_amenities          (a Hall has many Amenities, an Amenity is used by many Halls)
booking_staff_assignments   (a first-class relationship with its own meaning — a proper
                              descriptive name, not just "bookings_staff")
```

A junction table is named for what it *represents* when the relationship itself is a
business concept (an "assignment," a "membership") rather than a bare `<a>_<b>` pairing.

---

## 7. Column Naming

Fully governed by `naming-conventions.md` §8 (`snake_case`). This section adds
column-category conventions not covered there:

| Category | Convention | Example |
|---|---|---|
| Timestamps | Suffixed `_at`, never `_date` or `_on` | `created_at`, `confirmed_at`, `cancelled_at` |
| Booleans | Prefixed `is_`/`has_`/`can_` | `is_active`, `has_deposit` |
| Enum fields | Named for what they represent — no redundant `_enum`/`_type` suffix unless disambiguation is genuinely needed | `status`, not `status_enum` |

---

## 8. Audit Columns

| Column | Applies to | When |
|---|---|---|
| `created_at` | Every table | Always — set automatically at insert. |
| `updated_at` | Every table | Always — maintained automatically via Prisma's `@updatedAt`. |
| `created_by` | Business tables where accountability for creation matters | Where a Technical Design identifies a real auditability need (`Project-Constitution.md` §8) — not blanket on every table (e.g. a pure junction table, §6, may not need it). |
| `updated_by` | Same criterion as `created_by` | Same as above. |

`created_at`/`updated_at` are universal because they cost nothing and are needed constantly
for debugging and reporting; `created_by`/`updated_by` are added deliberately, because they
require a real actor reference and aren't meaningful on every table.

---

## 9. Soft Delete Strategy

- **`deleted_at`** (nullable timestamp) is the soft-delete mechanism, per
  `Architecture-Principles.md` §9 and `coding-standards.md` §6. `NULL` means active; a
  non-null value means deleted. Every query against a soft-deletable model filters
  `deleted_at: null` unless explicitly auditing deleted records.
- **`deleted_by`** (nullable FK) — added where accountability for deletion matters, same
  criterion as §8's `created_by`/`updated_by`.
- **Soft delete is distinct from suspension/deactivation.** A Hotel being temporarily
  deactivated by a Platform Administrator is a different business concept from a Hotel being
  deleted — that's a `status` field or an `is_active` boolean (§7), never conflated with
  `deleted_at`. Deletion and deactivation are never the same column.
- **Restoration** — a soft-deleted record is restored by clearing `deleted_at` (and
  `deleted_by`); *who* may restore, and under what conditions, is defined in the owning
  module's Business Specification — not assumed here.
- **When soft delete is preferred:** business- and audit-significant records (Bookings,
  Payments, Reviews, and similarly consequential data) always soft delete. Permanent
  deletion is reserved for genuinely disposable data with no audit requirement (e.g. an
  expired, never-confirmed Hold) — `Architecture-Principles.md` §9.

---

## 10. Relationships

- **One-to-One** — rare in this domain. Used only when splitting a table for a genuine
  lifecycle or access-control reason (e.g. separating especially sensitive Payment detail
  from a Booking for tighter access scoping) — never used just to organize columns for
  tidiness.
- **One-to-Many** — the common case (a Hotel has many Halls; a Customer has many Bookings).
  The foreign key lives on the "many" side (§5).
- **Many-to-Many** — modeled via an explicit junction table (§6), never via a JSON/array
  column pretending to hold a relationship. This is what keeps referential integrity
  enforced by the database (§5) rather than by application-level convention (§2).

---

## 11. Transactions

A database transaction (`prisma.$transaction(...)`, per `coding-standards.md` §6) is
**mandatory** whenever an operation touches more than one table and partial completion
would leave inconsistent data. Concretely, on this platform:

- **Booking creation** — creating the Booking record and updating Hall/Calendar
  availability happen together, or not at all.
- **Payment processing** — recording the payment and updating the Booking's payment status
  happen together.
- **Refunds** — the payment adjustment and the Booking status change happen together.
- **Any other multi-step business operation** identified in a Technical Design where two or
  more tables must move together.

A sequence of separate, non-transactional queries is never used to approximate one of these
operations, even when it "usually works."

---

## 12. Indexing

- **Primary keys** are indexed automatically by the primary key constraint (§4) — no
  action needed.
- **Foreign keys** are generally indexed — PostgreSQL does not auto-index them the way it
  does primary keys, and a foreign key is the most common join/filter path in this schema.
- **Frequently filtered/searched columns** (e.g. a Booking's `status`, a Hall's
  `hotel_id` + `is_active` combination) get an index when a real, identified query pattern
  needs it — not speculatively added to every column.
- **Composite indexes** follow query order: the most selective or most commonly-filtered
  column first.
- **Avoid unnecessary indexes.** Every index has a write cost. An index is added because a
  Technical Design identifies the query pattern that needs it (`Architecture-Principles.md`
  §12, Performance Principles: optimize against a measured need) — not by default.

---

## 13. Constraints

| Constraint | Standard |
|---|---|
| `NOT NULL` | The default for every column, unless a field is genuinely optional per its Business Specification. |
| `UNIQUE` | Applied to natural/business-unique fields (e.g. a Customer's email). |
| `CHECK` | Used for true data-integrity invariants the database can verify cheaply (e.g. a rating between 1 and 5) — a safety net, not the primary enforcement of a business rule (§2). |
| Default values | Set where a sensible, unconditional default exists (e.g. `created_at` defaults to `now()`) — never used to silently substitute for a value business logic should have explicitly provided. |

---

## 14. Migration Standards

- **One logical schema change per migration.** A migration that adds a table and
  unrelated-ly alters another table's constraint is two migrations, not one.
- **An applied migration is never edited.** If a mistake is discovered, a **new** migration
  corrects it — the same "append, don't rewrite history" pattern this project already
  applies to ADRs (`Decision-Making-Principles.md` §7) and Business Decision Records
  (`business-decision-register.md` §2).
- **Migrations are committed alongside the schema change they support**, in the same
  change, never as an afterthought.
- **Migration review before execution.** A migration is reviewed as part of Implementation
  Review (`Development-Lifecycle.md` Phase 9) — especially any migration that could affect
  existing data (e.g. adding a `NOT NULL` column to a populated table needs an explicit
  backfill plan in the Technical Design). A migration is never run directly against a
  shared environment without that review.

---

## 15. Performance Guidelines

Principles are `Architecture-Principles.md` §12; query-writing patterns are
`coding-standards.md` §13 and `api-standards.md` §18. Schema-level guidelines:

- **Efficient queries** are enabled by correct indexing (§12) — an unindexed frequent
  filter is a schema defect, not just a query-writing one.
- **Pagination** — the API contract is `api-standards.md` §10; the schema supports both
  offset and cursor pagination by ensuring the columns each mode sorts/filters on are
  indexed.
- **Avoid N+1 queries** — `coding-standards.md` §6's `include`/`select` pattern is the
  primary defense; the schema's foreign keys (§5) are what make that pattern possible.
- **Query optimization** — a query suspected of being slow is checked with `EXPLAIN
  ANALYZE` before an index or schema change is made to "fix" it — the diagnosis comes
  before the change.

---

## 16. Security Guidelines

Principles are `Project-Constitution.md` §8 and `Architecture-Principles.md` §7; the
exhaustive checklist is `security-coding-standards.md` (once authored). Database-specific
guidelines not already stated elsewhere:

- **Parameterized queries, always** — Prisma's query builder parameterizes by default
  (`coding-standards.md` §12); this is exactly why raw SQL (§3) is avoided except where
  unavoidable.
- **Least privilege** — the application's database connection uses a role with only the
  permissions it actually needs, never a superuser/admin connection.
- **Protect sensitive data** — payment details and password hashes are never stored in
  plain text (`coding-standards.md` §12).
- **Encryption where required** — a column identified as holding especially sensitive data
  may need encryption at rest beyond standard database-level encryption; this is decided
  per Technical Design when such a field is identified, not applied blanket across the
  schema.
- **Avoid exposing internal identifiers unnecessarily** — this is substantially already
  solved by §4's UUID choice, which is precisely why UUIDs (not sequential integers) were
  standardized: a UUID is safe to expose across the API without leaking record counts or
  being guessable, per `naming-conventions.md` §8's original reasoning.

---

## 17. Backup & Recovery

Specific tooling, schedule, and RPO/RTO targets depend on the hosting/cloud provider, which
is still **TBD** (`Project-Overview.md` §13) — this section states the principles that
apply regardless of which provider is eventually chosen, to be operationalized once that
decision is made:

- **Automated backups** run on a regular schedule once a hosting provider is selected — a
  manual, ad hoc backup process is not acceptable for a commercial platform handling
  payments.
- **Recovery is tested periodically**, not assumed to work — a backup that has never been
  restored is unverified.
- **Development seed data is separate from backups.** Seed data (`folder-structure.md` §6,
  `scripts/seed/`) is synthetic and representative, generated for local/testing use — it is
  never a copy of real production data, per `Project-Constitution.md` §8 (Data privacy).
- **Disaster recovery targets** (RPO/RTO) are defined once the hosting provider is
  approved, tracked as a follow-up architecture decision, not invented here.

---

## 18. AI Development Rules

This restates and is governed by `Project-Constitution.md` §4, `Architecture-Principles.md`
§14, and `coding-standards.md` §15 — see those for the canonical AI rules. Database-specific
additions only:

- **AI must respect the approved schema** — it works within what an approved Technical
  Design and existing migrations define.
- **AI must never invent a table or column** not traceable to an approved Business
  Specification or Technical Design.
- **AI must never rename an existing entity** — a `Project-Glossary.md` term stays exactly
  as named in the schema, the same rule `coding-standards.md` §15 states for code.
- **AI must generate Prisma-compliant code** matching `naming-conventions.md` §8 exactly.
- **AI must preserve referential integrity** — never removing or working around a foreign
  key constraint (§5) to make a migration or query easier to write.

---

## 19. Database Review Checklist

What a reviewer checks specifically about a schema change — the formal Implementation
Review approval is `review-checklists.md` and `Development-Lifecycle.md` Phase 9; this is a
reading aid, the same relationship `coding-standards.md` §16 and `api-standards.md` §20
have to that review.

- [ ] **Naming** — matches `naming-conventions.md` §8 and this document's §6–§7 exactly.
- [ ] **Relationships** — correct cardinality (§10), foreign keys enforced (§5).
- [ ] **Constraints** — `NOT NULL`, `UNIQUE`, `CHECK` applied where appropriate, not
      over-applied (§13).
- [ ] **Indexes** — present where a real query pattern needs them, absent where they don't
      (§12).
- [ ] **Transactions** — multi-table operations wrapped correctly (§11).
- [ ] **Performance** — no obvious missing index or N+1-enabling design (§15).
- [ ] **Security** — no sensitive data unprotected, least-privilege respected (§16).
- [ ] **Migration quality** — one logical change, reviewed before execution, no edits to an
      already-applied migration (§14).
- [ ] **Documentation updates** — the module's Technical Design and, if applicable,
      `domain-model-and-bounded-contexts.md`, reflect the schema change.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-03 | Ahmed | Initial approved Database Standards |
