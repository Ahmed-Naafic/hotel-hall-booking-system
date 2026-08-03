---
title: "Project Glossary"
document_type: Business / Governance
status: Approved
version: 1.1
owner: Ahmed (Business Documentation Architect)
last_updated: 2026-08-02
---

# Project Glossary
## Hotel Hall Booking Management System

This document is the project's **official dictionary**. Every business, technical, and
project term used across `docs/` has exactly one official meaning, defined here. If another
document uses a term defined in this glossary, it means what this glossary says it means —
no document is free to redefine a term locally.

> **This document replaces the previously-planned `00-governance/glossary.md`.** It moves to
> the docs root alongside the project's other foundational governance documents, consistent
> with how `Team-Management.md`, `Development-Lifecycle.md`, and the others already replaced
> their originally-planned `00-governance/` locations.

**A note on scope:** where a term's exact allowed values or specific policy is itself a
business rule (an enumerated list of statuses, a deposit percentage, a cancellation window),
this glossary defines the *concept* only. The authoritative value is set in the relevant
module's Business Specification once it is written — this glossary does not invent business
rules, per `Project-Constitution.md` §4.

---

## 1. Purpose

Three engineers and AI assistance are producing business, technical, and process
documentation in parallel, across 14 (and eventually more) modules. Without one shared
dictionary, the same concept inevitably gets two names, or two concepts share one name, and
nobody notices until a Technical Design contradicts the Business Specification it's supposed
to implement.

This glossary exists so that a word means the same thing everywhere it appears — in a
Business Specification, a Technical Design, a code review comment, or an AI prompt — and so
that new terms are added deliberately instead of accumulating by accident.

---

## 2. Usage Rules

- **Every defined term has one official meaning.** If a term appears in this glossary, no
  other document may define it differently.
- **Synonyms are avoided unless explicitly listed** as an accepted synonym in §6 (Naming
  Rules). An undefined synonym for a defined term should not be introduced.
- **Business documents must reference glossary terms consistently** — a Business
  Specification uses "Booking," never "Reservation," for the same underlying concept (§6).
- **AI assistants must use glossary definitions** when generating documentation or code. If
  a needed term isn't defined here, the AI states the gap rather than inventing a
  definition, per `Project-Constitution.md` §4.
- **Capitalized, defined terms are distinct from the same word used generically.** "A
  Booking was cancelled" refers to the defined entity; "please book a time to talk" does
  not, and would not be capitalized.

---

## 3. Business Terms

| Term | Definition | Usage | Related Terms |
|---|---|---|---|
| **Platform** | The Hotel Hall Booking Management System as a whole — the shared, multi-tenant system connecting many Hotels with Customers through the Customer and Hotel Manager mobile applications. | Refers to the system itself, never a single Hotel. | Hotel, Platform Administrator |
| **Hotel** | A tenant on the Platform — a business entity that owns and manages one or more Halls, employs Staff, and is represented by at least one Hotel Manager account. | The unit of multi-tenancy; every Hall, Staff member, and Booking belongs to exactly one Hotel. | Hall, Hotel Manager, Staff |
| **Hall** | A bookable event space belonging to a Hotel — a banquet room, conference room, or similar venue. | The core sellable inventory of the Platform. Never refers to an overnight guest room — see `Project-Overview.md` §7 (Out of Scope). | Hotel, Hall Availability, Booking, Amenity |
| **Customer** | An individual or organization that searches for, books, and pays for Halls through the Customer mobile application. | The buyer side of every Booking. | Booking, Review |
| **Booking** | The official record of a Customer's reservation of a Hall for a specific date, time, and Event. | The central transaction of the Platform. Preferred term in all documentation — see §6. | Reservation, Booking Status, Hall, Event |
| **Reservation** | The everyday-language term for the act of a Customer securing a Hall; refers to the same underlying concept as a Booking, not a distinct entity. | May appear in customer-facing or informal text; official documentation uses **Booking**. | Booking |
| **Event** | The occasion a Customer is booking a Hall for (e.g. a wedding, conference, corporate meeting), described within a Booking. | An Event exists only in the context of a Booking. | Booking, Event Type |
| **Event Type** | A category describing the nature of an Event. | Used to classify Bookings for search, reporting, and hall suitability. The definitive list of supported Event Types belongs in the Event Management module's Business Specification, not here. | Event, Booking |
| **Booking Status** | The current state of a Booking within its lifecycle (e.g. held, confirmed, completed, cancelled). | Distinct from the project's Feature-level Status (§5) — this is a business-data status on a Booking record. The definitive set of values belongs in the Booking Management module's Business Specification and Technical Design. | Booking, Cancellation, No Show |
| **Hall Availability** | Whether a given Hall is free to be booked for a given date and time, as reflected on the shared calendar. | The core guarantee the Platform makes to prevent double-booking. | Hall, Booking |
| **Deposit** | A partial payment made by a Customer at the time of Booking to secure a reservation, applied toward the Full Payment. | Whether a Deposit is required, and its amount, is a Hotel-specific rule defined in the Payment Management module's Business Specification — not fixed here. | Full Payment, Refund |
| **Full Payment** | The complete amount due for a Booking, of which a Deposit (if required) is a part. | A Booking is not considered fully paid until Full Payment is received. | Deposit, Invoice, Receipt |
| **Refund** | The return of some or all of a payment already made for a Booking, typically following a Cancellation. | Refund eligibility and amount are governed by a Hotel's cancellation policy, defined in the relevant Business Specification. | Cancellation, Deposit |
| **Cancellation** | The act of ending a Booking before the Event takes place, by the Customer or the Hotel. | Distinct from No Show — a Cancellation is a deliberate, recorded action. | Booking Status, Refund, No Show |
| **No Show** | A Booking Status indicating the Customer did not cancel but also did not attend the Event as booked. | Distinct from Cancellation. | Booking Status, Cancellation |
| **Check-in** | The recorded moment a Customer's Event begins at the Hall, marking the Booking as in progress. | Relevant to Staff and Hotel Manager operational workflows. | Check-out, Event |
| **Check-out** | The recorded moment a Customer's Event concludes and the Hall is released back to availability. | Marks a Booking as completed. | Check-in, Hall Availability |
| **Amenity** | A feature, service, or piece of equipment associated with a Hall (e.g. projector, catering access, sound system). | The definitive list of supported Amenities belongs in the Hall Management module's Business Specification. | Hall |
| **Hotel Manager** | The primary account role representing a Hotel on the Platform, with authority to manage that Hotel's Halls, Bookings, Payments, Staff, and Events. | One of the four Target Users defined in `Project-Overview.md` §8. | Hotel, Staff |
| **Staff** | A Hotel employee account, created and managed by a Hotel Manager, with scoped access to operate on that Hotel's Bookings and Events. | Operates under a Hotel Manager. | Hotel Manager |
| **Platform Administrator** | The account role that operates the Platform itself — onboarding Hotels, overseeing platform health, and handling cross-tenant administration. | Distinct from any single Hotel's Staff or Hotel Manager. | Platform, Hotel |
| **Review** | Feedback submitted by a Customer about a Hotel or Hall following a completed Booking. | Requires a completed Booking to exist. | Rating, Booking |
| **Rating** | A quantified score submitted as part of a Review. | The specific scale belongs in the Reviews & Ratings Management module's Business Specification. | Review |
| **Promotion** | A time-limited or condition-based offer made available to Customers, intended to encourage Bookings. | Distinct from a Discount — a Promotion is the offer/campaign; a Discount is its effect on price. Whether Promotions are in scope for a given release is determined by the relevant Business Specification. | Discount, Booking |
| **Discount** | A reduction applied to the price of a Booking, whether from a Promotion, a Hotel-specific policy, or another defined mechanism. | — | Promotion, Full Payment, Invoice |
| **Invoice** | A formal request or record of the amount owed for a Booking, issued before or at the time of payment. | Distinct from a Receipt — an Invoice precedes payment. | Receipt, Full Payment |
| **Receipt** | A record confirming that a payment for a Booking has been made. | Issued after payment is received; distinct from an Invoice. | Invoice |
| **Notification** | A message sent to a Customer, Hotel Manager, or Staff member communicating information about a Booking, Event, or account. | Delivered through the Communication & Notification Management module; specific channels (push, SMS, email) are a technical decision, not fixed here. | Booking Status |

---

## 4. Project Terms

| Term | Definition |
|---|---|
| **Business Specification** | The approved document defining business rules, scenarios, and acceptance criteria for one Module — the only legitimate source of business rules for that Module. See `documentation-architecture.md` §10.2. |
| **Technical Design** | The approved document translating a Module's Business Specification into a technical solution. See `documentation-architecture.md` §11. |
| **Implementation Planning** | The phase, and the document it produces (the Implementation Plan), that breaks an approved Technical Design into a sequenced build plan. See `documentation-architecture.md` §12. |
| **Validation** | The phase (`Development-Lifecycle.md` Phase 10) confirming a completed feature works against its own Business Specification's acceptance criteria; also the name of its output, the Validation Report. |
| **Feature Acceptance** | The formal, final acceptance of a feature as complete — `Development-Lifecycle.md` Phase 11. |
| **Architecture Decision Record (ADR)** | A recorded architecture decision — context, options, decision, consequences. See `Decision-Making-Principles.md` §7. |
| **Business Decision Record (BDR)** | A recorded business decision — one entry (`BDR-001`, `BDR-002`, ...) in `docs/04-business/business-decision-register.md`. Records a business decision the same way an ADR records an architecture decision — the two are never interchangeable. |
| **Documentation-First Development** | The project's core methodology: no feature is implemented without approved documentation. See `Project-Constitution.md` §5. |
| **AI-Assisted Development** | The project's implementation method: AI drafts, designs, and implements under mandatory human review and the guardrails in `Project-Constitution.md` §4. |
| **Round Robin Assignment** | The fixed implementation rotation — Ahmed → Mohamed → Abukar → Ahmed → ... — used once a feature is Ready for Development. See `Team-Management.md` §4. |
| **Quality Gate** | A checkpoint a feature cannot pass without meeting defined exit criteria and, where applicable, review sign-off. See `Development-Lifecycle.md` §4. |
| **Module** | One of the major functional areas of the Platform (14 at project start; more may be added, see `Development-Roadmap.md` §2), each with its own Business Specification, Technical Design, Implementation Plan, and Validation Report. |
| **Feature** | A unit of work tracked through the Development Lifecycle. Typically one Module at the top level, but a Module may be split into multiple Features (`Team-Management.md` §7's ID suffix scheme, e.g. `M05.1`). |
| **Feature Request** | The captured proposal for a new Feature or change — `Development-Lifecycle.md` Phase 0. |
| **Wave** | A group of Modules in `Development-Roadmap.md` §4 that become buildable at the same point in the dependency graph. |
| **Milestone** | A defined point of project-wide progress in `Development-Roadmap.md` §6, measured by completion criteria, never a date. |
| **Escalation** | Raising an issue that can't be resolved at the working level to Ahmed. See `Team-Management.md` §11 and `Decision-Making-Principles.md` §9. |

---

## 5. Status Vocabulary

This project uses exactly **three** official status vocabularies. There is no fourth, and no
term outside these three lists is an official status.

**Document-level status** — one artifact's approval state, defined in
`documentation-architecture.md` §3:

| Status | Meaning |
|---|---|
| `Not Started` | Placeholder only; no content authored |
| `Draft` | Author actively writing; not ready for review |
| `In Review` | Submitted to the designated reviewer(s) |
| `Changes Requested` | Reviewer sent it back |
| `Approved` | Reviewer sign-off recorded |
| `Implemented` | Corresponding code has been merged (Implementation Plans / features only) |
| `Deprecated` | Superseded; kept for history, linked from its replacement |

**Feature-level status** — which phase of `Development-Lifecycle.md` a whole feature is
currently in, tracked in `Team-Management.md` §7:

```
Not Started → Feature Request → Assigned → Business Discovery → Business Review →
Technical Design → Technical Review → Implementation Planning → Ready for Development →
Implementation → Implementation Review → Validation & QA → Feature Accepted → Maintenance
```

Plus `On Hold` and `Cancelled`, which can apply at any point in that sequence. Full
definitions of each: `Development-Lifecycle.md` §2.

**Business Decision status** — the lifecycle a recorded business decision moves through,
defined in `docs/04-business/business-decision-register.md` §2:

```
Proposed → Under Discussion → Approved → Implemented → Superseded (if replaced) → Archived
```

Note this is the one place `Archived` **is** an official term — it applies to a Business
Decision Record whose subject is no longer relevant, not to a document or a feature (see the
table below).

**Terms this project does not use**, and their actual equivalents — listed here so nobody
introduces one of these as if it were official:

| Not used | Use instead |
|---|---|
| Planned | `Not Started` or `Assigned`, depending on context |
| In Progress | The specific phase name (e.g. `Implementation`), for precision |
| Under Review | The specific review phase (`Business Review`, `Technical Review`, or `Implementation Review`) |
| Accepted | `Feature Accepted` |
| Archived (of a document or feature) | `Deprecated` (documents); features do not archive — completed features move to `Maintenance`. `Archived` is only official for a Business Decision Record. |

---

## 6. Naming Rules

**Preferred term vs. avoided synonym:**

| Preferred | Never use instead | Why |
|---|---|---|
| Booking | Reservation (as if a separate entity) | Reservation is an accepted informal synonym (§3) but not a distinct concept — official documentation always says Booking |
| Hall | Room, Venue, Space | Room specifically implies an overnight guest room, which is out of scope (`Project-Overview.md` §7) |
| Hotel | Property | Hotel is the defined tenant term; Property is not used |
| Customer | Guest, User, Client | "Guest" may appear in operational, Event-day language (e.g. "guest count") but the account role is always Customer |
| Hotel Manager | Manager, Admin | "Admin" is reserved for Platform Administrator — using it for Hotel Manager would blur the tenant boundary that Security & Access Control depends on |

**Never treat as interchangeable**, even though related: Cancellation ≠ No Show; Invoice ≠
Receipt; Deposit ≠ Full Payment; Document-level Status ≠ Feature-level Status (§5); Module ≠
Feature (a Module may split into several Features, §4).

**Singular vs. plural:** defined entity terms (Hotel, Hall, Booking, Customer) are used in
the singular when referring to the concept generally — "a Hall's availability," not "Halls'
availability" — even when the underlying reality is a collection.

**Capitalization:** a defined term is capitalized when used in its specific glossary sense
("a Booking was cancelled"). The same word used generically outside project documentation is
not capitalized ("please book a time to talk").

---

## 7. Maintenance

- **New terms require Ahmed's approval** before being added, per `Decision-Making-Principles.md`
  §3 (Documentation Decisions) — the same authority pattern as every other governance
  decision.
- **Existing definitions are not changed without checking dependent documentation** — any
  Business Specification, Technical Design, or other document that references the term —
  per `docs/00-governance/change-management-policy.md`.
- **Obsolete terms are marked `Deprecated`**, with a pointer to their replacement, rather
  than deleted — this preserves the readability of older documents that used them, the same
  way `Deprecated` works for any other document (`documentation-architecture.md` §3).
- Every addition or definition change is recorded in this document's own Version History.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial approved Project Glossary; replaces the planned `00-governance/glossary.md` |
| 1.1 | 2026-08-02 | Ahmed | Added Business Decision status as a third official vocabulary (§5) and Business Decision Record (BDR) as a Project Term (§4), following the addition of `docs/04-business/business-decision-register.md` |
