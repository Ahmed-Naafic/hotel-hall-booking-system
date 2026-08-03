---
title: "Documentation Map"
document_type: Navigation Guide
status: Approved
version: 2.0
owner: Ahmed (Documentation Architect)
last_updated: 2026-08-02
---

# Documentation Map
## Hotel Hall Booking Management System

## 1. Purpose

This document is the **navigation guide** for the project's documentation. It answers one
question, from any starting point: *"which document(s) do I need before I do this task?"*

It is deliberately not the same as the two documents it sits alongside:

- `docs/Project-Constitution.md` defines the **rules** — the non-negotiable principles the
  project is governed by.
- `docs/00-governance/documentation-architecture.md` defines the **design** of the
  documentation system — why each category and document type exists, who owns it, and what
  depends on it, in full detail.
- **This document** is the **index and route-finder** on top of both — it tells you where
  things are and in what order to read them, without re-explaining why they exist. Where
  more depth is needed, it points to `documentation-architecture.md` rather than repeating
  it.

Every developer and every AI assistant should be able to open this file, find their task
below, and know exactly which documents to open next.

---

## 2. Documentation Categories

> **Note on category names:** an early draft of this documentation set used a template with
> separate `api/` and `database/` top-level categories. Those were deliberately merged —
> API conventions live in `03-standards/api-standards.md`, and database/data concerns live
> in `02-architecture/data-architecture.md` — to keep the category set small enough for a
> 3-person team to actually maintain. See `documentation-architecture.md` §16 for the full
> rationale. The categories below are the current, approved set.

| Category | Purpose | Owner | Mandatory | When it's used |
|---|---|---|---|---|
| `docs/` (root) | Foundational documents: overview, constitution, this map, team management, development lifecycle, development roadmap, decision-making principles, project glossary | Ahmed | Yes | Read first, and whenever a rule, priority, process phase, execution order, decision, or term needs confirming |
| `00-governance/` | Ready/done gates, change control, decision log | Ahmed | Yes | Ongoing reference; consulted at every phase transition |
| `01-ai-governance/` | Rules for AI-assisted work | Ahmed | Yes | Before and during any AI-assisted task |
| `02-architecture/` | System-wide technical architecture + ADRs | Ahmed | Yes | Before any Technical Design; when proposing an architecture change |
| `03-standards/` | Engineering conventions: coding, naming, API, git, testing, documentation, UI/UX & accessibility, secure coding | Ahmed | Yes | During design and implementation of any module |
| `04-business/` | Stakeholders/personas, business decision register, one Business Specification per module | Ahmed | Yes | Before a module's Technical Design begins |
| `05-technical-design/` | One Technical Design per module | Ahmed | Yes | Before a module's Implementation Plan begins |
| `06-implementation-planning/` | One Implementation Plan per module | Ahmed | Yes | Before implementation of a module begins |
| `07-validation-and-qa/` | Test strategy, review checklists, one Validation Report per module | Ahmed / assigned reviewer | Yes | During and after implementation |
| `08-templates/` | Blank templates for the four per-module document types | Ahmed | Yes | Whenever a module's next document is started |

---

## 3. Documents Inside Every Category

Condensed index only — for the full purpose/why-it-exists/dependency reasoning behind any
row below, see the matching section of `documentation-architecture.md` (section numbers
noted in the last column).

### `docs/` (root)

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `Project-Overview.md` | What the system is, why, current status | First — before anything else | Yes | — |
| `Project-Constitution.md` | The non-negotiable rules of how the project is built | First — alongside Overview | Yes | — |
| `Documentation-Map.md` | This document | First — to learn how to navigate everything else | Yes | — |
| `Team-Management.md` | Team roles, Round-Robin assignment, review rules, live Feature Assignment Register | Before implementing or reviewing anything; whenever checking a feature's status | Yes | — |
| `Development-Lifecycle.md` | The mandatory 13-phase (0–12) process every feature follows, with entry/exit criteria, reviewers, and failure handling per phase | Before starting any phase of work on a feature; whenever it's unclear what happens next or what to do if a review fails | Yes | — |
| `Development-Roadmap.md` | The execution plan — implementation sequence, dependencies, milestones, release strategy | Before deciding what to prepare or build next; whenever it's unclear why a module is sequenced where it is | Yes | — |
| `Decision-Making-Principles.md` | Decision categories, authority, process, evaluation criteria, conflict resolution | Whenever a non-trivial decision needs to be made, justified, or revisited | Yes | — |
| `Project-Glossary.md` | The official dictionary — one meaning per business/technical/project term | Whenever a term is unclear or before introducing a new one | Yes | — |
| `README.md` | Short pointer into the documents above | Any time you land in `docs/` without context | Yes | — |

### `00-governance/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `definition-of-ready-and-done.md` | Entry gate for design; exit gate for delivery | Before starting Technical Design; before closing a feature | Yes | §6 |
| `change-management-policy.md` | How approved documents may be amended | When any approved document needs a change | Yes | §6 |
| `decision-log.md` | Index of all ADRs | When checking if an architecture decision already exists | Yes | §6 |

### `01-ai-governance/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `ai-governance.md` | AI boundaries, collaboration workflow, output-review checklist, required context | Before every AI-assisted session | Yes | §7 |

### `02-architecture/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `architecture-principles.md` | Non-negotiable architectural philosophy and principles every Technical Design must comply with | Before authoring or reviewing any Technical Design | Yes | §8 |
| `system-architecture-overview.md` | Overall system shape, NFRs, integration, infrastructure | Before any Technical Design | Yes | §8 |
| `technology-stack.md` | Approved languages, frameworks, services (Flutter, Node.js/Express, PostgreSQL/Prisma, and more — per ADR-0001) | Before any Technical Design | Yes | §8 |
| `folder-structure.md` | Official repository structure — feature-based, not layer-based; naming and ownership rules | Before any Implementation Plan; whenever adding a new module | Yes | §8 |
| `domain-model-and-bounded-contexts.md` | How the 14 modules map to domain entities | When a Technical Design defines entities or boundaries | Yes | §8 |
| `data-architecture.md` | Data ownership, cross-module access, multi-tenant isolation | Any module touching persisted data | Yes | §8 |
| `security-architecture.md` | System-wide security model | Every Technical Design; mandatory for Auth/Payment/Security modules | Yes | §8 |
| `mobile-application-architecture.md` | Architecture of both mobile apps, incl. API consumption | Any module with UI or an API surface | Yes | §8 |
| `adr/0000-adr-template.md` | Template for recording one architecture decision | Whenever proposing an architecture change | Yes (process) | §8 |

### `03-standards/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `coding-standards.md` | Code style, structure | During every implementation | Yes | §9 |
| `naming-conventions.md` | Official naming across docs, code, database, API, git, env vars, tests | Whenever naming anything new | Yes | §9 |
| `api-standards.md` | REST contract: envelopes, status codes, pagination, versioning, auth | Whenever a Technical Design defines endpoints | Yes | §9 |
| `database-standards.md` | Schema design: keys, relationships, constraints, migrations | Whenever a Technical Design or migration touches the schema | Yes | §9 |
| `git-workflow-and-branching.md` | Branching/commit workflow (naming format is in `naming-conventions.md` §11) | Every implementation task | Yes | §9 |
| `testing-standards.md` | Required test types, coverage (test naming is in `naming-conventions.md` §13) | Implementation planning and validation | Yes | §9 |
| `documentation-standards.md` | Formatting/structure rules for `docs/` itself | Authoring any document | Yes | §9 |
| `ui-ux-and-accessibility-standards.md` | Design system + accessibility minimums | Any Technical Design with a UI | Yes | §9 |
| `security-coding-standards.md` | Secure-coding checklist | Implementation and implementation review | Yes | §9 |

### `04-business/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `stakeholders-and-personas.md` | Who the users are | Before writing any Business Specification | Yes | §10 |
| `business-decision-register.md` | Centralized, versioned record of every significant business decision (BDR-*) | Before writing any Business Specification; whenever a business question needs an authoritative answer | Yes | §10 |
| `modules/<module>/business-specification.md` (×14) | Business rules, scenarios, acceptance criteria for one module | Before that module's Technical Design; before implementing that module | Yes | §10 |

### `05-technical-design/`, `06-implementation-planning/`, `07-validation-and-qa/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `modules/<module>/technical-design.md` (×14) | How the module's business spec is technically built | Before that module's Implementation Plan; before implementing | Yes | §11 |
| `modules/<module>/implementation-plan.md` (×14) | Sequenced build plan for the module | Immediately before implementing that module | Yes | §12 |
| `test-strategy.md` | System-wide test approach + UAT | Implementation planning and validation | Yes | §13 |
| `review-checklists.md` | Approval checklist for Business Spec / Technical Design / Implementation | At each of the three approval gates | Yes | §13 |
| `modules/<module>/validation-report.md` (×14) | Evidence a module was tested, reviewed, and accepted | After implementation and review of that module | Yes | §13 |

### `08-templates/`

| Document | Purpose | When to read | Mandatory | Detail |
|---|---|---|---|---|
| `business-specification-template.md`, `technical-design-template.md`, `implementation-plan-template.md`, `validation-report-template.md` | Blank starting structure for each per-module document type | Copied at the start of authoring that document for a module | Yes | §14 |

---

## 4. Reading Order

For a new developer or a fresh AI session with no prior context on this project:

```
Project-Overview.md
        ↓
Project-Constitution.md
        ↓
Documentation-Map.md              (this document)
        ↓
Team-Management.md                (team roles, workflow, review rules)
        ↓
Development-Lifecycle.md          (the 13 phases every feature moves through)
        ↓
Development-Roadmap.md            (what gets built, in what order, and why)
        ↓
Decision-Making-Principles.md     (how any decision along the way gets made)
        ↓
Project-Glossary.md               (one official meaning per term)
        ↓
00-governance/*                   (ready/done gates, decision log)
        ↓
01-ai-governance/ai-governance.md
        ↓
02-architecture/*
        ↓
03-standards/*
        ↓
04-business/stakeholders-and-personas.md, 04-business/business-decision-register.md
        ↓
[then, per feature]
business-specification.md → technical-design.md → implementation-plan.md
```

Nobody is expected to read all 56 per-module documents up front — only the ones for the
module they are currently working on, found via §5 below.

---

## 5. Task-Based Reading Guide

| Task | Read before starting |
|---|---|
| **Making or documenting a non-trivial decision** | `Decision-Making-Principles.md` §3–§6 (category, authority, process, evaluation criteria) |
| **Proposing or recording a business decision** | `business-decision-register.md` §2–§3 (lifecycle, record format), then the §5 Register table |
| **Deciding what to prepare or build next** (Ahmed only) | `Development-Roadmap.md` §4–§7 (sequence, dependency status, progress) |
| **Creating a new feature's documentation** (Ahmed only) | `Development-Lifecycle.md` Phases 0–6 (what to produce and in what order), `Project-Constitution.md`, `stakeholders-and-personas.md`, `business-decision-register.md`, `Project-Glossary.md`, and the Business Specifications of related existing modules for consistency |
| **Reviewing a Business Spec, Technical Design, or Implementation Plan** (Mohamed/Abukar) | `Development-Lifecycle.md` Phases 3, 5, 6 (entry/exit criteria for that phase), the relevant section of `review-checklists.md` |
| **Implementing an assigned feature** | `Development-Lifecycle.md` Phase 8, that module's `business-specification.md`, `technical-design.md`, `implementation-plan.md`, plus `folder-structure.md`, `naming-conventions.md`, `coding-standards.md`, and `git-workflow-and-branching.md` |
| **Bug fixing** | The module's `business-specification.md` (intended behavior) and `technical-design.md` (intended structure), plus `coding-standards.md` |
| **Refactoring** | The module's `technical-design.md`, `system-architecture-overview.md`, `coding-standards.md` — the module's `business-specification.md` defines the behavior that must not change |
| **Security improvements** | `security-architecture.md`, `security-coding-standards.md`, the module's `technical-design.md` |
| **Database / data work** | `data-architecture.md`, `domain-model-and-bounded-contexts.md`, `database-standards.md`, `naming-conventions.md` §8, the module's `technical-design.md` |
| **API work** | `api-standards.md`, `mobile-application-architecture.md`, the module's `technical-design.md` |
| **UI work** | `ui-ux-and-accessibility-standards.md`, `mobile-application-architecture.md`, the module's `business-specification.md` |
| **Code review** | `coding-standards.md`, `security-coding-standards.md`, the Implementation section of `review-checklists.md`, `Team-Management.md` §5 (to confirm you're an eligible reviewer) |
| **Architecture review / proposing a change** | `architecture-principles.md`, `system-architecture-overview.md`, `domain-model-and-bounded-contexts.md`, `decision-log.md`, `adr/0000-adr-template.md`, `Decision-Making-Principles.md` §7 (when an ADR is required), `Project-Constitution.md` §7 and §11 |

---

## 6. AI Reading Guide

`Project-Constitution.md` §4 and `01-ai-governance/ai-governance.md` apply to **every** AI
task below, regardless of type — load them first, always, no exceptions.
`Development-Lifecycle.md` §3 additionally requires confirming which phase the feature is
currently in before doing any of the work below — if that's unclear, stop and ask.

| AI task | Also load |
|---|---|
| **Business Analysis** (drafting a Business Specification) | `Development-Lifecycle.md` Phase 2, `stakeholders-and-personas.md`, `business-decision-register.md`, `Project-Glossary.md`, related existing Business Specifications |
| **Technical Design** | `Development-Lifecycle.md` Phase 4, the module's approved `business-specification.md`, all of `02-architecture/`, relevant `03-standards/` |
| **Implementation** | The module's approved `business-specification.md` + `technical-design.md` + `implementation-plan.md`, `folder-structure.md`, `naming-conventions.md`, `coding-standards.md`, `git-workflow-and-branching.md` |
| **Testing** | The module's `technical-design.md`, `testing-standards.md`, `test-strategy.md` |
| **Validation** | The module's `business-specification.md` (acceptance criteria), `test-strategy.md`, `review-checklists.md` |
| **Documentation updates** | `documentation-architecture.md`, `documentation-standards.md`, the document being updated, `Project-Constitution.md` |
| **Security review** | `security-architecture.md`, `security-coding-standards.md`, the module's `technical-design.md` |
| **Code review** | `coding-standards.md`, `review-checklists.md`, `ai-governance.md` (no-self-review applies to AI too) |
| **Architecture review** | `architecture-principles.md`, `system-architecture-overview.md`, `domain-model-and-bounded-contexts.md`, `decision-log.md` |

If a task doesn't fit these rows cleanly, the AI should say so and ask which documents apply
rather than guessing — per `Project-Constitution.md` §4 and §10.

---

## 7. Document Priority

This map does not define its own priority order — it reuses the one authority already
established in `Project-Constitution.md` §10:

```
1. Project-Constitution.md
2. Approved Business Documents
3. Architecture
4. Standards
5. Technical Design
6. Implementation Planning
```

This document and `documentation-architecture.md` are navigation and reference tools, not
sources of business or technical truth. If this map ever appears to contradict the actual,
current content of a document it describes, **the document wins, not this map** — and the
map should be corrected.

For how a decision actually gets made when priority alone isn't enough to resolve a
question — authority, process, evaluation criteria, conflict resolution — see
`Decision-Making-Principles.md`.

**When uncertainty remains: Stop. Request clarification. Do not assume.**

---

## 8. Document Lifecycle

The full 13-phase (0–12) lifecycle every feature and its documents move through —
Feature Request through Implementation to Maintenance, with entry/exit criteria and
reviewers at each step — is defined once, in full, in `docs/Development-Lifecycle.md`. It
is not duplicated here.

Two related status vocabularies, each defined where they're used:

- **Document-level status** (`Not Started` → `Draft` → `In Review` → `Changes Requested` →
  `Approved` → `Implemented` → `Deprecated`) — one artifact's approval state, defined in
  `documentation-architecture.md` §3.
- **Feature-level status** (the 13 phase names, plus `On Hold` / `Cancelled`) — which phase
  of `Development-Lifecycle.md` a whole feature is currently in, tracked in
  `Team-Management.md` §7 and defined in `Team-Management.md` §6.

---

## 9. Maintenance Rules

- **Documentation must always match implementation.** A code change that alters behavior
  updates the relevant document in the same review — not "later."
- **No feature may be implemented without documentation** — restated from
  `Project-Constitution.md`, enforced structurally by the folder layout in §2–§3.
- **Deprecated documents are marked `status: Deprecated` and linked to their replacement**,
  not silently deleted — history stays visible.
- **Every update to a foundational document** (`Project-Overview.md`, `Project-Constitution.md`,
  this map, `documentation-architecture.md`) is logged in that document's own Version
  History table.
- **AI-generated documentation is always reviewed by a human** before reaching `Approved`
  status — the same no-self-review rule that governs code applies to documentation.

---

## 10. Future Scalability

This structure is designed to support hundreds of features without restructuring:

- Adding module 15, 16, ... N adds one more identically-shaped slug folder under
  `04-business/modules/`, `05-technical-design/modules/`, `06-implementation-planning/modules/`,
  and `07-validation-and-qa/modules/`. No new top-level category is needed, and this map's
  §2–§6 tables do not change.
- The **category set (§2) is closed by design.** Adding a new document *type* (not a new
  module instance) is a governance decision, not a routine edit — it requires an amendment
  under `Project-Constitution.md` §11, precisely to prevent the category sprawl that was
  already identified and trimmed once (see `documentation-architecture.md` §16).
- Per-module documents scale linearly and predictably (4 documents × N modules); nothing
  else in the structure scales with feature count.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-01 | Ahmed | Initial approved Documentation Map |
| 1.1 | 2026-08-01 | Ahmed | Updated all references to `Team-Management.md`, which supersedes the planned `00-governance/team-and-workflow.md` and `feature-status-board.md` |
| 1.2 | 2026-08-02 | Ahmed | Added `Development-Lifecycle.md` throughout (categories, reading order, task guide, AI guide); §8 now points to it instead of duplicating a simplified lifecycle diagram |
| 1.3 | 2026-08-02 | Ahmed | Added `Development-Roadmap.md` throughout (categories, reading order, task guide) |
| 1.4 | 2026-08-02 | Ahmed | Added `Decision-Making-Principles.md` throughout (categories, reading order, task guide, §7 Document Priority) |
| 1.5 | 2026-08-02 | Ahmed | Replaced all `00-governance/glossary.md` references with root-level `Project-Glossary.md` |
| 1.6 | 2026-08-02 | Ahmed | Added `04-business/business-decision-register.md` throughout (§2, §3, reading order, task guide, AI guide) |
| 1.7 | 2026-08-02 | Ahmed | Added `02-architecture/architecture-principles.md`; corrected `system-architecture-overview.md`'s description (no longer covers principles) |
| 1.8 | 2026-08-02 | Ahmed | Added `02-architecture/folder-structure.md` throughout |
| 1.9 | 2026-08-02 | Ahmed | Added `03-standards/naming-conventions.md`; `coding-standards.md`, `git-workflow-and-branching.md`, `testing-standards.md` rows point to it for naming specifics |
| 2.0 | 2026-08-03 | Ahmed | `coding-standards.md` and `api-standards.md` now authored (rows updated); added new `database-standards.md` |
