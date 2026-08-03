---
title: "Team Management"
document_type: Governance
status: Approved
version: 1.3
owner: Ahmed (Project Lead)
last_updated: 2026-08-02
---

# Team Management
## Hotel Hall Booking Management System

This document is the authoritative source for team structure, responsibilities, feature
ownership, assignment, review, workload distribution, and feature tracking. It operationalizes
`Project-Constitution.md` §6 (Feature Ownership Principles) — this document defines the
*process*; the Constitution defines the *rule*. Where the two ever appear to differ, the
Constitution wins.

> **This document replaces the previously-planned `00-governance/team-and-workflow.md` and
> `00-governance/feature-status-board.md`.** Team roles, the assignment workflow, and the
> live feature register are always read and updated together, so they live in one place
> instead of three. Both of those files have been removed; every reference to them in the
> rest of `docs/` now points here.

---

## 1. Team Members

### Ahmed

**Role:** Project Lead · Business Architect · Technical Architect · Software Engineer ·
Lead Reviewer

**Responsibilities:**
- Own all project documentation.
- Prepare every feature before implementation: Business Specification, Technical Design,
  Implementation Planning — always, regardless of who later implements it.
- Implement features assigned to him through Round Robin.
- Perform the final review for features implemented by Mohamed or Abukar.
- Approve feature completion.
- Maintain project consistency across all 14 modules.
- Maintain `docs/Development-Roadmap.md` and the Feature Assignment Register (§7).

### Mohamed

**Role:** Software Engineer

**Responsibilities:**
- Implement assigned features.
- Follow approved documentation exactly — never deviate from an approved Business
  Specification or Technical Design without a recorded change (see
  `docs/00-governance/change-management-policy.md`).
- Fix review findings.
- Participate in peer reviews of Abukar's and Ahmed's work.
- Update implementation progress in the Feature Assignment Register (§7).

### Abukar

**Role:** Software Engineer

**Responsibilities:**
- Implement assigned features.
- Follow approved documentation exactly.
- Fix review findings.
- Participate in peer reviews of Mohamed's and Ahmed's work.
- Update implementation progress in the Feature Assignment Register (§7).

---

## 2. Team Principles

**One documented source of truth.** For any question about what a feature should do or how
it should be built, there is exactly one approved document that answers it — never a Slack
message, a verbal agreement, or an assumption.

**Documentation before implementation.** No developer starts writing code for a feature
until its Business Specification, Technical Design, and Implementation Plan are all
`Approved`.

**One feature owner at a time.** At any given moment, exactly one person is accountable for
implementing a given feature. Shared, ambiguous ownership is not permitted.

**Independent review.** No one approves their own work. This applies to documentation
review as much as implementation review.

**Quality before speed.** A deadline is never a reason to skip a review, a test, or a
documentation step.

**Architecture consistency.** Every feature, regardless of who builds it, conforms to the
same architecture and standards — consistency is not negotiated per feature.

**AI assists but never replaces engineering judgment.** AI may draft, implement, and
review, but a human is always accountable for the outcome, per `Project-Constitution.md` §4.

---

## 3. Feature Preparation Workflow

Ahmed prepares every feature by completing, in order:

```
Business Specification
        ↓
Technical Design
        ↓
Implementation Planning
```

Only after **all three** are `Approved` (per the review gates in
`docs/07-validation-and-qa/review-checklists.md`) does a feature reach status
**Ready for Development** (§6) and become eligible for Round-Robin assignment.

This is the summary. The full phase-by-phase process — including who reviews each of these
three documents (never Ahmed himself), entry/exit criteria, and what happens on a failed
review — is defined in `docs/Development-Lifecycle.md`.

---

## 4. Feature Assignment (Round Robin)

Implementation is assigned using Round Robin:

```
Ahmed → Mohamed → Abukar → Ahmed → Mohamed → Abukar → ...
```

**How Round Robin is maintained:** the sequence is global across the whole project, not
per-module or per-category. It is tracked by the **order features reach "Ready for
Development"** in the Feature Assignment Register (§7): each time a feature reaches that
status, Ahmed assigns it to whoever is next in the rotation after the most recently assigned
feature, and records the assignee in the register's `Implemented By` column. The register
itself is the record of the rotation — there is no separate counter to keep in sync.

Ahmed both authors every feature's documentation and takes his own turn in the rotation as
an implementer. The two roles are independent: authoring never skips Ahmed's place in line,
and being next in line never changes who authors the documentation.

---

## 5. Review Rules

- **No developer may perform the final review of their own implementation.**
- **Ahmed performs the final review** for every implementation completed by Mohamed or
  Abukar.
- **When Ahmed implements a feature, the implementation review is performed by Mohamed or
  Abukar** — whichever of the two is not already occupied with their own active
  implementation, at Ahmed's discretion.
- **A feature cannot reach Feature Accepted until the required review is complete.** No
  exceptions for schedule pressure.

---

## 6. Feature Lifecycle Status

Every feature moves through a fixed sequence of statuses, tracked in the `Status` column of
the Feature Assignment Register (§7). The statuses are the 13 phases defined in
`docs/Development-Lifecycle.md` — that document is where each one is fully defined (Purpose,
Owner, Reviewer, Entry/Exit Criteria); this is just the status vocabulary:

```
Not Started → Feature Request → Assigned → Business Discovery → Business Review →
Technical Design → Technical Review → Implementation Planning → Ready for Development →
Implementation → Implementation Review → Validation & QA → Feature Accepted → Maintenance
```

Plus two statuses that can apply at any point in the sequence above:

- **On Hold** — work paused for a documented reason (dependency, reprioritization,
  blocker); recorded in the register's `Notes` column.
- **Cancelled** — feature will not be built; reason recorded in `Notes`.

This is the feature-level lifecycle; it is distinct from the document-level status model
(`Draft` / `In Review` / `Approved` / ...) defined in
`docs/00-governance/documentation-architecture.md` §3 — a feature's status here reflects
which phase of work is active, while a document's status reflects that one artifact's
approval state.

---

## 7. Feature Assignment Register

This register tracks every feature across the life of the project. One row per feature; a
module may later be split into multiple features during Technical Design, in which case it
gains suffixed IDs (e.g. `M05` splits into `M05.1`, `M05.2`) without renumbering the rest of
the table.

| Feature ID | Feature Name | Module | Prepared By | Implemented By | Reviewer | Priority | Status | Assigned Date | Started Date | Completed Date | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| M01 | Authentication & Account Management | 01-authentication-and-account-management | — | — | — | High | Not Started | — | — | — | Dependency root for every other module — planned first. |
| M02 | Customer Management | 02-customer-management | — | — | — | — | Not Started | — | — | — | |
| M03 | Hotel Management | 03-hotel-management | — | — | — | — | Not Started | — | — | — | |
| M04 | Hall Management | 04-hall-management | — | — | — | — | Not Started | — | — | — | |
| M05 | Booking Management | 05-booking-management | — | — | — | — | Not Started | — | — | — | |
| M06 | Calendar & Scheduling Management | 06-calendar-and-scheduling-management | — | — | — | — | Not Started | — | — | — | |
| M07 | Payment Management | 07-payment-management | — | — | — | — | Not Started | — | — | — | |
| M08 | Event Management | 08-event-management | — | — | — | — | Not Started | — | — | — | |
| M09 | Staff Management | 09-staff-management | — | — | — | — | Not Started | — | — | — | |
| M10 | Communication & Notification Management | 10-communication-and-notification-management | — | — | — | — | Not Started | — | — | — | |
| M11 | Reviews & Ratings Management | 11-reviews-and-ratings-management | — | — | — | — | Not Started | — | — | — | |
| M12 | Reports & Analytics | 12-reports-and-analytics | — | — | — | — | Not Started | — | — | — | |
| M13 | Administration & Platform Management | 13-administration-and-platform-management | — | — | — | — | Not Started | — | — | — | |
| M14 | Security & Access Control | 14-security-and-access-control | — | — | — | — | Not Started | — | — | — | |

`Prepared By` is always Ahmed once populated (§1, §3) and is left blank until preparation
actually starts, to keep the table honest about current state. Ahmed keeps this table
current as the single source of truth for "what is happening with any given feature" — it
is not duplicated elsewhere.

---

## 8. Workload Management

- **Round Robin is the default assignment strategy** and should not be deviated from
  without reason.
- **High-priority work may override Round Robin**, but only with a written justification
  recorded in the register's `Notes` column at the time of the override.
- **No developer should own multiple critical (High priority) implementations
  simultaneously** unless explicitly approved by Ahmed as Project Lead, recorded the same
  way.

---

## 9. Documentation Ownership

- Ahmed owns all governance, architecture, business, technical design, implementation
  planning, and validation documents.
- Implementation progress (the `Status`, `Started Date`, `Completed Date` columns of §7) may
  be updated directly by the assigned developer.
- All other documentation changes require Ahmed's approval before becoming official, per
  `docs/00-governance/change-management-policy.md`.

---

## 10. AI Responsibilities

- AI assists with business analysis, technical design, implementation, testing,
  documentation, and review — across every role on the team.
- AI must follow approved documentation exactly, the same as a human contributor.
- AI must not invent requirements.
- AI must not modify architecture without an approved ADR.
- AI-generated work is reviewed under the same rules as human-generated work before
  acceptance — including the no-self-review rule in §5.

Full detail: `docs/01-ai-governance/ai-governance.md` and `Project-Constitution.md` §4.

---

## 11. Escalation Process

Issues that cannot be resolved at the working level are escalated to Ahmed as Project Lead,
who makes the final decision, guided by the priority order in `Project-Constitution.md` §10.
This is the operational escalation process for issues encountered during active feature
work; it is one instance of the general decision framework defined in
`docs/Decision-Making-Principles.md` (see especially §4 Decision Authority and §9 Conflict
Resolution there).

| Escalation type | Example | Resolved by |
|---|---|---|
| Technical disagreement | Two valid implementation approaches, no clear winner | Ahmed, as Technical Architect |
| Business ambiguity | A Business Specification doesn't cover a case that's come up | Ahmed, as Business Architect — the specification is corrected before implementation continues |
| Architecture conflict | A Technical Design appears to require deviating from approved architecture | Ahmed; resolved via ADR if the architecture itself should change |
| Security concern | A design or implementation raises a security question | Ahmed, consulting `docs/02-architecture/security-architecture.md` |
| Scope change | A feature needs to do more or less than its Business Specification states | Ahmed; the Business Specification is updated and re-approved before implementation proceeds |

Escalations that set a precedent for future decisions are recorded in
`docs/00-governance/decision-log.md`; escalations specific to one feature are recorded in
that feature's row in the Register (§7), `Notes` column.

**In every case: if uncertainty remains after escalation, work stops until Ahmed provides an
explicit answer.** Nobody proceeds on an assumption.

---

## 12. Completion Rules

A feature is considered complete only when **all** of the following are true:

- Its Business Specification, Technical Design, and Implementation Plan are `Approved`.
- Implementation is complete.
- The required review (§5) is complete.
- Validation has passed against the feature's own acceptance criteria.
- `docs/00-governance/decision-log.md` is updated if the feature involved any architecture
  decision.
- This document's Feature Assignment Register (§7) reflects `Feature Accepted` status and a
  `Completed Date`.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-01 | Ahmed | Initial approved Team Management document; replaces the planned `team-and-workflow.md` and `feature-status-board.md` |
| 1.1 | 2026-08-02 | Ahmed | §6 status vocabulary aligned to the 13 phases now defined in `docs/Development-Lifecycle.md`; §3 cross-references it |
| 1.2 | 2026-08-02 | Ahmed | Linked the anticipated "Development Roadmap" reference in §1 to the now-approved `docs/Development-Roadmap.md` |
| 1.3 | 2026-08-02 | Ahmed | §11 now notes it is an instance of the general framework in `docs/Decision-Making-Principles.md` |
