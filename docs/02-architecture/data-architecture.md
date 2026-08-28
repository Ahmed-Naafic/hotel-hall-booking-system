---
title: "Data Architecture"
document_type: Architecture
status: Approved
version: 1.2
owner: Ahmed (Chief Data Architect)
last_updated: 2026-08-25
---

# Data Architecture
## Hotel Hall Booking Management System

This document defines the enterprise data architecture for the platform — how business
data is organized, related, governed, and managed across the system, independent of
implementation. **It does not define PostgreSQL tables or Prisma models** — physical schema
design is `docs/03-standards/database-standards.md`.

> **Relationship to other documents:** this document defines *business* information —
> domains, entities, relationships, ownership, lifecycle, governance, classification. Its
> physical counterpart is `database-standards.md` (keys, columns, constraints, migrations —
> what the prompt that requested this document calls "Database-Architecture," which
> already exists under that name). `domain-model-and-bounded-contexts.md` (once authored)
> maps these same entities to per-module bounded contexts for Technical Design purposes —
> narrower and more implementation-adjacent than this document's enterprise-wide view.
> `Architecture-Principles.md` §9 already states the underlying data principles this
> document applies; not repeated here beyond what's needed for context.

---

## 1. Purpose

**Data Architecture and Database Architecture answer different questions.** Data
Architecture answers "what business information exists, what does it mean, who owns it,
and how does it move through its lifecycle" — independent of PostgreSQL, Prisma, or any
other technology. Database Architecture (`database-standards.md`) answers "how is that
information physically stored" — tables, columns, keys, constraints.

This separation exists so the *business* data model remains valid even if the underlying
database technology ever changed (`Architecture-Principles.md` §15, Evolution Principles) —
a Technical Design reasons about a Booking as a business concept first, and only then about
how `bookings` is physically shaped.

---

## 2. Data Architecture Principles

The business-data-specific application of `Architecture-Principles.md` §9:

- **Business-first data modeling.** An entity exists because a Business Specification
  requires it — never introduced for technical convenience ahead of business need.
- **Single Source of Truth.** A business fact is owned by exactly one domain (§9); every
  other domain that needs it references it, never copies it.
- **Data consistency.** The same fact means the same thing everywhere it's used — the same
  discipline `Project-Glossary.md` §2 already applies to terminology, applied to data.
- **Data integrity.** A relationship declared in this document (§5) is enforced physically
  in `database-standards.md` §5 — the two are never allowed to drift apart.
- **Data ownership.** Every entity has exactly one owning domain (§9) — no entity is
  jointly owned by two domains with no tie-breaker.
- **Data lifecycle.** Every entity's creation, use, and eventual archival or deletion is
  understood before it's built (§10) — not discovered after the fact.
- **Minimize duplication.** Restates `Project-Constitution.md` §7 (No duplicated business
  logic) at the data layer.
- **Security by design.** Every entity is classified (§13) as part of its definition, not
  as an afterthought.
- **Scalability.** The model holds as the Platform grows to many Hotels, many Halls, and
  high Booking volume (`Project-Constitution.md` §3, Scalability) — not just at today's
  scale.

---

## 3. Business Data Domains

| Domain | Purpose |
|---|---|
| **Identity & Access** | Who can act on the Platform, and what they're allowed to do — Customers, Hotel Managers, Staff, Platform Administrators, and their roles. |
| **Customer** | Customer profiles, preferences, and account history beyond bare identity. |
| **Hotel** | The tenant entity — a Hotel's profile and its relationship to the Platform. |
| **Hall** | The bookable inventory — a Hall's attributes, availability, and amenities. |
| **Booking** | The central transaction — a Customer's reservation of a Hall for an Event. |
| **Calendar** | The shared availability model underlying Bookings. |
| **Payment** | Payments, deposits, and refunds tied to Bookings. |
| **Event** | Event-specific detail describing what a Booking is for. |
| **Staff** | Hotel employee accounts and their assignment to Bookings/Events. |
| **Notification** | Messages delivered to Customers, Hotel Managers, and Staff. |
| **Review** | Customer feedback tied to completed Bookings. |
| **Reporting** | Derived, read-oriented views over the domains above, for operational and business insight. |
| **Administration** | Platform-wide oversight — Hotel onboarding and approval, cross-tenant administration. |

These thirteen domains map to the fourteen approved modules in `Project-Overview.md` §6
(Security & Access Control is realized *across* every domain above, per
`Architecture-Principles.md` §6, rather than owning a domain of its own — the same
cross-cutting treatment already established for it). **There is no "Branch" domain** — per
`BDR-008` (`Approved`), one Hotel represents exactly one physical location; this document
does not reintroduce the question `folder-structure.md` §4 and `naming-conventions.md` §4
already resolved.

---

## 4. Core Business Entities

Business purpose only — no columns, no physical shape (that's `database-standards.md`):

| Entity | Business Purpose |
|---|---|
| **Customer** | A person or organization that books Halls. |
| **Hotel** | A Platform tenant that owns Halls and employs Staff. |
| **Hall** | A bookable event space belonging to a Hotel. |
| **Booking** | A Customer's reservation of a Hall for a specific Event. |
| **Payment** | A payment made toward a Booking. |
| **Refund** | A return of some or all of a Payment. |
| **Staff Member** | A Hotel employee account with scoped operational access. |
| **Review** | Customer feedback about a Hotel or Hall, tied to a completed Booking. |
| **Notification** | A message delivered about a Booking, Event, or account. |
| **Role** | A named set of permissions (Customer, Hotel Manager, Staff, Platform Administrator). |
| **Permission** | A specific allowed action, granted via a Role. |
| **Audit Record** | An immutable record of a significant action, for accountability. |

There is no "Booking Item" entity at this stage — a Booking reserves one Hall
(`Project-Glossary.md` §3), and no approved Business Specification has yet introduced a
multi-line-item booking concept; one is added here only if a future Business Specification
requires it (§17).

---

## 5. Entity Relationships

Described conceptually — no database notation, no cardinality symbols beyond plain
language:

- A **Hotel** owns **Halls**.
- A **Customer** creates **Bookings**.
- A **Booking** reserves one **Hall** (`Project-Glossary.md` §3 — not multiple Halls per
  Booking, absent a future approved decision).
- A **Booking** describes one **Event**.
- A **Booking** may generate one or more **Payments**.
- A **Payment** may generate a **Refund**.
- A **Hotel** employs **Staff Members**.
- **Staff Members** may be assigned to **Bookings** or **Events**.
- A **Review** belongs to exactly one completed **Booking**.
- A **Role** grants one or more **Permissions**; an **Identity** (Customer, Hotel Manager,
  Staff Member, or Platform Administrator account) holds one or more **Roles**.
- **Notifications** reference the **Booking**, **Event**, or account they concern.
- **Audit Records** reference the entity and actor involved in the action they record.

---

## 6. Master Data

Long-lived reference data that changes rarely and is shared across many records: **Roles**,
**Permissions**, **Hall Types**, **Booking Statuses**, **Payment Statuses**, **Currencies**,
**Countries**, **Cities**, **Amenities**.

Master data is managed differently from transactional data (§7) because it's referenced by
many records rather than created per transaction — a change to master data (e.g. adding a
new Amenity type) is a deliberate, low-frequency administrative action, not something a
Customer or Hotel Manager creates as a side effect of normal use.

---

## 7. Transactional Data

**Bookings, Payments, Refunds, Notifications, Audit Events.** Transactional data is created
continuously as the Platform is used, and moves through a defined lifecycle (§10) — a
Booking progresses from held to confirmed to completed (or cancelled); a Payment moves from
initiated to settled. Unlike master data, transactional records are rarely edited after
creation — they progress through states, and history (via soft delete,
`database-standards.md` §9) is preserved rather than overwritten.

---

## 8. Reference Data

Reusable lookup values that shape how transactional and master data is interpreted, but
aren't master data themselves: **Event Types**, **Hall Categories**, **Payment Methods**,
**Languages**, **System Settings**, **Booking Sources** (e.g. which client app a Booking
originated from).

---

## 9. Data Ownership

| Domain | Owns |
|---|---|
| Customer Domain | Customer profile data and its own business rules for eligibility (`BDR-005`). |
| Hotel Domain | Hotel profile, and the Hotel's application/approval and lifecycle status (`BDR-003`) — Hotel Management (Module 3) owns this data; Administration & Platform Management performs the review action against it through Hotel Management's defined interface. |
| Hall Domain | Hall inventory data, including Hall attributes, availability, and amenities. |
| Booking Domain | Booking records and the Booking Policy business rules (`BDR-006`). |
| Payment Domain | Payment and Refund records and the Payment Flow business rules (`BDR-004`). |
| Administration Domain | Cross-tenant administrative data. **Does not own Hotel approval status** — corrected 2026-08-10; see Hotel Domain row and `docs/05-technical-design/modules/03-hotel-management/technical-design.md` §18. |

Each domain owns its own business rules and data — another domain that needs that data
reads it through the owning domain's interface (`Architecture-Principles.md` §5), it never
maintains its own copy.

---

## 10. Data Lifecycle

**Creation → Validation → Usage → Update → Archive → Retention → Deletion.**

- **Creation** — a record is created only through its owning domain's business logic
  (`coding-standards.md` §5), never inserted directly.
- **Validation** — request and business validation both apply before creation
  (`coding-standards.md` §11).
- **Usage** — a record is read and referenced by other domains through defined interfaces
  (§9), for as long as it's active.
- **Update** — changes are made through the owning domain, with audit fields recording who
  and when (`database-standards.md` §8).
- **Archive** — business- and audit-significant records are soft-deleted, not removed, once
  no longer active (`database-standards.md` §9).
- **Retention** — how long archived data is retained is a compliance/business decision, set
  per entity where a real requirement exists — not assumed uniformly here.
- **Deletion** — permanent deletion is reserved for genuinely disposable data with no audit
  requirement (`database-standards.md` §9); business-significant data is never permanently
  deleted as a routine operation.

---

## 11. Multi-Tenant Data Isolation

Principles only — implementation is `database-standards.md` and (once authored)
`security-architecture.md`:

- **Each Hotel owns its own operational data** — Halls, Bookings, Staff, and Payments
  belonging to one Hotel are never visible to another Hotel.
- **Platform Administrators have platform-wide visibility**, by design, distinct from any
  single Hotel's access (`Architecture-Principles.md` §6).
- **Hotels cannot access another Hotel's operational data**, under any circumstance,
  including through indirect queries or aggregate views not specifically designed to be
  cross-tenant.
- **Tenant boundaries are respected at every layer** that touches data — this is a data
  architecture guarantee, not only an API-layer check (`api-standards.md` §13).

---

## 12. Data Governance

- **Data quality, accuracy, completeness, consistency** — the responsibility of each
  domain's owning business logic (§9), verified through the validation standards already
  established (`coding-standards.md` §11, `testing-standards.md` §8).
- **Ownership** — §9, exhaustively.
- **Traceability** — every record's origin is knowable (§10's Creation stage plus audit
  fields, `database-standards.md` §8).
- **Retention** — §10.
- **Compliance** — data handling follows `Project-Constitution.md` §8 (Data privacy) as the
  baseline; specific regulatory compliance requirements (e.g. payment data standards) are
  addressed per domain as they're identified, not assumed uniformly.

---

## 13. Data Security Classification

| Classification | Examples |
|---|---|
| **Public** | Hall names, Hotel names, published Amenities — data intended for anyone to see. |
| **Internal** | Booking statuses, operational Staff assignments — visible within the Platform to authorized roles, not published externally. |
| **Confidential** | Customer contact details, Hotel financial summaries — visible only to the owning party and roles with a legitimate need. |
| **Restricted** | Payment credentials, password hashes, authentication tokens — never exposed in any response body (`api-standards.md` §19), accessible only to the specific system component that requires them. |

Every entity in §4 is assigned a classification as part of its Technical Design — no entity
is treated as Public by default (`Architecture-Principles.md` §7, Secure defaults).

---

## 14. Audit Data

**User actions, Booking actions, Payment actions, administrative changes, and system
events** are recorded as Audit Records (§4). Audit data matters because it's what makes
`Project-Constitution.md` §8's Auditability principle real rather than aspirational — a
disputed Booking, a Payment discrepancy, or an administrative access change all need a
reliable, tamper-evident record of who did what and when, independent of whether the
current state of the record still shows it.

---

## 15. Reporting Data

**Operational reports, management reports, Platform analytics, and business intelligence**
are derived, read-oriented views over the domains above (Reporting domain, §3).
**Reporting never modifies transactional data** — it reads from it, at whatever freshness
its own Technical Design specifies, and never becomes a side-channel write path that
transactional business logic (§9) would need to account for.

---

## 16. Data Flow Overview

```
Customer
    ↓
Booking
    ↓
Payment
    ↓
Confirmation
    ↓
Notification
    ↓
Reporting
```

A Customer's action creates a Booking; a successful Payment confirms it; confirmation
triggers a Notification to both the Customer and the Hotel; the completed transaction feeds
Reporting. Every arrow above crosses a domain boundary (§9) through that domain's owning
interface — this diagram is the business-level counterpart to the technical communication
paths described in `system-architecture-overview.md` (once authored).

---

## 17. Future Scalability

This model is deliberately structured so growth doesn't require restructuring
(`Development-Roadmap.md` §2, Design for Extensibility):

- **Additional Hotels and Halls** — the model already assumes many, from the Booking
  domain's design (§5) onward; no change needed to add more.
- **Future payment providers** — the Payment domain (§9) owns payment data independent of
  which provider processes it, per `Architecture-Principles.md` §11 (provider abstraction).
- **Future integrations** — new external data sources join as new Reference Data (§8) or
  new domains (§3), never by silently extending an existing domain's meaning.
- **Additional business modules** — a new approved module (`Development-Roadmap.md` §9)
  adds a new domain here, following the same ownership (§9) and classification (§13)
  pattern already established.
- **International expansion** — Currencies, Countries, and Languages are already modeled as
  Master/Reference Data (§6, §8), not hardcoded assumptions.

---

## 18. AI Development Rules

This restates and is governed by `Project-Constitution.md` §4 and
`database-standards.md` §18 — see those for the canonical AI rules. Data-architecture-
specific additions only:

- **AI must respect approved business entities** (§4) — never introducing a new one without
  an approved Business Specification behind it.
- **AI must never invent a new entity without approval** — including entities the prompt's
  own illustrative examples might suggest but that aren't yet approved (e.g. "Branch," §3).
- **AI must never duplicate a business concept** already owned by a domain (§9).
- **AI must follow approved terminology** — `Project-Glossary.md`, exactly.
- **AI must preserve domain boundaries and logical relationships** (§5, §9) — never
  collapsing two domains' data together for convenience.

---

## 19. Review Checklist

- [ ] Business domains defined and traceable to approved modules (§3).
- [ ] Entities identified with business purpose only, no physical detail (§4).
- [ ] Relationships documented conceptually (§5).
- [ ] Ownership defined per domain (§9).
- [ ] Lifecycle defined (§10).
- [ ] Security classification completed for every entity (§13).
- [ ] Governance principles documented (§12).
- [ ] Multi-tenant principles respected (§11).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.2 | 2026-08-25 | Ahmed | §9 corrected — "Hall inventory data" removed from the Hotel Domain row and reassigned to a new Hall Domain row ("Hall inventory data, including Hall attributes, availability, and amenities"), resolving the staleness Hotel Management's Technical Design §18 (Item 5) already flagged: §3 of this document lists Hall as its own business domain, and `Project-Glossary.md` defines a Hall as inventory belonging to a Hotel, not part of the Hotel's own data. No business rule changed; this is an architecture-layer correction only, surfaced during Hall Management's Business Discovery and Business Specification (`04-hall-management/business-specification.md`, `Approved` v1.1). Hotel Domain narrowed to Hotel profile and application/approval/lifecycle status only. |
| 1.1 | 2026-08-10 | Ahmed | §9 corrected — "Hotel approval status" reassigned from the Administration Domain to the Hotel Domain (Hotel Management, Module 3), resolving a data-ownership conflict discovered during Hotel Management's Technical Design review. Administration Domain narrowed to cross-tenant administrative data only; it performs the review action against Hotel Management's data through Hotel Management's defined interface, per that module's Technical Design §7. No business decision changed — `BDR-003` never assigned data ownership; this corrects an architecture-layer inference that had gone beyond it. Module 1's Technical Design corrected to match in the same pass. |
| 1.0 | 2026-08-03 | Ahmed | Initial approved Data Architecture |
