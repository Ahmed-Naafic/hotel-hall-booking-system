---
title: "Project Overview"
document_type: Foundational / Governance
status: Approved
version: 2.4
owner: Ahmed (Project Lead, Business Architect, Technical Architect)
last_updated: 2026-08-03
audience: Every human contributor and every AI assistant working on this project
---

# Project Overview
## Hotel Hall Booking Management System

> **This is the first document every developer and every AI assistant must read before
> touching this project.** It is subordinate to `docs/Project-Constitution.md`, the
> project's highest governance authority — if anything here conflicts with the
> Constitution, the Constitution wins. Conflicts with any other document are resolved in
> this document's favor until recorded through `docs/00-governance/change-management-policy.md`.

---

## 1. Welcome

Welcome to the Hotel Hall Booking Management System. This repository is built using a
**documentation-first, AI-assisted development methodology**: nothing is implemented until
it has been specified, designed, and planned in writing, reviewed, and approved.

Whether you are Ahmed, Mohamed, Abukar, a future team member, or an AI assistant picking up
a task, this document tells you what the system is, why it exists, how the team works, and
where to find the rest of the truth. Read it fully before opening any other document or
writing any code.

---

## 2. Project Vision

To become the platform hotels rely on to manage and monetize their event halls, and the
platform customers trust to find and book the right hall — anywhere, from a phone, without
a phone call to the front desk.

---

## 3. Project Mission

To provide a commercial, multi-hotel booking platform where:

- **Customers** can search, compare, reserve, and pay for hotel halls remotely through a
  mobile application, with clear availability, pricing, and confirmation at every step.
- **Hotel managers** can manage their halls, bookings, payments, staff, and events from a
  dedicated mobile application, without depending on manual processes or third-party tools.

---

## 4. Business Problem

Hotel halls (banquet halls, conference rooms, event spaces) are today typically booked
through phone calls, email, walk-ins, or generic spreadsheet-based tracking. This causes:

- **Lost revenue** from halls sitting unbooked simply because availability wasn't visible
  to a customer at the moment they were looking.
- **Double-bookings and scheduling errors** from manually coordinated calendars across
  multiple staff and multiple halls.
- **No unified system** for a hotel to manage halls, staff, payments, and events together —
  forcing managers to stitch together disconnected tools.
- **No self-service channel** for customers, who must reach a human during business hours
  to get an answer as simple as "is this hall free on this date."

This system solves that by giving hotels a dedicated management application and giving
customers a dedicated booking application, both backed by one real-time, shared platform.

---

## 5. Project Objectives

1. Let customers search, filter, and book hotel halls remotely, in real time, without
   manual coordination with hotel staff.
2. Let hotel managers manage halls, bookings, payments, staff, and events for their
   property (or properties) from a single mobile application.
3. Prevent double-booking and scheduling conflicts through a shared, authoritative calendar
   and booking engine.
4. Support multiple hotels on one platform, each operating independently with isolated
   data, while sharing the same underlying system.
5. Provide the operational tools hotels need around a booking: payments, staff assignment,
   event details, communication with customers, and reviews.
6. Give the platform operator (administration layer) the tools to onboard, support, and
   oversee hotels on the platform.
7. Build all of the above under a documentation-first process so the system remains
   understandable, auditable, and maintainable as it grows — including by AI assistants
   working from the documentation rather than tribal knowledge.

---

## 6. Scope

The system is a **commercial, multi-tenant mobile platform** consisting of:

- A **Customer mobile application** for searching, reserving, and booking hotel halls, and
  managing the customer's own account, bookings, payments, and reviews.
- A **Hotel Manager mobile application** for managing a hotel's halls, bookings, calendar,
  payments, staff, and events.
- A shared **backend platform** providing authentication, booking logic, payment
  processing, scheduling, notifications, reporting, and administration across all onboarded
  hotels.

Scope is defined by, and limited to, the **14 approved major modules**:

1. Authentication & Account Management
2. Customer Management
3. Hotel Management
4. Hall Management
5. Booking Management
6. Calendar & Scheduling Management
7. Payment Management
8. Event Management
9. Staff Management
10. Communication & Notification Management
11. Reviews & Ratings Management
12. Reports & Analytics
13. Administration & Platform Management
14. Security & Access Control

The platform is **multi-tenant at the hotel level**: it supports many independent hotels,
each managing its own halls, staff, bookings, and data, on shared infrastructure.

No feature outside these 14 modules is in scope unless it is added to this list through an
approved change to this document.

---

## 7. Out of Scope

The following are explicitly **not** part of this system unless a future, separately
approved decision brings them into scope:

- Booking of hotel *rooms* (guest room reservations) — this system is scoped to **halls**
  (banquet/event/meeting spaces), not overnight room inventory.
- Point-of-sale, restaurant, or in-hotel retail systems.
- Public marketplace features unrelated to hall booking (e.g. general travel booking,
  flights, transport).
- Hardware integrations (door locks, IoT, on-premise kiosks).
- Non-mobile client applications for **Customers or Hotel Managers** — both remain
  mobile-application-first (Flutter). **The one approved exception:** a React + Vite web
  dashboard for **Platform Administrator** use only (`Administration & Platform
  Management`), confirmed by `BDR-007` (`docs/04-business/business-decision-register.md`)
  — not a public web app, and not available to Customers or Hotel Managers.
- Any business rule, workflow, or module not traceable to one of the 14 modules above or to
  an approved Business Specification.

---

## 8. Target Users

| User Type | Description | Primary Interface |
|---|---|---|
| **Customer** | An individual or organization searching for and booking a hotel hall for an event. | Customer mobile application |
| **Hotel Manager** | Manages one hotel's halls, bookings, staff, payments, and events. | Hotel Manager mobile application |
| **Hotel Staff** | Operates under a Hotel Manager; assigned to bookings/events per staff management rules. | Hotel Manager mobile application (scoped access) |
| **Platform Administrator** | Operates the platform itself: onboards hotels, oversees platform health, handles escalations. | Administration & Platform Management tooling |

Detailed personas live in `docs/04-business/stakeholders-and-personas.md`.

---

## 9. Development Philosophy

The project follows a strict, sequential methodology:

```
Business First → Architecture → Quality → Implementation
```

Concretely, for every one of the 14 modules and every feature within them:

```
Business Specification → Technical Design → Implementation Plan → Approval → Implementation → Validation
```

**Implementation is always the last step.** No module skips a stage, and no stage begins
before the one before it has reached `Approved` status. This is not a preference — it is
how the project is governed. Full detail is in
`docs/00-governance/documentation-architecture.md` and `docs/Team-Management.md`.

---

## 10. AI Development Philosophy

This project is built **AI-assisted**. AI (including the assistant reading this document
right now) is expected to draft documentation, design technical solutions, and write code —
but always inside the following boundaries, detailed fully in `docs/01-ai-governance/`:

- **AI must never invent business rules.** Every business rule must trace back to an
  approved Business Specification. If a rule is needed but not yet specified, the correct
  action is to raise the gap, not to assume an answer.
- **AI must never change architecture without approval.** Architectural decisions are
  proposed as ADRs (`docs/02-architecture/adr/`) and require Ahmed's explicit approval
  before they may be relied upon.
- **AI must never skip documentation.** No code is generated for a feature that lacks an
  Approved Business Specification, Technical Design, and Implementation Plan.
- AI output is reviewed like any other contributor's output — against
  `docs/01-ai-governance/ai-governance.md` and the same review/no-self-review
  rules that apply to human work.

AI is a force multiplier for the documentation-first process, not an exception to it.

---

## 11. Documentation-First Philosophy

No feature may be implemented without approved documentation. Documentation is not a
by-product of building this system — it *is* the specification the system is built from.
This exists because:

- The system spans 14 modules, two mobile applications, and multiple hotels' worth of
  business rules — too much to hold reliably in memory or in conversation.
- Three engineers plus AI assistance are producing work in parallel; shared, approved
  documents are what keeps that work consistent.
- A commercial, multi-tenant platform must be auditable: for any behavior in the system,
  there must be a document explaining why it exists.

The full documentation system — every document type, its owner, and its dependencies — is
defined in `docs/00-governance/documentation-architecture.md`. That document is the
detailed companion to this one; this document tells you *what the project is*, that one
tells you *how the project is documented and governed*.

---

## 12. Team Structure

| Name | Roles |
|---|---|
| **Ahmed** | Project Lead, Business Architect, Technical Architect, Software Engineer, Lead Reviewer |
| **Mohamed** | Software Engineer |
| **Abukar** | Software Engineer |

**How the team works together:**

- Ahmed authors every Business Specification, Technical Design, and Implementation Plan for
  every module, and also implements features assigned to him.
- Once documentation for a feature is approved, implementation is assigned by **Round
  Robin**: Ahmed → Mohamed → Abukar → Ahmed → ...
- Ahmed performs the final implementation review for every feature **except** those he
  personally implements.
- When Ahmed implements a feature, **Mohamed or Abukar** performs the implementation
  review.
- **No one reviews their own implementation.**

Full RACI, workflow, and the live per-feature assignment register live in
`docs/Team-Management.md`.

---

## 13. Technology Stack

The technology stack was approved via **ADR-0001** (`docs/02-architecture/adr/0001-initial-technology-stack.md`).
Full detail, including how the stack is changed later, lives in
`docs/02-architecture/technology-stack.md` — that document is authoritative; this table is a
summary.

| Layer | Choice |
|---|---|
| Customer & Hotel Manager mobile applications | Flutter |
| Web frontend | React + Vite — Platform Administrator dashboard only, confirmed by `BDR-007` |
| Backend / API framework | Node.js + Express.js |
| Database | PostgreSQL, via Prisma ORM |
| Authentication | JWT + Refresh Tokens, RBAC |
| File / media storage | Provider-agnostic abstraction; Cloudinary default |
| API style | REST, documented with OpenAPI (Swagger) |
| Containerization | Docker |
| Push notifications | Firebase Cloud Messaging |
| Version control | GitLab |
| Payment processing provider (gateway) | **TBD** — `BDR-004` approved the payment *policy* (deposit + balance); the specific payment gateway/provider is a separate, still-open technical decision |
| Hosting / cloud provider | **TBD** |

**Note on the web frontend:** `BDR-007` (`docs/04-business/business-decision-register.md`)
confirmed React + Vite serves the Platform Administrator web dashboard only — reconciling
it with §7's mobile-application-first scope statement below, which now states this
explicitly as the one approved exception.

---

## 14. Repository Structure

The documentation structure (below) is finalized. The **code** structure is now finalized
too — approved in full in `docs/02-architecture/folder-structure.md` (feature-based, not
layer-based; see that document for the complete repository layout, module naming, and
ownership rules). This section is a summary, not the source of truth:

```
/
├── docs/                       Documentation (finalized — see §15)
├── apps/
│   ├── customer-mobile/        Flutter — Customer mobile application
│   ├── manager-mobile/         Flutter — Hotel Manager mobile application
│   └── admin-web/               React + Vite — Platform Administrator dashboard (BDR-007)
├── backend/                    Node.js + Express.js API, feature-based modules
├── shared/                     Code genuinely reusable across apps/backend
├── docker/                     Containerization
├── scripts/                    Repo- and environment-level scripts
└── README.md
```

Per **ADR-0003** (`docs/02-architecture/adr/0003-repository-initialization-scaffolding.md`),
the top-level skeleton above now exists — `apps/*`, `backend/`, `shared/`, `docker/`,
`scripts/` — each containing nothing but a placeholder `README.md`. No application code, no
module or feature subfolder, and no dependency manifest exists yet. Those are still created
only as each module reaches `Development-Lifecycle.md` Phase 8 (Implementation) — this
project remains implementation-code-free until then, by design (see §22, Current Project
Status).

---

## 15. Documentation Structure

The full `docs/` tree, its purpose, ownership, and dependency chain is defined in
`docs/00-governance/documentation-architecture.md`. Summary:

| Document / Folder | Contents |
|---|---|
| `Project-Constitution.md` | Highest authority; non-negotiable governing rules |
| `Documentation-Map.md` | Navigation guide — what to read for any given task |
| `Team-Management.md` | Team roles, workflow, review rules, live Feature Assignment Register |
| `Development-Lifecycle.md` | The mandatory 13-phase process every feature follows |
| `Development-Roadmap.md` | The execution plan — sequence, dependencies, milestones, release strategy |
| `Decision-Making-Principles.md` | Decision categories, authority, process, evaluation criteria, conflict resolution |
| `Project-Glossary.md` | The official dictionary — one meaning per business/technical/project term |
| `00-governance/` | Ready/done gates, change management, ADR decision log |
| `01-ai-governance/` | Rules governing AI-assisted work |
| `02-architecture/` | System-wide architecture + ADRs (incl. approved `architecture-principles.md`, `technology-stack.md`, `folder-structure.md`) |
| `03-standards/` | Coding, naming, API, testing, git, documentation, UI/UX & accessibility, security-coding standards |
| `04-business/` | Stakeholders/personas, business decision register, per-module Business Specifications |
| `05-technical-design/` | Per-module Technical Design documents |
| `06-implementation-planning/` | Per-module Implementation Plans |
| `07-validation-and-qa/` | Test strategy, review checklists, per-module Validation Reports |
| `08-templates/` | Blank templates for the four per-module document types |

There is no `09-releases/` folder yet — versioning and release notes are added when the
project nears its first release, not before.

Each of the 14 modules has an identically-named folder under `04-business/modules/`,
`05-technical-design/modules/`, `06-implementation-planning/modules/`, and
`07-validation-and-qa/modules/`.

---

## 16. Development Workflow

1. Ahmed authors a module's **Business Specification** → reviewed against the Business
   Specification section of `docs/07-validation-and-qa/review-checklists.md` → status
   `Approved`.
2. Ahmed authors the module's **Technical Design**, conforming to
   `docs/02-architecture/` and `docs/03-standards/` → reviewed → `Approved`.
3. Ahmed authors the module's **Implementation Plan** → reviewed → `Approved`.
4. The feature's row in `docs/Team-Management.md` §7 (Feature Assignment Register) moves to
   `Ready for Development`; implementation is assigned via Round Robin (Ahmed → Mohamed →
   Abukar → Ahmed → ...).
5. The assignee implements the feature per `docs/03-standards/`.
6. Implementation review is performed by Ahmed, unless Ahmed was the implementer — in
   which case Mohamed or Abukar reviews. No self-review, ever.
7. A **Validation Report** is completed against `docs/07-validation-and-qa/test-strategy.md`
   (which includes the UAT approach) and the module's own acceptance criteria.
8. The feature's status is updated to `Feature Accepted` in the Register.

This is the summary. Full detail on team/roles: `docs/Team-Management.md`. Full detail on
the process itself — all 13 phases, entry/exit criteria, and what happens when a review
fails: `docs/Development-Lifecycle.md`.

---

## 17. Quality Principles

- A feature is not "done" until it meets the Definition of Done in
  `docs/00-governance/definition-of-ready-and-done.md`:
  implemented, tested, documented, and reviewed.
- Every module is tested per `docs/03-standards/testing-standards.md` and validated per
  `docs/07-validation-and-qa/test-strategy.md` before being marked complete.
- Consistency across modules is enforced through shared standards
  (`docs/03-standards/`), not left to individual preference — this matters because three
  engineers and AI assistance are contributing to the same codebase.
- Every implementation is reviewed by someone other than its author, without exception.
- Documentation quality is held to the same bar as code quality: see
  `docs/03-standards/documentation-standards.md`.

---

## 18. Security Principles

- Security is designed in at the architecture level (`docs/02-architecture/security-architecture.md`),
  not added after the fact.
- The platform is **multi-tenant**: each hotel's data must be strictly isolated from every
  other hotel's data. No module may assume single-tenant behavior.
- Authentication, authorization, and role-based access apply consistently across both
  mobile applications and all 14 modules — governed by the **Security & Access Control**
  module and `docs/03-standards/security-coding-standards.md`.
- Payment handling follows the strictest applicable standard for the eventual payment
  provider (e.g. PCI-DSS-aligned practices) — finalized in the Payment Management module's
  Technical Design.
- Staff and administrator access follows least-privilege: a Hotel Manager, Hotel Staff
  member, and Platform Administrator each see and can act on only what their role requires.
- Every implementation review includes a security check per the Implementation section of
  `docs/07-validation-and-qa/review-checklists.md`.

---

## 19. AI Usage Rules

Restated from §10 for emphasis, since this is the section most likely to be checked
directly before an AI-assisted task begins:

1. AI must never invent business rules — only implement what an approved Business
   Specification states.
2. AI must never change or introduce architecture without an approved ADR.
3. AI must never skip a documentation stage — no code without an Approved Business
   Specification, Technical Design, and Implementation Plan for that feature.
4. AI-generated output is subject to the same review and no-self-review rules as any human
   contributor's output.
5. AI must ground its work in the actual current contents of `docs/`, not assumptions —
   per `docs/01-ai-governance/ai-governance.md`.

Full detail: `docs/01-ai-governance/`.

---

## 20. Success Criteria

**Documentation-phase success** (current phase):

- All governance, AI governance, architecture, and standards documents in
  `docs/00-governance/`, `docs/01-ai-governance/`, `docs/02-architecture/`, and
  `docs/03-standards/` are authored and `Approved`.
- Every one of the 14 modules has an `Approved` Business Specification before any Technical
  Design begins.

**Product-phase success** (later phases):

- A customer can search for, reserve, and complete payment for a hall through the Customer
  mobile application, for at least one onboarded hotel, end to end.
- A hotel manager can create and manage halls, view and manage bookings on a shared
  calendar, and process payments through the Hotel Manager mobile application.
- Multiple hotels operate on the platform simultaneously with verified data isolation.
- All 14 modules have reached `Implemented` status with passing Validation Reports.
- The platform administration layer can onboard a new hotel without engineering
  intervention.

---

## 21. Current Project Status

**Documentation Phase — Foundation.** The documentation architecture, this Project Overview,
`Project-Constitution.md`, `Documentation-Map.md`, `Team-Management.md`,
`Development-Lifecycle.md`, `Development-Roadmap.md`, `Decision-Making-Principles.md`,
`Project-Glossary.md`, and `docs/04-business/business-decision-register.md` have all been
created and approved. The register now has eight entries, all `Approved`.
`docs/02-architecture/architecture-principles.md`, `technology-stack.md` (ADR-0001), and
`folder-structure.md` are also approved. The repository has been initialized (ADR-0003): the
top-level skeleton exists (placeholder folders only), root configuration, and GitLab
standards are in place. The engineering workspace has since been initialized (ADR-0004): the
backend, Prisma, Admin Web, Customer Mobile, and Hotel Manager Mobile projects are
bootstrapped with dependencies installed and a minimal runnable entry point each, plus
development tooling (ESLint, Prettier) and development-only Docker configuration. No feature
code, business logic, API, or database model exists. No module's Business Specification has
yet been authored.

---

## 22. Current Phase

**Phase 0 — Governance & Foundational Documentation.**

Objective: establish the governance, AI governance, architecture, and standards layers
(`docs/00-governance/`, `docs/01-ai-governance/`, `docs/02-architecture/`,
`docs/03-standards/`) to the point where Business Specification work on the first module can
begin with a stable foundation underneath it.

---

## 23. Next Milestone

`architecture-principles.md`, `technology-stack.md` (ADR-0001), and `folder-structure.md`
are `Approved`. All eight initial Business Decisions (`BDR-001`–`BDR-008`) are now also
`Approved` — see `docs/04-business/business-decision-register.md`. Next: author the
remaining foundational architecture documents in `docs/02-architecture/` —
`system-architecture-overview.md`,
`domain-model-and-bounded-contexts.md`, `data-architecture.md`, `security-architecture.md`,
`mobile-application-architecture.md` — plus the remaining core governance documents,
`docs/00-governance/definition-of-ready-and-done.md` and
`docs/01-ai-governance/ai-governance.md`. Once those are `Approved`, begin the **Business
Specification for Module 1: Authentication & Account Management**, the first module of Wave
1 in `docs/Development-Roadmap.md` §4, as it is the dependency root for every other module
(a customer or hotel manager must be able to authenticate before any other module's flows
apply).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-01 | Ahmed | Initial approved Project Overview |
| 1.1 | 2026-08-01 | Ahmed | Updated cross-references after trimming the documentation architecture (see `docs/00-governance/documentation-architecture.md` §16) |
| 1.2 | 2026-08-01 | Ahmed | Updated cross-references for `Project-Constitution.md`, `Documentation-Map.md`, and `Team-Management.md`, which supersedes the planned `team-and-workflow.md` and `feature-status-board.md` |
| 1.3 | 2026-08-02 | Ahmed | Added `Development-Lifecycle.md` references (§15, §16, §21) |
| 1.4 | 2026-08-02 | Ahmed | Added `Development-Roadmap.md` references (§15, §21, §23) |
| 1.5 | 2026-08-02 | Ahmed | Added `Decision-Making-Principles.md` references (§15, §21) |
| 1.6 | 2026-08-02 | Ahmed | Replaced `00-governance/glossary.md` references with root-level `Project-Glossary.md` (§15, §21) |
| 1.7 | 2026-08-02 | Ahmed | Added `docs/04-business/business-decision-register.md` references (§15, §21) |
| 1.8 | 2026-08-02 | Ahmed | §13 technology stack approved via ADR-0001, TBD replaced with real values; §7 flags the unresolved web-frontend scope question as `BDR-007` |
| 1.9 | 2026-08-02 | Ahmed | §23 Next Milestone updated to reflect `architecture-principles.md` and `technology-stack.md` now being `Approved` |
| 2.0 | 2026-08-02 | Ahmed | §14 Repository Structure now points to the approved `docs/02-architecture/folder-structure.md` instead of an indicative placeholder tree |
| 2.1 | 2026-08-02 | Ahmed | All 8 initial Business Decisions (BDR-001–008) approved; §7, §13, §14, §21, §23 updated to reflect resolved decisions (notably: web dashboard confirmed as Platform-Administrator-only exception to mobile-first scope) |
| 2.2 | 2026-08-03 | Ahmed | §15 mentions `03-standards/naming-conventions.md` |
| 2.3 | 2026-08-03 | Ahmed | Per ADR-0003, §14 and §21 updated — repository initialized with an empty top-level skeleton; module/feature code still waits for each module's Phase 8 |
| 2.4 | 2026-08-03 | Ahmed | Per ADR-0004, §21 updated — engineering workspace (backend, Prisma, Admin Web, both Flutter apps, dev tooling, dev Docker config) initialized; module/feature implementation still waits for each module's Phase 8 |
