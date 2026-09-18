---
title: "Team Management"
document_type: Governance
status: Approved
version: 1.27
owner: Ahmed (Project Lead)
last_updated: 2026-09-16
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
| M01.1 | Authentication & Account Management — Backend | 01-authentication-and-account-management | Ahmed | Ahmed | Mohamed | High | Validation & QA | 2026-08-03 | 2026-08-03 | — | Dependency root for every other module — planned first. Split from `M01` on 2026-08-04 (§7's own splitting rule) once frontend became a distinct, separately-tracked scope. Business Specification v1.2, Technical Design v1.7 (§1–§17), Implementation Plan v1.7 (§1–§3 WBS-01–15) all `Approved`; **Implementation Review complete — approved by Mohamed.** All 15 backend WBS tasks complete (M1–M4 milestones): full component set including Verification and Password Reset via the `SmsProvider` abstraction (`MockSmsProvider`/`TwilioSmsProvider`, `ADR-0005`). 51 passing tests, clean lint. One design defect found and corrected during implementation: Technical Design §10's `PATCH /password-resets/:id` was incompatible with its own anti-enumeration requirement, corrected to `PATCH /password-resets`. **Real gap, not yet procedural-only:** `test-strategy.md`, `review-checklists.md`, `definition-of-ready-and-done.md`, and `validation-report.md` are all still `Not Started` — blocks Validation & QA from actually closing out. |
| M01.2 | Authentication & Account Management — Frontend | 01-authentication-and-account-management | Ahmed | Ahmed | Mohamed | High | Implementation | 2026-08-04 | 2026-08-04 | — | Split from `M01` on 2026-08-04. Technical Design §18 (Frontend Integration Scope) and Implementation Plan §3.1 (`FE-00`–`FE-07`) — **reviewed and approved by Mohamed, 2026-08-04.** `Implemented By` set to Ahmed as the first Round Robin assignment (§4) once `FE-01`/`FE-02` were picked up. **`FE-01`/`FE-02` (Admin Web Login/Change-Password) done** — implemented on `feature/authentication-admin-web-ui`, manually verified end-to-end against the real backend (login, change password, logout). **`FE-00` (shared Flutter design-token package) done, 2026-08-25** — `shared/flutter_design_tokens/`, consumed by both `apps/customer-mobile` and `apps/manager-mobile`; prioritized ahead of `FE-03`–`FE-07` to resolve a blocker Hall Management's (M04) own Development phase surfaced. Remaining scope: Customer Mobile and Hotel Manager Mobile screens (`FE-03`–`FE-06`, now unblocked at the token-package level); `FE-07` additionally blocked on Hotel Management (Module 3) and Administration & Platform Management (Module 13) having Business Specifications — Hotel Management's now exists, Module 13's does not. Source: `Hotel Hall Design System/` (repo root, committed 2026-08-04). |
| M02 | Customer Management | 02-customer-management | Ahmed | Ahmed | TBD | High | Implementation | 2026-08-30 | 2026-08-30 | — | **Documentation written retroactively 2026-09-07** (business specification §25 addendum, Technical Design v1, Implementation Plan v1 — all `Approved`/`Implementation` status, no human Reviewer sign-off yet). Delivered: bare Customer profile existence (`/customers/me`, `/customers/me/profile`) and Favorites (Saved Hotels). **Genuinely blocked, not an oversight:** BDR-CUST-01/02/03 (required/optional profile fields, completion requirement) remain unresolved — `profileData` accepts no fields until approved. Validation & QA not started. |
| M03 | Hotel Management | 03-hotel-management | Ahmed | — | Mohamed or Abukar | Critical | Ready for Development | 2026-08-10 | — | — | Business Specification v1.1, Technical Design v1.3, Implementation Plan v1.1 all `Approved` 2026-08-10. Grounded in `BDR-001`, `BDR-003`, `BDR-008`, and five newly-recorded decisions (`BDR-010`–`BDR-014`) covering rejected-application handling, withdrawal, suspension authority, information-validity restriction, and profile-change review policy. During Technical Design review, a genuine data-ownership conflict was found and resolved: `data-architecture.md` §9 and Module 1's Technical Design had misattributed "Hotel approval status" to Administration & Platform Management (Module 13) — both corrected 2026-08-10 to match this module's approved boundary (Hotel Management owns the data; Module 13 owns only the review workflow/interface). Three Pending Business Decisions (#4 Restriction Scope, #5 Field Classification, #7 Required Profile Content) block specific Implementation Plan task sub-scopes, not the feature's start — tracked in Implementation Plan §11. `Implemented By` not yet set — Round Robin assignment (§4) happens when this row's first task is actually picked up. |
| M04 | Hall Management | 04-hall-management | Ahmed | Ahmed | Mohamed | Critical | Implementation | 2026-08-25 | 2026-08-25 | — | Business Specification v1.1, Technical Design v1.3, and Implementation Plan v1.2 all `Approved`. All 10 WBS tasks across all 4 milestones (M1–M4) complete, **except** the sub-scope Pending Business Decision #2 (Required Hall Information) deliberately keeps open (WBS-03/WBS-08's field-level content) — not an oversight. Two genuine architectural blockers surfaced during Development and were resolved: (1) own-Hotel authorization (`BR-HALL-10`, WBS-05) had no approved cross-module mechanism — resolved via a new, dedicated Hotel Ownership Query Interface added to Hotel Management's Technical Design (v1.5, independently reviewed and approved by Mohamed), never by reaching into Hotel Management's table directly; (2) no buildable Flutter frontend target existed for either mobile app — resolved by prioritizing and completing `FE-00` (M01.2's shared design-token package) ahead of Hall Management's own frontend scope. Backend: 4 own-Hotel-scoped endpoints (WBS-05) plus the platform-wide browse endpoint (WBS-06), full OpenAPI documentation (WBS-09), 29 Hall Management tests plus 4 in Hotel Management's own suite for the new interface (WBS-10); full backend suite 172/172 passing, lint clean. **Not started:** Hall Management's own mobile screens (Hotel Manager Hall CRUD, Customer Hall browsing — no approved `FE-##`-equivalent task list defines them yet); Validation & QA (`validation-report.md` still `Not Started`); Feature Acceptance. |
| M05 | Booking Management | 05-booking-management | Ahmed | Ahmed | TBD | Critical | Implementation | 2026-09-03 | 2026-09-03 | — | Business Specification, Technical Design, and Implementation Plan all `Approved` (2026-09-03, updated 2026-09-07 to correct the payment-verification rule below and record later UX work — no human Reviewer sign-off yet). Full Customer + own-Hotel Manager Booking lifecycle, pricing, and payment report/verify delivered and backend-tested. **Business rule changed 2026-09-07 by explicit approval:** verifying a Customer's reported payment no longer hard-blocks on an under-required-advance amount — the Manager now sees a warning and decides. Also delivered since initial build: post-Booking confirmation feedback on Customer Mobile, a Manager-side confirm dialog + spinner for payment verification, and cross-screen refresh (My Bookings, Booking Detail, Manager Bookings queue, Hall Availability, Popular Hotels ranking) after a Booking mutation. **2026-09-16 (`BDR-024`):** cancelling a `CONFIRMED` Booking now requires a Customer-supplied reason (`Booking.cancellationReason`, shown to the Hotel Manager on the detail sheet); a Pending cancellation and the Hotel Manager's own cancellation are unaffected. Same date: also fixed six `$transaction` call sites (`booking.service.js`, `availability.service.js` ×2, `application.service.js` ×3) that used Prisma's default 2s/5s timeout, too tight for this project's remote Neon Postgres latency — widened to match the one call site (`authentication.service.js#register`) that had already hit and fixed this exact problem. Validation & QA not started. |
| M06 | Calendar & Scheduling Management | 06-calendar-and-scheduling-management | Ahmed | Ahmed | TBD | Critical | Implementation | 2026-09-03 | 2026-09-03 | — | **Documentation written retroactively 2026-09-07** — the module was fully implemented (and its own design decisions recorded only as in-code comments referencing an "Approved Technical Design" that was never actually committed to `docs/`) before this Business Specification/Technical Design/Implementation Plan existed. Delivered: own-Hotel Manager manual availability blocks, the public Customer busy-periods/availability-check surface, the shared per-Hall transaction lock and database exclusion constraint preventing double-booking, and lazy Booking expiration. No human Reviewer sign-off yet; Validation & QA not started. |
| M07 | Payment Management | 07-payment-management | Ahmed | Ahmed | TBD | Critical | Implementation | 2026-09-03 | 2026-09-03 | — | **Documentation written retroactively 2026-09-07.** V1 scope is intentionally narrow: manual off-platform payment reporting and verification embedded in Booking Management's own record — there is no standalone `payments` backend module, no gateway, no refunds, no invoicing. Delivered: Customer payment report, own-Hotel Manager verify/reject (with the 2026-09-07 rule change recorded under M05), and the Manager-facing reported-amount display this change depended on. No human Reviewer sign-off yet; Validation & QA not started. |
| M08 | Event Management | 08-event-management | — | — | — | — | Not Started | — | — | — | |
| M09 | Staff Management | 09-staff-management | — | — | — | — | Not Started | — | — | — | |
| M10 | Communication & Notification Management | 10-communication-and-notification-management | Ahmed | Ahmed | TBD | Medium–High | Implementation | 2026-09-07 | 2026-09-07 | — | **Documentation written retroactively 2026-09-13.** Business Specification, Technical Design, and Implementation Plan all `Approved` (2026-09-11) — Notification-only V1, per the Naming Note (Communication/chat is a separate, out-of-scope future feature). Built ahead of Staff Management (Module 9), one of its three formal dependencies (§5) — Staff-account notifications are explicitly out of scope for V1, so nothing here required Staff Management to exist first; recorded here the same way Reviews & Ratings' (M11) own out-of-wave-order build is recorded in `Development-Roadmap.md` §9. Delivered: all 19 Notification Catalog events (backend `notification.events.js`, including `BDR-021` Hotel-application-decision and `BDR-022` Hotel suspend/deactivate/reactivate notifications added 2026-09-11), in-app list/unread-count/mark-read/mark-all-read on Customer Mobile, Manager Mobile, and Admin Web (the last wired 2026-09-11 into `NotificationsMenu.jsx`'s pre-existing but previously-hardcoded bell/dropdown — no new frontend infrastructure), and Firebase Cloud Messaging push delivery end-to-end on Android for both mobile apps (`MockPushProvider`/`FcmPushProvider` selection, dead-token cleanup, token-refresh handling, tap-to-navigate from background/terminated launch). **Genuinely still pending, not an oversight:** iOS Firebase registration (no `GoogleService-Info.plist` yet — Android-only for now), and a monochrome status-bar notification icon (cosmetic, needs a real design asset). Validation & QA not started. |
| M11 | Reviews & Ratings Management | 11-reviews-and-ratings-management | Ahmed | Ahmed | TBD | Low–Medium | Implementation | 2026-09-06 | 2026-09-06 | — | **Documentation written retroactively 2026-09-07.** Delivered: Customer review submission gated on a Completed Booking the Customer owns (one review per Booking, database-enforced), and the public Hotel average-rating/count + review list on Hotel Detail. Sequenced ahead of its Wave 6 roadmap position because its only real dependencies (Booking Management, Customer identity) were already stable — see `Development-Roadmap.md` §9 change note. No human Reviewer sign-off yet; Validation & QA not started. |
| M12 | Reports & Analytics | 12-reports-and-analytics | — | — | — | — | Not Started | — | — | — | |
| M13 | Administration & Platform Management | 13-administration-and-platform-management | Ahmed | Ahmed | TBD | High | Implementation | 2026-08-28 | 2026-08-28 | — | **Documentation written retroactively 2026-09-07.** V1 scope is intentionally narrow — the Platform Administrator's Hotel-application review workflow only (list/approve/reject on Admin Web), delegating entirely to Hotel Management's own Application data and lifecycle. No admin user management, no cross-tenant reporting, no other platform tooling yet — see this module's Implementation Plan "Remaining Scope." No human Reviewer sign-off yet; Validation & QA not started. |
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
| 1.27 | 2026-09-16 | Ahmed | §7: M05 (Booking Management) Notes updated — `BDR-024` (cancelling a Confirmed Booking now requires a Customer-supplied reason, shown to the Hotel Manager) and a reliability fix (six `$transaction` call sites widened to a 10s timeout, matching an already-fixed identical issue in `authentication.service.js#register`, for this project's remote Neon Postgres latency). |
| 1.26 | 2026-09-13 | Ahmed | §7: updated M10 (Communication & Notification Management) from `Not Started` to `Implementation`, reflecting that it was already implemented and running (backend, Customer Mobile, Manager Mobile, Admin Web, FCM push) before this row was ever updated. Documentation written retroactively this date. Built ahead of its Wave 6 roadmap position and ahead of Staff Management (one of its three dependencies), the same category of workload-sequencing call already recorded for M11 — see M10's own Notes and `Development-Roadmap.md` §9. `Reviewer` not filled in yet; Validation & QA not started. |
| 1.25 | 2026-09-07 | Ahmed | §7: updated M02, M05, M06, M07, M11, M13 from `Not Started` to `Implementation`, reflecting that all six were already implemented and running before their Business Specification/Technical Design/Implementation Plan documents existed. Documentation for all six written retroactively this date, against the actual delivered code rather than forward design — see each module's own documents for what shipped and what remains genuinely blocked on a pending business decision. No module's `Reviewer` column is filled in yet; none has entered Validation & QA. |
| 1.16 | 2026-08-04 | Ahmed | §7: Mohamed reviewed and approved Technical Design §18 and Implementation Plan §3.1 (frontend scope). Split `M01` into `M01.1` (Backend, `Validation & QA`) and `M01.2` (Frontend, `Ready for Development`) per §7's own splitting rule — the two tracks are now at genuinely different lifecycle phases and a single `Status` cell could no longer represent both accurately. |
| 1.17 | 2026-08-04 | Ahmed | §7: M01.2's `Status` changed `Ready for Development` → `Implementation`; `Implemented By` set to Ahmed (first Round Robin assignment); `Started Date` set. `FE-01`/`FE-02` (Admin Web Login/Change-Password) complete and manually verified against the real backend; `FE-00`, `FE-03`–`FE-07` remain not started. |
| 1.18 | 2026-08-10 | Ahmed | §7: M03 (Hotel Management) `Status` changed `Not Started` → `Ready for Development` — Business Specification, Technical Design, and Implementation Plan all reached `Approved` the same day, including resolution of a genuine Hotel-approval-status data-ownership conflict discovered during Technical Design review (`data-architecture.md` and Module 1's Technical Design corrected to match). `Prepared By` set to Ahmed; `Assigned Date` set; three Pending Business Decisions noted as task-level (not feature-level) blockers. |
| 1.24 | 2026-08-25 | Ahmed | §7: M04 (Hall Management) `Status` changed `Implementation Planning` → `Implementation`; `Implemented By` set to Ahmed, `Started Date` set. All 10 WBS tasks and 4 milestones now complete except the Pending Business Decision #2 sub-scope (deliberately open). Records both blockers found and resolved during Development: the Hotel Ownership Query Interface (Hotel Management Technical Design v1.5) and `FE-00`'s completion (M01.2). Not moved to `Validation & QA` — that phase has not started. |
| 1.23 | 2026-08-25 | Ahmed | §7: M01.2's `Notes` updated — `FE-00` (shared Flutter design-token package) marked Done, prioritized ahead of `FE-03`–`FE-07` to resolve a genuine architectural blocker Hall Management's (M04) own Development phase surfaced (no buildable frontend target existed for either Flutter app). `FE-03`–`FE-06` now unblocked at the token-package level; `FE-07` still separately blocked on Module 13. |
| 1.22 | 2026-08-25 | Ahmed | §7: M04 (Hall Management) `Notes` updated — Implementation Plan v1.0 (`Draft`) authored (10 WBS tasks, 4 milestones); Technical Design bumped to v1.2 for a self-found `GET /api/v1/halls` pagination-mode defect (`coding-standards.md` §6 compliance), corrected transparently while authoring the plan. `Status` remains `Implementation Planning` pending independent review. |
| 1.21 | 2026-08-25 | Ahmed | §7: M04 (Hall Management) `Status` changed `Technical Design` → `Implementation Planning` — Technical Design v1.1 reached `Approved`, reviewed by Mohamed with no changes requested, matching Business Specification v1.1's own review outcome. Implementation Plan not yet authored. |
| 1.20 | 2026-08-25 | Ahmed | §7: M04 (Hall Management) `Notes` updated — the `data-architecture.md` §9 blocker recorded in v1.19 is resolved; Technical Design v1.0 (`Draft`) authored, computing Hall visibility live from Hotel Management's Eligibility Query Interface rather than a second persisted status. `Status` remains `Technical Design` pending independent review. |
| 1.19 | 2026-08-25 | Ahmed | §7: M04 (Hall Management) `Status` changed `Not Started` → `Technical Design` — Business Specification v1.1 reached `Approved`, reviewed by Mohamed with no changes requested. `Prepared By` set to Ahmed; `Reviewer` set to Mohamed; `Assigned Date` set. Notes record the Hall lifecycle model (Hidden/Visible), the 11 logged Pending Business Decisions (none feature-blocking), and the standing `data-architecture.md` §9 staleness that must be corrected before this module's Technical Design may proceed. |
| 1.15 | 2026-08-04 | Ahmed | §7: M01's `Notes` — `FE-00`–`FE-07` formalized into Implementation Plan §3.1 (v1.6), still `Proposed` pending review, same as Technical Design §18. |
| 1.14 | 2026-08-04 | Ahmed | §7: M01's `Notes` note Technical Design §18 (Frontend Integration Scope, unreviewed) and that no frontend work has started. |
| 1.13 | 2026-08-04 | Ahmed | §7: M01's `Status` changed `Implementation Review` → `Validation & QA` — Mohamed approved the implementation review. `Feature Accepted` still requires Validation to actually pass (§6), which currently has no governing document (`test-strategy.md`, `review-checklists.md`, `definition-of-ready-and-done.md`, `validation-report.md` all `Not Started`). |
| 1.12 | 2026-08-04 | Ahmed | §7: M01's `Status` changed `Implementation` → `Implementation Review` — all 15 WBS tasks (M1–M4) complete, 51 passing tests. Awaiting Mohamed's review. |
| 1.11 | 2026-08-04 | Ahmed | §7: M01's `Notes` updated — Milestone M4 complete (GET /me, OpenAPI docs, 28 passing tests); only M3 (Twilio-dependent) remains. |
| 1.10 | 2026-08-04 | Ahmed | §7: M01's `Reviewer` set to Mohamed (arbitrary pick between two equally-available reviewers, per §5); branch pushed, MR link recorded; M4 marked in progress. |
| 1.9 | 2026-08-03 | Ahmed | §7: M01's `Status` changed `Ready for Development` → `Implementation`; `Started Date` set. Development began on `feature/authentication-identity-foundation` — Milestones M1+M2 (WBS-01–09) complete with 26 passing tests; M3 deferred (needs Twilio credentials); M4 not yet started. |
| 1.8 | 2026-08-03 | Ahmed | §7: M01's `Notes` updated — password hashing algorithm decided (Argon2id); no blockers remain for M01. Reflects Technical Design v1.4 and Implementation Plan v1.4. |
| 1.7 | 2026-08-03 | Ahmed | §7: M01's Implementation Plan reached `Approved` — Status changed `Implementation Planning` → `Ready for Development`; `Implemented By` set to Ahmed as the first Round Robin assignment (§4), consistent with the register being the record of the rotation (§4's own rule). |
| 1.6 | 2026-08-03 | Ahmed | §7: M01's `Notes` updated — `ADR-0005` reached `Approved` (Twilio); the SMS delivery blocker is resolved, leaving the password-hashing algorithm as the sole remaining blocker. Reflects Technical Design v1.3 and Implementation Plan v1.2. |
| 1.5 | 2026-08-03 | Ahmed | §7: M01's `Notes` now cite `ADR-0005` (`Proposed`) by ID for the SMS delivery-provider blocker, and reflect Technical Design v1.2 and Implementation Plan v1.1 (both minor cross-reference updates only). |
| 1.4 | 2026-08-03 | Ahmed | §7: M01 (Authentication & Account Management) updated from `Not Started` to `Implementation Planning`, reflecting that its Business Specification and Technical Design are `Approved` and its Implementation Plan is authored (`Draft`, pending review). `Prepared By` set to Ahmed; `Assigned Date` set; two open implementation blockers recorded in `Notes`. |
| 1.0 | 2026-08-01 | Ahmed | Initial approved Team Management document; replaces the planned `team-and-workflow.md` and `feature-status-board.md` |
| 1.1 | 2026-08-02 | Ahmed | §6 status vocabulary aligned to the 13 phases now defined in `docs/Development-Lifecycle.md`; §3 cross-references it |
| 1.2 | 2026-08-02 | Ahmed | Linked the anticipated "Development Roadmap" reference in §1 to the now-approved `docs/Development-Roadmap.md` |
| 1.3 | 2026-08-02 | Ahmed | §11 now notes it is an instance of the general framework in `docs/Decision-Making-Principles.md` |
