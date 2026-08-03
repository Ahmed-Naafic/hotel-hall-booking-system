---
title: "Development Lifecycle"
document_type: Governance / Process
status: Approved
version: 1.2
owner: Ahmed (Engineering Process Architect)
last_updated: 2026-08-02
---

# Development Lifecycle
## Hotel Hall Booking Management System

This document defines the **mandatory lifecycle every feature must follow**, from initial
request through to acceptance and maintenance. It is one of the project's core governance
documents. **No feature may skip or reorder a phase without formal approval from Ahmed**,
recorded per `docs/00-governance/change-management-policy.md`.

This document operationalizes `Project-Constitution.md` §2 and §5 at the level of detail
needed to actually run a feature through the process. Team roles and responsibilities are
defined in `docs/Team-Management.md` §1 and are not repeated here — this document assumes
you already know who Ahmed, Mohamed, and Abukar are and what Round Robin means, and focuses
purely on the phases themselves.

---

## 1. How to Read This Document

- The lifecycle has **13 phases (0–12)**, run in order, for every feature.
- Every phase below has the same shape: **Purpose, Owner, Reviewer, Inputs, Outputs, Entry
  Criteria, Exit Criteria, Deliverables.**
- The `Status` column in the Feature Assignment Register (`docs/Team-Management.md` §7) uses
  the phase names below as its vocabulary — this document is where each status is actually
  defined; the register just records which phase a given feature is currently in.
- §5 (Quality Gates) explains how phases are enforced; §6 (Failure Handling) explains what
  happens when a phase doesn't pass.

---

## 2. The Lifecycle

### Phase 0 — Feature Request

| Field | Detail |
|---|---|
| Purpose | Capture a proposed feature, enhancement, or business change before any preparation effort is committed. |
| Owner | Anyone may originate a request (Ahmed, Mohamed, Abukar, or a stakeholder relayed through Ahmed); Ahmed captures and owns it. |
| Reviewer / Approval | Ahmed (Project Lead). |
| Inputs | A business need tied to one of the 14 approved modules (`Project-Overview.md` §6 Scope), or a documented scope change. |
| Outputs | A new row (or sub-feature ID) in the Feature Assignment Register, `docs/Team-Management.md` §7. |
| Entry Criteria | None — this is the starting point of the lifecycle. |
| Exit Criteria | Ahmed has approved the request as in-scope and worth preparing. |
| Deliverables | Feature Request, Initial Scope, Business Justification. |

### Phase 1 — Feature Assignment

| Field | Detail |
|---|---|
| Purpose | Record ownership and tracking details before preparation work begins. |
| Owner | Ahmed. |
| Reviewer | N/A — administrative phase. |
| Inputs | Approved Feature Request (Phase 0). |
| Outputs | Register row populated with Feature Owner (preparation is always Ahmed — see `Team-Management.md` §1/§3), Priority, and Dependencies on other modules. |
| Entry Criteria | Feature Request approved. |
| Exit Criteria | Register row complete; `Status` set to `Assigned`. |
| Deliverables | Updated Feature Assignment Register entry. |

### Phase 2 — Business Discovery

| Field | Detail |
|---|---|
| Purpose | Understand the business need before any solution is designed. |
| Owner | Ahmed (Business Architect). |
| Reviewer | N/A — this phase produces a draft, not yet reviewed. |
| Inputs | Feature Request; `docs/04-business/stakeholders-and-personas.md`; `docs/04-business/business-decision-register.md`; `docs/Project-Glossary.md`; related existing Business Specifications for consistency. |
| Activities | Discover requirements; identify stakeholders; identify assumptions; ask clarification questions rather than assume; identify business risks. |
| Outputs | Draft Business Specification, `04-business/modules/<module>/business-specification.md`. |
| Entry Criteria | Feature Assignment complete (Phase 1 exit criteria met). |
| Exit Criteria | A complete draft exists, covering scope, business rules, workflows, and acceptance criteria. |
| Deliverables | Business Specification (`Draft`). |

### Phase 3 — Business Review

| Field | Detail |
|---|---|
| Purpose | Independently validate business correctness before technical work begins. |
| Owner | Ahmed (submits for review). |
| Reviewer | **Mohamed or Abukar.** Ahmed authored the document and may not approve his own work — see `Project-Constitution.md` §9 and `Team-Management.md` §2 (no one reviews their own work, without exception, including documentation). |
| Inputs | Draft Business Specification. |
| Review checks | Scope, business rules, workflows, dependencies — per the Business Specification section of `docs/07-validation-and-qa/review-checklists.md`. |
| Outputs | `Approved` Business Specification, or `Changes Requested` (§6 Failure Handling). |
| Entry Criteria | Draft Business Specification complete (Phase 2 exit criteria met). |
| Exit Criteria | Reviewer has explicitly signed off; document status = `Approved`. |
| Deliverables | Approved Business Specification. |

### Phase 4 — Technical Design

| Field | Detail |
|---|---|
| Purpose | Design how the approved business need will be technically built. |
| Owner | Ahmed (Technical Architect). |
| Reviewer | N/A — drafting phase. |
| Inputs | Approved Business Specification; `docs/02-architecture/*`; `docs/03-standards/*`. |
| Include | Architecture fit, data model impact, API impact, security considerations, validation strategy, performance considerations. |
| Outputs | Draft Technical Design, `05-technical-design/modules/<module>/technical-design.md`. Any new architecture decision required is raised as an ADR (`02-architecture/adr/`) and approved before the design may rely on it. |
| Entry Criteria | Business Specification `Approved` (Phase 3 exit criteria met). |
| Exit Criteria | Complete draft exists, conforming to current architecture and standards. |
| Deliverables | Technical Design (`Draft`). |

### Phase 5 — Technical Review

| Field | Detail |
|---|---|
| Purpose | Independently validate the design before planning implementation. |
| Owner | Ahmed (submits for review). |
| Reviewer | **Mohamed or Abukar** — same independent-review rule as Phase 3. |
| Inputs | Draft Technical Design. |
| Review checks | Architecture consistency, standards compliance, security, scalability, maintainability — per the Technical Design section of `review-checklists.md`. |
| Outputs | `Approved` Technical Design, or `Changes Requested` (§6). |
| Entry Criteria | Draft Technical Design complete. |
| Exit Criteria | Reviewer has signed off; document status = `Approved`. |
| Deliverables | Approved Technical Design. |

### Phase 6 — Implementation Planning

| Field | Detail |
|---|---|
| Purpose | Break the approved design into a concrete, sequenced build plan. |
| Owner | Ahmed. |
| Reviewer | **Mohamed or Abukar** — same independent-review rule; ideally whichever of the two did not review the Technical Design, for workload balance. |
| Inputs | Approved Technical Design; `docs/03-standards/git-workflow-and-branching.md`. |
| Include | Scope, files/components affected, risks, dependencies, estimated effort. |
| Outputs | `Approved` Implementation Plan, `06-implementation-planning/modules/<module>/implementation-plan.md`. |
| Entry Criteria | Technical Design `Approved`. |
| Exit Criteria | Plan drafted and reviewed; status = `Approved`. |
| Deliverables | Approved Implementation Plan. |

### Phase 7 — Ready for Development

| Field | Detail |
|---|---|
| Purpose | Final checkpoint before any code is written. |
| Owner | Ahmed. |
| Reviewer | N/A — a verification checkpoint, not a new review. |
| Inputs | All three preparation documents. |
| Verify | Business Specification approved; Technical Design approved; Implementation Plan approved; required standards/architecture references are current. |
| Outputs | `Status` set to `Ready for Development`; Round Robin (`Team-Management.md` §4) determines the implementer. |
| Entry Criteria | Phases 2–6 all complete with `Approved` outputs. |
| Exit Criteria | All four items verified; an implementer is assigned. |
| Deliverables | Register updated with `Implemented By` and `Assigned Date`. |

### Phase 8 — Implementation

| Field | Detail |
|---|---|
| Purpose | Build the approved feature. |
| Owner | The assigned developer (Ahmed, Mohamed, or Abukar, per Round Robin). |
| Reviewer | N/A during this phase — review happens in Phase 9. |
| Inputs | Approved Business Specification, Technical Design, Implementation Plan; `docs/03-standards/*`. |
| Rules | Follow documentation exactly; do not invent requirements; do not modify unrelated modules; follow project standards. |
| Outputs | Working code on a feature branch per `git-workflow-and-branching.md`. |
| Entry Criteria | `Ready for Development` (Phase 7 exit criteria met). |
| Exit Criteria | Implementation complete and self-tested against the Implementation Plan's scope; ready for review. |
| Deliverables | Implemented feature; `Started Date` and progress recorded in the Register. |

### Phase 9 — Implementation Review

| Field | Detail |
|---|---|
| Purpose | Independently verify implementation quality before validation. |
| Owner | The assigned developer (submits for review). |
| Reviewer | Per `Team-Management.md` §5: **Ahmed**, unless Ahmed implemented the feature, in which case **Mohamed or Abukar**. No developer ever reviews their own implementation. |
| Inputs | Implemented code; the Implementation section of `review-checklists.md`. |
| Verify | Coding standards, business compliance (matches the Business Specification exactly), security, performance, documentation updates. |
| Outputs | Approved implementation, or findings returned to the developer (§6). |
| Entry Criteria | Implementation complete (Phase 8 exit criteria met). |
| Exit Criteria | Reviewer has signed off. |
| Deliverables | Reviewed, merge-ready implementation. |

### Phase 10 — Validation & QA

| Field | Detail |
|---|---|
| Purpose | Validate the completed, reviewed feature end to end. |
| Owner | The Phase 9 implementation reviewer (per `docs/00-governance/documentation-architecture.md` §13.2). |
| Reviewer | N/A — this phase is itself the verification step. |
| Inputs | Reviewed implementation; `docs/07-validation-and-qa/test-strategy.md`; the feature's own acceptance criteria from its Business Specification. |
| Include | Functional testing, business rule validation, security testing, edge-case testing, regression testing. |
| Outputs | Validation Report, `07-validation-and-qa/modules/<module>/validation-report.md`. |
| Entry Criteria | Implementation Review `Approved` (Phase 9 exit criteria met). |
| Exit Criteria | All validation activities pass; report status = `Approved`. |
| Deliverables | Approved Validation Report. |

### Phase 11 — Feature Acceptance

| Field | Detail |
|---|---|
| Purpose | Formally accept the feature as complete. |
| Owner | Ahmed. |
| Reviewer | N/A — administrative closure of a feature that has already passed every prior gate. |
| Inputs | Approved Validation Report; confirmation Phases 0–10 are all complete. |
| Requirements | All phases completed; validation passed; reviews completed; documentation current. |
| Outputs | Feature marked `Feature Accepted`. |
| Entry Criteria | Validation `Approved` (Phase 10 exit criteria met). |
| Exit Criteria | Ahmed confirms and records acceptance. |
| Deliverables | `Team-Management.md` §7 register updated (`Status = Feature Accepted`, `Completed Date` recorded); `decision-log.md` updated if the feature involved an ADR. |

### Phase 12 — Maintenance

| Field | Detail |
|---|---|
| Purpose | Govern what happens to an accepted feature afterward. |
| Owner | Ahmed — any future change re-enters at the appropriate earlier phase. |
| Reviewer | Whichever phase the change re-enters at. |
| Inputs | A change request, bug report, or business rule change against an already-accepted feature. |
| Rules | Follows `docs/00-governance/change-management-policy.md`. A business rule change requires the Business Specification to be updated and re-approved (re-entering at Phase 2–3) before any implementation reflects it — code never leads a business decision, including a change to one. |
| Outputs | Either no action (feature remains accepted, unchanged), or a new pass through the relevant phases. |
| Entry Criteria | `Feature Accepted` (Phase 11) — Maintenance is the permanent resting state after acceptance. |
| Exit Criteria | N/A — ongoing for the life of the feature. |
| Deliverables | Updated documents (only the ones affected), each with a new Version History entry. |

---

## 3. AI Responsibilities

Before doing any work on a feature, AI must verify it has access to:

- `docs/Project-Overview.md`
- `docs/Project-Constitution.md`
- `docs/Documentation-Map.md`
- `docs/Team-Management.md`
- The relevant module's Business Specification (once past Phase 2)
- The relevant module's Technical Design (once past Phase 4)
- The relevant `docs/03-standards/*` documents for the task at hand

**If required context is missing, or the feature's current phase is unclear, AI must stop
and request it. AI must never guess.**

AI operating within a given phase follows that phase's Owner/Reviewer assignment exactly —
AI assisting Ahmed in Phase 2 is drafting on Ahmed's behalf, not bypassing Phase 3's
independent human review. AI never performs both the drafting and the reviewing role for
the same artifact.

---

## 4. Quality Gates

A feature cannot advance to the next phase until:

1. The current phase's **Exit Criteria** are met, and
2. Where the phase specifies a **Reviewer**, that reviewer has explicitly signed off — not
   silence, not implicit approval.

Gate failures are handled per §5 below, never by proceeding anyway regardless of schedule
pressure (`Project-Constitution.md` §9, "Quality Over Speed").

| Phase | Gate type |
|---|---|
| 0 — Feature Request | Approval (Project Lead) |
| 1 — Feature Assignment | Administrative |
| 2 — Business Discovery | None (drafting) |
| 3 — Business Review | **Review gate** (independent reviewer) |
| 4 — Technical Design | None (drafting) |
| 5 — Technical Review | **Review gate** (independent reviewer) |
| 6 — Implementation Planning | **Review gate** (independent reviewer) |
| 7 — Ready for Development | Verification checkpoint |
| 8 — Implementation | None (build) |
| 9 — Implementation Review | **Review gate** (no self-review) |
| 10 — Validation & QA | Verification (pass/fail) |
| 11 — Feature Acceptance | Administrative closure |
| 12 — Maintenance | Re-enters the relevant gate on any future change |

---

## 5. Failure Handling

- **Business Review fails (Phase 3):** `Changes Requested` is recorded on the Business
  Specification with specific findings. The feature returns to Phase 2 for revision by
  Ahmed and re-enters Phase 3 once ready. It does not proceed to Technical Design.
- **Technical Review fails (Phase 5):** Same pattern — returns to Phase 4. If the finding
  reveals the Business Specification itself was ambiguous or wrong, it returns further, to
  Phase 2, and Phase 3 is redone once corrected.
- **Implementation Review fails (Phase 9):** Findings are returned to the developer; the
  feature returns to Phase 8 for fixes and re-enters Phase 9 once ready. Repeated failures
  on the same feature are escalated to Ahmed per `Team-Management.md` §11.
- **Validation fails (Phase 10):** If the defect is an implementation bug, it returns to
  Phase 8. If the defect reveals the Technical Design was flawed, it returns to Phase 4. If
  it reveals the Business Specification was wrong or incomplete, it returns to Phase 2. The
  Validation Report records which.
- **Security issues discovered (any phase):** Escalated immediately per `Team-Management.md`
  §11, regardless of current phase. The feature is placed `On Hold` until
  `docs/02-architecture/security-architecture.md` and
  `docs/03-standards/security-coding-standards.md` concerns are resolved, then resumes at
  the phase where the issue was found.
- **Scope changes during implementation (Phase 8 or later):** Implementation stops. The
  change is treated as a new business decision — the Business Specification is updated and
  re-approved (Phase 2–3) before implementation resumes, per
  `docs/00-governance/change-management-policy.md`. Ahmed decides whether in-progress work
  is salvageable or restarted.

In every failure case, the feature's row in `Team-Management.md` §7 records the regression
in its `Notes` column, and `Status` reverts to the phase it returned to — it never stays
marked at a later phase while the actual work is happening earlier.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial approved Development Lifecycle |
| 1.1 | 2026-08-02 | Ahmed | Phase 2 now references `docs/Project-Glossary.md` (moved from `00-governance/glossary.md`) |
| 1.2 | 2026-08-02 | Ahmed | Phase 2 Inputs now include `docs/04-business/business-decision-register.md` |
