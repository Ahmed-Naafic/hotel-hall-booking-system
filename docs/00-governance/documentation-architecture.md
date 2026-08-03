---
title: "Documentation Architecture"
document_type: Governance
status: Draft
owner: Ahmed (Project Lead / Business & Technical Architect)
last_updated: 2026-08-02
version: 3.7
---

# Documentation Architecture
## Hotel Hall Booking Management System

This document is the constitution of the project's documentation system. It defines every
document category the project uses, why each one exists, when it is used, whether it is
mandatory, who owns it, and what later documents depend on it. Every other document in
`docs/` is subordinate to the rules defined here.

This document does not contain business rules, architecture decisions, or feature content.
It only defines the **structure and governance of documentation itself**.

> **v2.0 note:** This structure was deliberately trimmed from a larger first draft. The
> project charter and methodology content now live in `docs/Project-Overview.md` instead of
> as separate documents, and several thin, overlapping, or speculative documents were merged
> or removed — see §16. The goal is the minimum set of documents that still fully supports
> the Business → Architecture → Quality → Implementation methodology for a 3-person,
> AI-assisted team. Add a document back only when there is a real, current need for it.
>
> **v3.0 note:** `docs/Project-Constitution.md`, `docs/Documentation-Map.md`, and
> `docs/Team-Management.md` have since been added as root-level foundational documents.
> `Team-Management.md` fully absorbs what were planned as `00-governance/team-and-workflow.md`
> and `00-governance/feature-status-board.md` — both were removed before being authored, in
> favor of that single document. Every reference below has been updated accordingly.
>
> **v3.1 note:** `docs/Development-Lifecycle.md` has been added — the authoritative,
> phase-by-phase (0–12) breakdown of the process this document describes only at a summary
> level in §4–§5 below. It also corrected an inconsistency: §4 previously implied Ahmed could
> self-review his own documentation via a checklist; that contradicted the no-self-review
> rule stated in `Project-Constitution.md` and `Team-Management.md`. Business Specification
> and Technical Design reviews are now explicitly assigned to Mohamed or Abukar, matching
> `Development-Lifecycle.md` Phases 3, 5, and 6.
>
> **v3.2 note:** `docs/Development-Roadmap.md` and `docs/Decision-Making-Principles.md` have
> been added as root-level documents (execution planning and decision governance,
> respectively). `docs/00-governance/glossary.md` has also been promoted to root-level
> `docs/Project-Glossary.md`, for the same reason `team-and-workflow.md` and
> `feature-status-board.md` were promoted in v3.0 — it's a foundational, constantly-referenced
> document, not a narrow governance policy. Every reference below has been updated.
>
> **v3.3 note:** `docs/04-business/business-decision-register.md` has been added as a
> business-layer document alongside `stakeholders-and-personas.md` — unlike the root-level
> promotions above, it stays inside `04-business/` because it's specifically a business
> artifact Business Specifications reference, not a cross-project governance document.
>
> **v3.4 note:** `docs/02-architecture/architecture-principles.md` has been added — un-merged
> from `system-architecture-overview.md` (see §16) now that it has grown into a substantial,
> 16-section document. It stays inside `02-architecture/`, not root, for the same reason
> `business-decision-register.md` stays inside `04-business/` — it's a layer-specific
> document, not cross-project governance. This also produced the project's first real
> ADR (`ADR-0001`, initial technology stack) and populated `decision-log.md` and
> `02-architecture/technology-stack.md` for the first time — both had been unauthored stubs.
>
> **v3.5 note:** `docs/02-architecture/folder-structure.md` has been added — the official
> repository layout, superseding the "indicative shape" placeholder that previously lived in
> `Project-Overview.md` §14. Authoring it surfaced a scope question not previously tracked
> (whether Hotels may operate multiple physical branches), now recorded as `BDR-008`.
>
> **v3.6 note:** `docs/03-standards/naming-conventions.md` has been added — un-merged from
> `coding-standards.md` (see §16) now that it covers naming across every layer: files, code
> identifiers, the database, the API, environment variables, git, documentation, and tests.
> `coding-standards.md`, `api-standards.md`, `git-workflow-and-branching.md`, and
> `testing-standards.md` have each had their naming-specific language pointed there instead
> of restating it — all eight BDRs are now `Approved`, so `naming-conventions.md` §4 states
> the module list (and the absence of a `branches` module, per `BDR-008`) as settled fact,
> not a pending question.
>
> **v3.7 note:** `docs/03-standards/api-standards.md`, `coding-standards.md`, and
> `database-standards.md` have all been authored. `database-standards.md` is a genuinely
> new addition to the Standards Layer, not an un-merge — schema-design guidance
> (keys, relationships, constraints, migrations) grew beyond what `Architecture-Principles.md`
> §9's principles and `coding-standards.md` §6's query patterns already covered.
> Authoring the API contract also surfaced one small inconsistency, now fixed:
> `naming-conventions.md` §9's pagination example used `pageSize`; the formal contract in
> `api-standards.md` §10 uses `limit` — `naming-conventions.md` has been updated to match.

---

## 1. Methodology Recap

The project follows a strict, non-negotiable sequence, detailed in `docs/Project-Overview.md`:

```
Business First → Architecture → Quality → Implementation
```

For every feature: `Business Specification → Technical Design → Implementation Plan →
Approval → Implementation → Validation`. Implementation is always the last step.

Three standing rules govern all AI-assisted and human work on this project (full detail in
`docs/01-ai-governance/ai-governance.md`):

1. **AI must never invent business rules.**
2. **AI must never change architecture without approval** (via an ADR in `02-architecture/adr/`).
3. **AI must never skip documentation.**

---

## 2. Folder Structure

```
docs/
├── Project-Overview.md                    First document to read; vision, scope, philosophy, status
├── Project-Constitution.md                 Highest authority; non-negotiable rules
├── Documentation-Map.md                    Navigation guide across all documents
├── Team-Management.md                      Team roles, workflow, review rules, feature register
├── Development-Lifecycle.md                Mandatory phase-by-phase (0–12) process every feature follows
├── Development-Roadmap.md                  Execution plan: sequence, dependencies, milestones
├── Decision-Making-Principles.md           Decision categories, authority, process, evaluation criteria
├── Project-Glossary.md                     Official dictionary of business and project terms
├── README.md                               Navigation index
├── 00-governance/                          Project governance & process
├── 01-ai-governance/                       Rules for AI-assisted work
├── 02-architecture/                        System-wide architecture (incl. adr/)
├── 03-standards/                           Engineering & design standards
├── 04-business/                            Stakeholders/personas, business decision register, per-module Business Specs
│   └── modules/<01..14-module-slug>/business-specification.md
├── 05-technical-design/                    Per-module Technical Design docs
│   └── modules/<01..14-module-slug>/technical-design.md
├── 06-implementation-planning/             Per-module Implementation Plans
│   └── modules/<01..14-module-slug>/implementation-plan.md
├── 07-validation-and-qa/                   Test strategy, review checklists, per-module validation
│   └── modules/<01..14-module-slug>/validation-report.md
└── 08-templates/                           Blank templates for the four per-module document types
```

The 14 major features each get an identically-numbered slug folder under `modules/` in
`04-business`, `05-technical-design`, `06-implementation-planning`, and
`07-validation-and-qa`:

`01-authentication-and-account-management`, `02-customer-management`, `03-hotel-management`,
`04-hall-management`, `05-booking-management`, `06-calendar-and-scheduling-management`,
`07-payment-management`, `08-event-management`, `09-staff-management`,
`10-communication-and-notification-management`, `11-reviews-and-ratings-management`,
`12-reports-and-analytics`, `13-administration-and-platform-management`,
`14-security-and-access-control`.

These 56 per-module documents (4 types × 14 modules) are **not** candidates for further
trimming — they are the actual mechanism of the documentation-first methodology. Everything
else in this architecture exists only to support producing and approving those 56 documents
consistently.

There is deliberately **no `09-releases/` folder yet.** Versioning and release-notes
documentation is premature before there is a first release to version; it will be added when
the project nears its first release, not before.

---

## 3. Document Lifecycle & Status Model

| Status | Meaning |
|---|---|
| `Not Started` | Placeholder only; no content authored |
| `Draft` | Author actively writing; not ready for review |
| `In Review` | Submitted to the designated reviewer(s) |
| `Changes Requested` | Reviewer sent it back |
| `Approved` | Reviewer sign-off recorded; implementation may begin (if applicable) |
| `Implemented` | Corresponding code has been merged (Implementation Plans / features only) |
| `Deprecated` | Superseded; kept for history, linked from its replacement |

A feature may not move from Implementation Plan to actual coding while its Business
Specification, Technical Design, or Implementation Plan is anything other than `Approved`.
Tracked centrally in the Feature Assignment Register, `docs/Team-Management.md` §7.

---

## 4. Ownership & Review Model (applies to every document below)

- **Author** of Business Specification, Technical Design, and Implementation Planning
  documents: **always Ahmed**, regardless of who later implements the feature.
- **Assignment for implementation** follows Round Robin once documentation is approved:
  Ahmed → Mohamed → Abukar → Ahmed → ...
- **Review of implementation:**
  - If Ahmed did **not** implement the feature → **Ahmed** performs final review.
  - If Ahmed **did** implement the feature → **Mohamed or Abukar** performs the review.
  - No developer reviews their own implementation, ever.
- **Review of documentation:** Ahmed authors Business Specs / Technical Designs /
  Implementation Plans, but never approves his own — each is independently reviewed by
  **Mohamed or Abukar** against `docs/07-validation-and-qa/review-checklists.md` before
  status becomes `Approved`. The same no-self-review rule applies to documentation as to
  implementation.

Full detail on roles: `docs/Team-Management.md`. Full detail on the phase-by-phase process,
including entry/exit criteria and failure handling: `docs/Development-Lifecycle.md`.

---

## 5. Document Dependency Chain (end-to-end)

```
Project-Overview.md, 00-governance/*
        │
        ▼
02-architecture/* (architecture-principles, system-architecture-overview, technology-stack,
                    domain-model, data-architecture, security-architecture, mobile-application-architecture)
        │
        ▼
03-standards/* (coding, naming, API, testing, git, documentation, UI/UX & accessibility, security-coding)
        │
        ▼
04-business/stakeholders-and-personas.md, 04-business/business-decision-register.md
        │
        ▼
[per module] business-specification.md   ◄── MUST be Approved before next step
        │
        ▼
[per module] technical-design.md         ◄── MUST be Approved before next step
        │
        ▼
[per module] implementation-plan.md      ◄── MUST be Approved before next step
        │
        ▼
Round-Robin assignment → Implementation (code, outside docs/)
        │
        ▼
[per module] validation-report.md  (uses test-strategy.md + review-checklists.md)
        │
        ▼
Team-Management.md Feature Assignment Register updated
```

---

## 6. Governance Layer — `docs/00-governance/`

Team roles, the assignment/review workflow, and the live per-feature register live in
`docs/Team-Management.md` at the docs root, not in this folder — see that document
directly. The project glossary similarly lives at `docs/Project-Glossary.md`, not in this
folder. This folder holds the remaining, narrower governance documents:

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `definition-of-ready-and-done.md` | Checklist a Business Specification must satisfy before Technical Design starts, **and** the checklist a feature must satisfy to be considered complete. | Two short, always-paired gates (entry gate for design, exit gate for delivery) kept in one place rather than two thin files. | Before Technical Design begins (Ready); before a validation report can be `Approved` (Done). | Yes | Ahmed | Technical Design docs; validation reports. |
| `change-management-policy.md` | Defines how already-approved documents (business, architecture, standards) may later be amended. | Approved documents aren't silently edited; changes need traceable justification. | Whenever an approved document needs modification after sign-off. | Yes | Ahmed | ADR process; decision-log. |
| `decision-log.md` | Chronological index of all Architecture Decision Records (ADRs) with status and links. | Single place to see what architectural decisions were made, when, and why — supports "no architecture change without approval." | Updated every time an ADR is created or its status changes. | Yes | Ahmed | Architecture docs; onboarding. |

---

## 7. AI Governance Layer — `docs/01-ai-governance/`

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `ai-governance.md` | One document covering: what AI may/may not do; the three hard guardrails (no invented business rules, no unapproved architecture change, no skipped documentation); the expected human/AI collaboration workflow at each stage; the checklist used to verify AI output before human review; and what context must be supplied to an AI session. | A 3-person team doesn't need five separate AI policy documents that are always read together — one coherent document is easier to keep current and actually read. | Before any AI-assisted session; referenced by the reviewer whenever AI-drafted output is submitted for review. | Yes | Ahmed | `review-checklists.md`; every document an AI assists in drafting. |

---

## 8. Architecture Layer — `docs/02-architecture/`

System-wide, not per-feature; every Technical Design document must conform to these.

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `architecture-principles.md` | The non-negotiable architectural philosophy and principles (modularity, layering, dependency rules, multi-tenancy, security, API, database, storage, integration, performance, error handling, AI, and evolution principles) every architecture decision, Technical Design, and Implementation Plan must comply with. | Originally planned as a subsection of `system-architecture-overview.md`; separated into its own document once it grew to the depth a Technical Design author actually needs — see §16. | Read before authoring or reviewing any Technical Design; referenced in every architecture and implementation review. | Yes | Ahmed | Every Technical Design document; every ADR. |
| `system-architecture-overview.md` | The "big picture" architecture document: overall system shape (mobile + web + backend + how the modules relate), system-wide non-functional requirements (performance, availability, scalability), how the system integrates with external services, and the deployment/infrastructure model. Does **not** cover architecture principles — see `architecture-principles.md` above. | Consolidates what would otherwise be four thin, always-cross-referenced documents (NFRs, integration, infra, overall shape) into the one place a Technical Design author checks first. | Written before any Technical Design; revisited on major architecture change (via ADR). | Yes | Ahmed | Every Technical Design document; every Implementation Plan. |
| `technology-stack.md` | Approved languages, frameworks, cloud services, and libraries. | Kept separate from the overview because it changes on its own schedule (tooling decisions) and is referenced constantly and independently, incl. directly from `docs/Project-Overview.md`. | Consulted before/during every Technical Design. | Yes | Ahmed | Every Technical Design; coding standards. |
| `folder-structure.md` | The official repository structure — feature-based, not layer-based — for the backend, both mobile apps, and the web app, plus naming and ownership rules. | Operationalizes `architecture-principles.md` §3–§5 at the level of actual folders and files; kept separate because it's referenced independently by every Implementation Plan, not just Technical Designs. | Before authoring any Implementation Plan; whenever adding a new module or deciding where code belongs. | Yes | Ahmed | Every Implementation Plan; every module's actual folder layout once implementation begins. |
| `domain-model-and-bounded-contexts.md` | Maps the 14 major features to domain entities and bounded contexts, and defines their relationships (e.g. Booking ↔ Hall ↔ Payment). | Prevents overlapping ownership of the same business concept across modules — substantial enough to warrant its own document. | Consulted when a Technical Design defines entities or module boundaries. | Yes | Ahmed | Data architecture; every module's Technical Design. |
| `data-architecture.md` | Data storage strategy, per-module data ownership, cross-module data access rules, and multi-tenant data isolation between hotels. | Ensures per-module data decisions in Technical Designs don't conflict, duplicate, or leak across hotel tenants. | Consulted during Technical Design for any module touching persisted data. | Yes | Ahmed | Every Technical Design; security architecture. |
| `security-architecture.md` | System-wide security model: authN/authZ, tenant isolation, data protection, secrets handling. | Security must be designed in, not bolted on per feature — kept as its own document given the platform handles payments and multi-tenant hotel data. | Consulted by every Technical Design; mandatory for Auth, Payment, and Security & Access Control modules. | Yes | Ahmed | Security & Access Control module; security-coding-standards.md. |
| `mobile-application-architecture.md` | Architecture of the Customer app and the Hotel Manager app (navigation, state, offline behavior, shared components, API consumption pattern). | The two mobile apps are the primary interfaces and need one coherent architecture both follow — includes what would otherwise be a separate "API architecture" document, since API shape is driven by what the apps need. | Consulted by every module's Technical Design that has UI or an API surface. | Yes | Ahmed | UI/UX standards; API standards; every Technical Design with a UI or API component. |
| `adr/0000-adr-template.md` | Template for recording a single architecture decision (context, options, decision, consequences). | Makes "AI must never change architecture without approval" concrete and auditable — copy this template, don't invent a new format each time. | Copied whenever an architecture decision must be proposed or changed. | Yes (process is mandatory; individual ADRs are created as needed) | Ahmed (approver of every ADR) | `decision-log.md`; any architecture doc it amends. |

---

## 9. Standards Layer — `docs/03-standards/`

Cross-cutting rules every Technical Design and Implementation must follow.

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `coding-standards.md` | Language/style conventions, project structure, code quality bar. Does **not** cover naming — see `naming-conventions.md` below. | Keeps code from three different authors (plus AI) consistent and reviewable. | Referenced during every implementation and implementation review. | Yes | Ahmed | Implementation review checklist. |
| `naming-conventions.md` | Official naming standards across documentation, code, the database, the API, git, infrastructure, and testing. | Originally folded into `coding-standards.md`; separated into its own document once it grew to the depth every layer of the stack actually needs — see §16. | Read before naming anything new — a variable, a table, an endpoint, a branch, a file. | Yes | Ahmed | Every Technical Design and Implementation Plan; every commit. |
| `api-standards.md` | REST/API conventions: design, versioning, error format, pagination, and how API design decisions relate to the mobile-application-architecture. Naming specifics live in `naming-conventions.md` §9. | One document for "how we design and build APIs" rather than splitting architecture-level API concerns from standards-level API concerns. | Referenced whenever a Technical Design defines endpoints. | Yes | Ahmed | Every Technical Design. |
| `database-standards.md` | Schema-design standard: primary/foreign keys, table/relationship design, audit columns, soft delete, transactions, indexing, constraints, migrations, backup principles. Naming specifics live in `naming-conventions.md` §8; query-writing patterns live in `coding-standards.md` §6. | Not part of the original Standards Layer plan — added once schema-design guidance grew beyond what `Architecture-Principles.md` §9's principles and `coding-standards.md` §6's query patterns already covered; see §16. | Referenced whenever a Technical Design or migration defines or changes the schema. | Yes | Ahmed | Every Technical Design touching persisted data; every migration. |
| `git-workflow-and-branching.md` | Branching and commit *workflow* — when to branch, PR requirements, merge strategy, tied to the Round-Robin assignment. Branch/commit *naming format* lives in `naming-conventions.md` §11. | Makes the review/assignment rules in `docs/Team-Management.md` operational in the actual repo. | Every implementation task. | Yes | Ahmed | Implementation review checklist. |
| `testing-standards.md` | Required test types (unit, integration, E2E) and coverage expectations. Test *naming* lives in `naming-conventions.md` §13. | Ensures Validation Reports have a consistent, comparable basis across modules. | Referenced in Implementation Planning and Validation. | Yes | Ahmed | `test-strategy.md`; every validation report. |
| `documentation-standards.md` | Formatting, structure, and status-field conventions all `docs/` files must follow. | Keeps this now-smaller but still substantial document set navigable and consistent as it's actually written. | Referenced whenever any document in `docs/` is authored. | Yes | Ahmed | Every document in the repository. |
| `ui-ux-and-accessibility-standards.md` | Design system, interaction patterns, and minimum accessibility requirements for both mobile apps. | Accessibility is a constraint on the same design system, not a separate concern — one document keeps them consistent instead of risking drift. | Referenced by every Technical Design and Validation for UI-bearing modules. | Yes | Ahmed | Mobile-application-architecture.md; relevant Technical Designs and validation reports. |
| `security-coding-standards.md` | Secure-coding checklist (input validation, secrets handling, auth checks, dependency hygiene). | Operationalizes `security-architecture.md` at the code level — kept separate from that document because it's a developer-facing checklist, not an architectural decision. | Referenced during implementation and implementation review of every module. | Yes | Ahmed | Security architecture; implementation review checklist. |

---

## 10. Business Layer — `docs/04-business/`

### 10.1 Cross-cutting business documents

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `stakeholders-and-personas.md` | Who the system's stakeholders are (customers, hotel managers, staff, admins) and concrete personas for each. | Keeps business rules grounded in real user goals and named interests rather than abstract requirements — one document because stakeholders and personas are the same underlying "who," described at two levels of detail. | Referenced when writing any Business Specification. | Yes | Ahmed | Every Business Specification. |
| `business-decision-register.md` | Centralized, versioned record of every significant business decision (BDR-001, BDR-002, ...), independent of any single module. | Business decisions often span modules or predate any one module's Business Specification — without this register, the reasoning behind them would exist only in conversation or get silently absorbed into whichever document needed it first. | Consulted, and updated first, whenever a business decision is needed or a Business Specification would otherwise assume an unrecorded answer. | Yes | Ahmed | Every Business Specification that references a BDR ID. |

The commercial rationale (vision, mission, business problem, objectives, target users) is
covered in `docs/Project-Overview.md` and is **not** duplicated here as a separate
business-case document.

### 10.2 Per-module Business Specification — `modules/<module>/business-specification.md`

One instance per each of the 14 major features (folder slugs listed in §2).

| Field | Detail |
|---|---|
| **Purpose** | Defines, for one module, the business rules, user stories/scenarios, constraints, and acceptance criteria — in business language, with no technical design. |
| **Why it exists** | The *only* legitimate source of business rules for its module — enforces "AI must never invent business rules" positively. |
| **When used** | Authored first in every feature cycle, before any technical work starts on that module. |
| **Mandatory** | Yes — no exceptions. |
| **Owner** | Ahmed (author); reviewed via `docs/07-validation-and-qa/review-checklists.md`. |
| **Feeds into** | That module's `technical-design.md` (05), and indirectly its `implementation-plan.md` (06) and `validation-report.md` (07). |
| **Depends on** | `docs/Project-Overview.md`, `docs/04-business/stakeholders-and-personas.md`, `docs/04-business/business-decision-register.md`, `docs/Project-Glossary.md`. |

---

## 11. Technical Design Layer — `docs/05-technical-design/`

### Per-module Technical Design — `modules/<module>/technical-design.md`

| Field | Detail |
|---|---|
| **Purpose** | Translates the module's approved Business Specification into a concrete technical solution: data model, API contracts, module boundaries, sequence flows, and fit with system architecture. |
| **Why it exists** | Separates "what/why" (business) from "how" (technical) so each is reviewed by the relevant lens, and architecture conformance is checked before code is written. |
| **When used** | Authored after the module's Business Specification reaches `Approved` (Definition of Ready gate). |
| **Mandatory** | Yes. |
| **Owner** | Ahmed (author); reviewed via `docs/07-validation-and-qa/review-checklists.md` against `docs/02-architecture/*` and `docs/03-standards/*`. |
| **Feeds into** | That module's `implementation-plan.md` (06). |
| **Depends on** | The module's own `business-specification.md`; all documents in `02-architecture/`; relevant documents in `03-standards/`. |

---

## 12. Implementation Planning Layer — `docs/06-implementation-planning/`

### Per-module Implementation Plan — `modules/<module>/implementation-plan.md`

| Field | Detail |
|---|---|
| **Purpose** | Breaks the module's approved Technical Design into a sequenced build plan: tasks, scope, cross-module dependencies, effort. |
| **Why it exists** | Makes Round-Robin assignment and the review-assignment rule actionable — the document a developer is actually handed when assigned a feature. |
| **When used** | Authored after the module's Technical Design reaches `Approved`, immediately before Round-Robin assignment. |
| **Mandatory** | Yes. |
| **Owner** | Ahmed (author, regardless of who is later assigned to implement); reviewed via `review-checklists.md`. |
| **Feeds into** | Actual implementation (code, outside `docs/`); that module's `validation-report.md` (07). |
| **Depends on** | The module's own `technical-design.md`; `docs/02-architecture/folder-structure.md`; `docs/Team-Management.md`; `03-standards/git-workflow-and-branching.md`. |

---

## 13. Validation & QA Layer — `docs/07-validation-and-qa/`

### 13.1 Cross-cutting validation documents

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `test-strategy.md` | System-wide testing approach (test levels, environments, tooling, what "adequately tested" means) **and** how business stakeholders confirm a module meets its Business Specification (UAT). | Technical test strategy and business-facing UAT are both "how we know it works," reviewed together rather than as separate documents. | Consulted during Implementation Planning and Validation; UAT section run before release of a module. | Yes | Ahmed | Every validation report. |
| `review-checklists.md` | One document, three sections: the checklist to approve a Business Specification, the checklist to approve a Technical Design, and the checklist to approve a completed implementation. | Three checklists are always used at different points by the same reviewer role and change together — kept as one file instead of three near-empty ones. | Applied at each of the three approval gates described in §3–§4. | Yes | Whoever holds the reviewer role for that gate (§4) | Every document's approval event; every validation report. |

### 13.2 Per-module Validation Report — `modules/<module>/validation-report.md`

| Field | Detail |
|---|---|
| **Purpose** | Records the outcome of testing and review for a module: what was tested, results, defects found/resolved, sign-off against acceptance criteria. |
| **Why it exists** | Auditable evidence a feature is actually `Implemented`/`Done`, tying back to the Definition of Done. |
| **When used** | After implementation and review are complete for the module, before it's marked done in the Feature Assignment Register. |
| **Mandatory** | Yes. |
| **Owner** | The assigned implementation reviewer (§4); informed by `test-strategy.md` and `review-checklists.md`. |
| **Feeds into** | `docs/Team-Management.md` §7 (Feature Assignment Register). |
| **Depends on** | The module's `implementation-plan.md`; the module's `business-specification.md` (for acceptance criteria); `test-strategy.md`. |

---

## 14. Templates Layer — `docs/08-templates/`

Only templates for documents that are actually instantiated repeatedly (14 times each) are
kept. One-off documents (ADRs, checklists, the status board) don't get a separate template —
copy an existing example of that document instead once one exists.

| Document | Purpose | Why it exists | When used | Mandatory | Owner | Feeds into |
|---|---|---|---|---|---|---|
| `business-specification-template.md` | Blank, structured template for §10.2 documents. | Guarantees every Business Specification covers the same required sections, making review checklists meaningful. | Copied at the start of every module's Business Specification. | Yes | Ahmed | Every module's `business-specification.md`. |
| `technical-design-template.md` | Blank template for §11 documents. | Same rationale, technical layer. | Copied at the start of every module's Technical Design. | Yes | Ahmed | Every module's `technical-design.md`. |
| `implementation-plan-template.md` | Blank template for §12 documents. | Same rationale, planning layer. | Copied at the start of every module's Implementation Plan. | Yes | Ahmed | Every module's `implementation-plan.md`. |
| `validation-report-template.md` | Blank template for §13.2 documents. | Same rationale, validation layer. | Copied at the start of every module's Validation Report. | Yes | Ahmed | Every module's `validation-report.md`. |

The ADR template lives only in `02-architecture/adr/0000-adr-template.md` — it is not
duplicated here.

---

## 15. Worked Example: One Feature Through the Full Chain

Using **Booking Management** (module `05-booking-management`):

1. `04-business/modules/05-booking-management/business-specification.md` — Ahmed authors it,
   grounded in `Project-Overview.md` and `stakeholders-and-personas.md`. Goes through the
   Business Specification section of `review-checklists.md` → `Approved`.
2. `05-technical-design/modules/05-booking-management/technical-design.md` — Ahmed authors
   it, conforming to `architecture-principles.md`, `system-architecture-overview.md`,
   `domain-model-and-bounded-contexts.md`, `data-architecture.md`. Any new architectural
   decision (e.g. how holds/locks on a hall are
   handled) is proposed as an ADR and approved by Ahmed before the Technical Design can
   reference it. Reviewed via the Technical Design section of `review-checklists.md` →
   `Approved`.
3. `06-implementation-planning/modules/05-booking-management/implementation-plan.md` — Ahmed
   authors it, referencing `git-workflow-and-branching.md`. On approval, the feature's row in
   `docs/Team-Management.md` §7 moves to `Ready for Development` and Round Robin (§4 of that
   document) determines the next assignee.
4. The assignee implements the feature per `coding-standards.md`, `security-coding-standards.md`,
   `testing-standards.md`.
5. Implementation review follows the no-self-review rule from `docs/Team-Management.md` §5,
   using the Implementation section of `review-checklists.md`.
6. `07-validation-and-qa/modules/05-booking-management/validation-report.md` is completed
   against `test-strategy.md` and the module's own acceptance criteria.
7. The feature's row in `docs/Team-Management.md` §7 is updated to `Feature Accepted`.

This is the summary version. For the full phase-by-phase breakdown — including who reviews
each document, entry/exit criteria, and what happens if a review fails — see
`docs/Development-Lifecycle.md`.

---

## 16. What Was Removed From the Original Draft, and Why

The first draft of this architecture had ~30 non-module governance/architecture/standards
documents. That was trimmed to the set above because most of them either duplicated content
that now lives in `docs/Project-Overview.md`, or were thin enough that splitting them from a
closely related document added navigation overhead without adding clarity, or were
speculative documents with no near-term use:

- **Removed, superseded by `Project-Overview.md`:** `project-charter.md`, `methodology.md`.
- **Merged (multiple thin/related files → one):** team-roles-and-raci + workflow-and-review-process
  → `team-and-workflow.md` (v2.0) → since further absorbed, along with `feature-status-board.md`,
  into root-level `docs/Team-Management.md` (v3.0); definition-of-ready + definition-of-done →
  `definition-of-ready-and-done.md`; all 5 AI governance documents → `ai-governance.md`;
  architecture-principles + integration-architecture + infrastructure-and-deployment-architecture
  + non-functional-requirements → folded into `system-architecture-overview.md` (v2.0) →
  architecture-principles later separated back out into its own `architecture-principles.md`
  (v3.4) once it grew into a substantial, 16-section document in its own right — integration
  and infrastructure content remains folded into `system-architecture-overview.md`; api-architecture
  + api-design-standards → `api-standards.md`; naming-conventions → folded into
  `coding-standards.md` (v2.0) → later separated back out into its own
  `naming-conventions.md` (v3.6), the same pattern as architecture-principles.md above;
  ui-ux-design-standards + accessibility-standards →
  `ui-ux-and-accessibility-standards.md`; stakeholder-register + user-personas →
  `stakeholders-and-personas.md`; uat-plan → folded into `test-strategy.md`; the three review
  checklists → `review-checklists.md`.
- **Removed, redundant with `Project-Overview.md`:** `business-case.md`.
- **Removed, redundant with the single project glossary:** `business-glossary.md` (merged
  into `00-governance/glossary.md`, which was itself later promoted to root-level
  `docs/Project-Glossary.md` — see v3.2 note above).
- **Removed, duplicate:** `08-templates/adr-template.md` (the canonical copy lives in
  `02-architecture/adr/`).
- **Removed, speculative/YAGNI:** `review-checklist-template.md`,
  `feature-status-template.md` (only needed if the document taxonomy itself is extended —
  write them then, not now).
- **Removed entirely, premature:** `09-releases/` (`versioning-policy.md` and
  `release-notes/`) — there is nothing to version or release yet; add this folder back when
  the project approaches its first release.

The 56 per-module documents were **not** reduced — they are the point of the methodology,
not overhead on top of it.

---

## 17. Summary: What Is Mandatory vs. Optional

Everything in this architecture is mandatory except individual ADRs, which are created only
when an architecture decision actually needs to be made or changed.

---

*This document is governed by `docs/03-standards/documentation-standards.md` and is owned
by Ahmed. Any change to the structure defined here is a change to
project governance and must be explicitly approved by Ahmed, following
`docs/00-governance/change-management-policy.md`.*
