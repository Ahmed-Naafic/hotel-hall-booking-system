---
title: "Hotel Management — Business Specification"
document_type: Business Specification
module: 03-hotel-management
status: Approved
owner: Ahmed
reviewer: Mohamed or Abukar (per documentation-architecture.md §4, no self-review)
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md", "docs/Project-Glossary.md", "docs/04-business/modules/01-authentication-and-account-management/business-specification.md"]
version: 1.4
last_updated: 2026-08-31
---

# Hotel Management — Business Specification
## Hotel Hall Booking Management System

> **Dependency note:** `docs/04-business/stakeholders-and-personas.md` is a formal dependency
> of every Business Specification (`documentation-architecture.md` §10.2) but is currently
> `Not Started`. This document grounds its actors, as `01-authentication-and-account-management/business-specification.md`
> does, in the approved Target Users table in `Project-Overview.md` §8. It should be
> reconciled against `stakeholders-and-personas.md` once that document is authored.

---

## 1. Purpose

This document defines the business rules, hotel lifecycle, business capabilities, user
journeys, and acceptance criteria for **Hotel Management** — the module governing the Hotel
as a business entity and tenant on the Platform: its registration, profile, application
review status, approval outcome, and the operational-eligibility state (active, suspended,
restricted) that determines whether it may operate.

This module owns the **Hotel's own business lifecycle** — what state a Hotel is in at any
point, and what causes it to move between states (§6). It does not own the Hotel Manager's
identity, credentials, login, or session (Authentication & Account Management, Module 1); it
does not own a Hotel's Halls, their availability, pricing, or customer-facing visibility
mechanics (Hall Management, Module 4); and it does not own the interface or workflow through
which a Platform Administrator actually performs a review, approval, rejection, or suspension
action (Administration & Platform Management, Module 13). §3 defines these boundaries
explicitly.

---

## 2. Scope

### 2.1 In Scope

- Hotel registration as a business entity, following Hotel Manager account creation (Module 1).
- Hotel profile completion — the business-profile content Module 1 §2.2 attributes to this
  module.
- Hotel application submission for Platform Administrator review.
- Hotel application review status: Under Review, Approved, Rejected.
- Editing a rejected application and resubmitting it (`BDR-010`).
- Withdrawing a pending application (`BDR-011`).
- Hotel activation upon approval.
- Hotel suspension and deactivation, and the Platform Administrator's exclusive authority
  over it (`BDR-012`).
- Restriction and review triggered by invalid required information (`BDR-013`).
- Ordinary Hotel profile changes, which do not require re-review (`BDR-014`).
- Critical Hotel information changes, which require Platform Administrator review before
  taking full effect (`BDR-014`).
- The eligibility signal this module provides to Hall Management — whether a Hotel's Halls
  may be visible — without owning the visibility mechanism itself (§3).

### 2.2 Out of Scope

- **Hotel Manager account creation, credentials, login, logout, verification, password
  reset/change, and session validity** — owned by Authentication & Account Management
  (Module 1); referenced here only where this module's application/operational state affects
  account-level access (Module 1 §5.2, §7.2, BR-AUTH-03, BR-AUTH-04, BR-AUTH-07).
- **Customer accounts and profiles** — Customer Management (Module 2).
- **Hall creation, hall details, hall availability, hall pricing, and hall customer-facing
  visibility mechanics** — Hall Management (Module 4). This module defines only whether a
  Hotel is eligible to have Halls visible (§6, §7); how that visibility is actually
  implemented is Hall Management's concern.
- **The Platform Administrator's review interface, workflow, and administrative tooling** for
  performing an approval, rejection, suspension, or deactivation action — Administration &
  Platform Management (Module 13). This module defines the Hotel-side states and transitions
  those actions produce, not the actions' interface or workflow — the same boundary Module 1
  §2.2 already draws for the same review workflow.
- **Multi-branch or multi-location Hotel structures** — explicitly out of scope per `BDR-008`:
  one Hotel account represents exactly one physical location.
- Booking, payment, staff, and event management — each module's own scope
  (`Project-Overview.md` §7).
- Any specific numeric or procedural detail not settled by an approved Business Decision
  (e.g. which profile fields are "critical," the precise mechanics of "restriction," a cap on
  rejection/resubmission cycles) — tracked as pending business decisions (§11), not decided
  here.

### 2.3 Referenced Business Decisions

Per `business-decision-register.md` §6, this specification references rather than restates
the following approved decisions:

| BDR | Title | Relevance to this module |
|---|---|---|
| `BDR-001` | Platform Type | The Platform is a marketplace connecting independently-operating Hotels and Customers — this module governs a Hotel's own lifecycle without inserting Platform operational involvement into how a Hotel runs itself. |
| `BDR-003` | Hotel Approval Process | The foundational decision this entire module operationalizes: manual Platform Administrator approval is required before a Hotel may list Halls or receive Bookings (§6, §7). |
| `BDR-008` | Multi-Branch Hotels | One Hotel account represents exactly one physical location (§7, BR-HOTEL-13). |
| `BDR-010` | Rejected Hotel Application Handling | A rejected Hotel may edit and resubmit its application (§6, §7, HM7–HM8). |
| `BDR-011` | Pending Hotel Application Withdrawal | A Hotel may withdraw a pending application before a decision (§6, §7, HM9). |
| `BDR-012` | Hotel Suspension Authority | An approved Hotel may be suspended or deactivated; only the Platform Administrator may do so (§6, §7, HM11). |
| `BDR-013` | Hotel Information Validity & Restriction | Invalid required information triggers restriction and review (§6, §7, HM14). |
| `BDR-014` | Hotel Profile Change Review Policy | Ordinary changes require no re-review; critical changes require Platform Administrator review before taking full effect (§6, §7, HM12–HM13). |
| `BDR-015` | Required Hotel Business-Profile Content | Defines the required, optional, and custom-field structure a Hotel's profile must satisfy before it may reach Profile Complete (§7, BR-HOTEL-02). |
| `BDR-017` | Hotel Geographic Location Capture | Defines the approved coordinate-plus-address location capture and OpenStreetMap workflow. |

---

## 3. Feature Boundaries

Hotel Management governs the Hotel as a business entity and its lifecycle on the Platform.
It does not govern the identity, credentials, or authentication of the Hotel Manager account
that acts on the Hotel's behalf — that remains Authentication & Account Management's
(Module 1) responsibility. This module begins from the premise that an authenticated Hotel
Manager account already exists (Module 1); it does not re-define how that account is
created, authenticated, verified, or managed.

**Boundary with Module 1 (Identity & Access Management):**

- **Hotel Management** defines: "The Hotel application is approved" — the business outcome,
  and what it makes the Hotel eligible to do.
- **Identity & Access Management (Module 1)** defines: "Whether the associated Hotel Manager
  identity can authenticate and access authorized resources" — the effect that outcome has on
  login and session behavior (Module 1 §5.2, §7.2, BR-AUTH-04).

This module does not duplicate Module 1's account-lifecycle states (Registered, Profile
Complete, Submitted/Under Review, Approved/Active, Rejected, Deactivated — Module 1 §5.2). It
is the upstream source of truth for the Hotel-entity decisions (approval, rejection,
suspension, restriction) that Module 1's account states reflect for authentication-gating
purposes.

**Boundary with Module 4 (Hall Management):** Hall Management remains a separate feature.
This module establishes only whether a Hotel is approved/eligible to operate (§6); Hall
Management owns the detailed hall lifecycle (creation, pricing, availability) and the
mechanics of customer-facing visibility. A Hotel may prepare its Halls before approval (§6,
BR-HOTEL-04), but the visibility/listing mechanism itself is defined by Hall Management, not
here.

**Boundary with Module 13 (Administration & Platform Management):** The Platform
Administrator's review, approval, rejection, suspension, and deactivation actions are
performed through Administration & Platform Management's interface and workflow. This module
governs only the Hotel-side states and transitions those actions produce (§6, §7,
BR-HOTEL-14) — consistent with Module 1 §2.2's identical boundary for the same review
workflow.

---

## 4. Actors

Sourced from `Project-Overview.md` §8 (Target Users) and `Project-Glossary.md` §3, pending
`stakeholders-and-personas.md`. No actor beyond the approved Target Users is introduced.

| Role | Description | Relevance to Hotel Management |
|---|---|---|
| **Hotel Manager** | The account role representing a Hotel on the Platform (`Project-Glossary.md`), with authority to manage that Hotel's Halls, Bookings, Staff, and Events once approved. | Performs every Hotel-side action in this module: registers the Hotel, completes its profile, submits/edits/resubmits/withdraws its application, and submits profile changes. Account creation, credentials, and login are Module 1's concern (§3). |
| **Platform Administrator** | The account role that operates the Platform itself — onboarding Hotels, overseeing platform health, and handling cross-tenant administration (`Project-Glossary.md`). | Reviews and decides Hotel applications (approve/reject), controls suspension and deactivation of approved Hotels (`BDR-012`), and reviews restriction cases and critical information changes (`BDR-013`, `BDR-014`). The interface/workflow this actor uses is Module 13's concern (§3). |

---

## 5. Business Capabilities

- **Hotel Registration** — establishing a Hotel as a business entity on the Platform.
- **Profile Management** — completing and maintaining the Hotel's business-profile
  information.
- **Application Submission & Review Tracking** — submitting an application and tracking its
  review status.
- **Application Outcome Handling** — responding to approval, rejection (with edit and
  resubmission), or withdrawal.
- **Operational Eligibility Control** — activation upon approval; suspension and deactivation
  by the Platform Administrator.
- **Information Validity Enforcement** — restriction and review when required information
  becomes invalid.
- **Change Impact Management** — distinguishing ordinary from critical profile changes, and
  gating critical changes behind Platform Administrator review.

---

## 6. Hotel Lifecycle

| State | Meaning | Entered When |
|---|---|---|
| **Registered** | Hotel exists as a business entity on the Platform; profile not yet complete. | Hotel Manager registers the Hotel, following Hotel Manager account creation (Module 1). |
| **Profile Complete** | Required business-profile information has been supplied. | Hotel Manager finishes profile completion (§7, BR-HOTEL-02). |
| **Submitted / Under Review** | Application has been submitted for Platform Administrator review. | Hotel Manager submits the application (`BDR-003`). |
| **Approved / Active** | Platform Administrator has approved the application; Hotel is operationally eligible. | Platform Administrator approval action (Module 13), per `BDR-003`. |
| **Rejected** | Platform Administrator has declined the application. | Platform Administrator rejection action (Module 13), per `BDR-003`. |
| **Rejected — Editing** | Hotel is revising a rejected application. | Hotel Manager begins editing after rejection (`BDR-010`). |
| **Resubmitted / Under Review** | An edited, previously-rejected application has been resubmitted. | Hotel Manager resubmits (`BDR-010`); re-enters the same review process as Submitted / Under Review. |
| **Withdrawn** | Hotel Manager withdrew a pending application before a decision. | Hotel Manager withdraws (`BDR-011`). |
| **Suspended** | Platform Administrator has suspended an approved Hotel; Hotel is not operationally eligible. | Platform Administrator suspension action (`BDR-012`). |
| **Deactivated** | Platform Administrator has deactivated an approved Hotel. | Platform Administrator deactivation action (`BDR-012`). |
| **Restricted / Under Review** | Required Hotel information has become invalid. | Detected per the applicable business process (`BDR-013`); Hotel is not fully operationally eligible until resolved. |
| **Pending Critical Change Review** | An Approved / Active Hotel has submitted a critical information change awaiting Platform Administrator review. | Hotel Manager submits a critical information change (`BDR-014`). |

A Hotel may only be listed to Customers, and only its Halls may become visible, while in the
**Approved / Active** state (`BDR-003`, §3). `BDR-012` does not distinguish the operational
meaning of **Suspended** from **Deactivated** beyond both being Platform-Administrator-
controlled and both ending operational eligibility; that distinction, if any, is tracked as a
pending business decision (§11). Likewise, what happens to a **Withdrawn** application
afterward, and whether a Hotel remains fully operational while in **Pending Critical Change
Review**, are not settled by any approved decision (§11).

---

## 7. Business Rules

| ID | Rule |
|---|---|
| BR-HOTEL-01 | A Hotel Manager must have an authenticated account (Module 1) before a Hotel may be registered on the Platform; this module governs the Hotel's own registration and lifecycle, not the account itself (§3). |
| BR-HOTEL-02 | A Hotel must complete its required business-profile information before it may submit an application for Platform Administrator review. Required fields: Hotel Name, Description, Location, Contact Phone. Optional fields: Email, Hotel Logo, Hotel Photos. A Hotel Manager may also supply optional custom key/value fields, which may never substitute for or satisfy a required field (`BDR-015`). Location contains latitude, longitude, and an editable customer-facing address; reverse-geocoding failure never blocks saving when coordinates and a manual address are present (`BDR-017`). |
| BR-HOTEL-03 | A Hotel must submit an application before it can be reviewed by a Platform Administrator; while Under Review, the Hotel is not operationally eligible (`BDR-003`). |
| BR-HOTEL-04 | A Hotel may prepare its Halls before its application is approved, but its Halls remain hidden from Customers until the Hotel reaches Approved / Active (`BDR-003`); the mechanics of hall visibility are Hall Management's concern (§3). |
| BR-HOTEL-05 | A Hotel only becomes operationally eligible — able to list Halls and receive Bookings — once its application reaches Approved / Active (`BDR-003`). |
| BR-HOTEL-06 | A rejected Hotel application may be edited by the Hotel Manager to address the rejection reason (`BDR-010`). |
| BR-HOTEL-07 | An edited, previously-rejected application may be resubmitted by the Hotel Manager for another Platform Administrator review (`BDR-010`). |
| BR-HOTEL-08 | A Hotel Manager may withdraw a pending application at any time before a Platform Administrator decision is made (`BDR-011`). |
| BR-HOTEL-09 | An Approved / Active Hotel may be suspended or deactivated; only a Platform Administrator holds the authority to do so (`BDR-012`). |
| BR-HOTEL-10 | If required Hotel information becomes invalid, the Hotel must be restricted and placed into review according to the applicable business process (`BDR-013`). |
| BR-HOTEL-11 | Ordinary Hotel profile changes take effect immediately and do not require Platform Administrator re-review (`BDR-014`). |
| BR-HOTEL-12 | Critical Hotel information changes require Platform Administrator review before the change becomes fully effective (`BDR-014`). |
| BR-HOTEL-13 | A Hotel account represents exactly one physical location; multi-branch or multi-location structures are out of scope (`BDR-008`). |
| BR-HOTEL-14 | The Platform Administrator's review, approval, rejection, suspension, and deactivation actions are performed through Administration & Platform Management's (Module 13) interface and workflow; this module governs only the Hotel-side states and transitions those actions produce (§3). |

---

## 7a. Location Capture (`BDR-017`)

The Location value contains `latitude`, `longitude`, and `address`. The Hotel
Manager places or moves a pin on an OpenStreetMap-based map; the captured coordinates are
authoritative for geographic calculations. The system attempts reverse geocoding and displays
the detected address for confirmation or editing. If reverse geocoding fails, the coordinates
are retained, a manual customer-facing address field is shown, and that address is required
before saving. Nearby-Hotel search is not part of this scope and the Hotel approval flow is
unchanged.

## 8. User Journeys

| # | Journey | Preconditions | Flow | Result |
|---|---|---|---|---|
| HM1 | Hotel registration | Hotel Manager has an authenticated account (Module 1) | Hotel Manager registers a new Hotel business entity. | Hotel created in **Registered** state (§6). |
| HM2 | Profile completion | Hotel is Registered | Hotel Manager supplies required business-profile information. | Hotel reaches **Profile Complete** (BR-HOTEL-02). |
| HM3 | Application submission | Hotel is Profile Complete | Hotel Manager submits the application for review. | Hotel reaches **Submitted / Under Review** (BR-HOTEL-03). |
| HM4 | Application pending | Application submitted | No Hotel Manager action; Platform Administrator is reviewing (Module 13). | Hotel remains **Under Review**; not operationally eligible (BR-HOTEL-03). |
| HM5 | Administrator approval | Platform Administrator approves (Module 13, `BDR-003`) | — | Hotel reaches **Approved / Active**; operationally eligible (BR-HOTEL-05). |
| HM6 | Administrator rejection | Platform Administrator rejects (Module 13, `BDR-003`) | — | Hotel reaches **Rejected** (§6). |
| HM7 | Rejected hotel editing its application | Hotel is Rejected | Hotel Manager edits the application to address the rejection reason. | Hotel reaches **Rejected — Editing** (BR-HOTEL-06). |
| HM8 | Rejected hotel resubmitting | Hotel has edited its rejected application | Hotel Manager resubmits. | Hotel reaches **Resubmitted / Under Review**, re-entering HM4 (BR-HOTEL-07). |
| HM9 | Withdrawing a pending application | Hotel is Under Review | Hotel Manager withdraws the application. | Hotel reaches **Withdrawn** (BR-HOTEL-08). |
| HM10 | Approved hotel becoming active | Same trigger as HM5 | — | Hotel may now list Halls and receive Bookings, subject to Hall Management's own rules (BR-HOTEL-05). |
| HM11 | Approved hotel being suspended | Hotel is Approved / Active | Platform Administrator suspends the Hotel (Module 13, `BDR-012`). | Hotel reaches **Suspended**; not operationally eligible (§6). |
| HM12 | Critical profile information changing | Hotel is Approved / Active | Hotel Manager submits a change to critical information. | Hotel reaches **Pending Critical Change Review**; change awaits Platform Administrator review before taking full effect (BR-HOTEL-12). |
| HM13 | Ordinary profile change | Hotel is Approved / Active | Hotel Manager submits a change to ordinary (non-critical) profile information. | Change takes effect immediately; no review required (BR-HOTEL-11). |
| HM14 | Invalid required information requiring review | Hotel is Approved / Active | Required information is found to be invalid, per the applicable business process. | Hotel reaches **Restricted / Under Review** (BR-HOTEL-10). |
| HM15 | Customer-facing visibility boundary after approval | Hotel reaches Approved / Active | — | Hotel's Halls become eligible for Customer-facing visibility; the visibility mechanism itself is Hall Management's concern (Module 4, §3). |

---

## 9. Exception Scenarios

| Scenario | Business Rule | Expected Business Behavior |
|---|---|---|
| Incomplete application | BR-HOTEL-02, BR-HOTEL-03 | A Hotel Manager cannot submit an application until required profile information is complete; submission is blocked. |
| Rejected application | BR-HOTEL-06, BR-HOTEL-07 | The Hotel is shown its actual Rejected status and the path to edit and resubmit (§6, HM7–HM8); it is not treated as a dead end. |
| Withdrawal | BR-HOTEL-08 | A withdrawn application ends the pending review; what a Hotel Manager may do afterward (e.g. submit a new application) is not defined by any approved decision (§11). |
| Attempted operation before approval | BR-HOTEL-05 | A Hotel that is not yet Approved / Active attempting an operational action (e.g. listing a Hall, receiving a Booking) is blocked — consistent with how Module 1's BR-AUTH-04 and BR-AUTH-07 already handle the account-level effect of the same condition. |
| Suspended hotel attempting to operate | BR-HOTEL-09 | A Suspended or Deactivated Hotel attempting an operational action is blocked, the same as a not-yet-approved Hotel (§6). |
| Invalid required information | BR-HOTEL-10 | A Hotel with invalid required information is restricted and placed into review; it is not silently left in an inconsistent state (§6, HM14). |
| Critical profile change requiring review | BR-HOTEL-12 | A submitted critical information change does not take full effect until Platform Administrator review is complete; whether the Hotel continues operating on its prior information in the meantime is not defined by any approved decision (§11). |

---

## 10. Acceptance Criteria

Written in Given/When/Then form against the journeys in §8 and rules in §7.

1. **Profile required before submission** — Given a Hotel in Registered state, when the Hotel
   Manager attempts to submit an application before completing required profile information,
   then submission is blocked (BR-HOTEL-02, BR-HOTEL-03).
2. **Submission reaches review** — Given a Hotel in Profile Complete state, when the Hotel
   Manager submits the application, then the Hotel reaches Submitted / Under Review
   (BR-HOTEL-03, HM3).
3. **Halls hidden before approval** — Given a Hotel that is not yet Approved / Active, when
   the Hotel Manager prepares Hall information, then the Halls are not visible to Customers
   (BR-HOTEL-04).
4. **Approval unlocks operation** — Given a Hotel reaches Approved / Active, when the Hotel
   Manager attempts an operational action, then it succeeds, subject to Hall Management's own
   rules (BR-HOTEL-05, HM10).
5. **Rejected application may be edited and resubmitted** — Given a Hotel in Rejected state,
   when the Hotel Manager edits the application and resubmits it, then the Hotel reaches
   Resubmitted / Under Review and is reviewed again (BR-HOTEL-06, BR-HOTEL-07, HM7–HM8).
6. **Pending application may be withdrawn** — Given a Hotel in Submitted / Under Review,
   when the Hotel Manager withdraws the application, then the Hotel reaches Withdrawn and is
   no longer under review (BR-HOTEL-08, HM9).
7. **Suspension blocks operation** — Given a Hotel in Approved / Active, when a Platform
   Administrator suspends it, then the Hotel can no longer perform operational actions
   (BR-HOTEL-09, HM11).
8. **Only Platform Administrator may suspend** — Given an Approved / Active Hotel, when any
   actor other than a Platform Administrator attempts to suspend or deactivate it, then the
   action is refused (BR-HOTEL-09).
9. **Invalid information triggers restriction** — Given an Approved / Active Hotel whose
   required information becomes invalid, when this is detected, then the Hotel reaches
   Restricted / Under Review (BR-HOTEL-10, HM14).
10. **Ordinary changes take effect immediately** — Given an Approved / Active Hotel, when the
    Hotel Manager submits an ordinary profile change, then it takes effect without Platform
    Administrator review (BR-HOTEL-11, HM13).
11. **Critical changes require review** — Given an Approved / Active Hotel, when the Hotel
    Manager submits a critical information change, then the change does not become fully
    effective until a Platform Administrator reviews it (BR-HOTEL-12, HM12).
12. **Single location per Hotel** — Given a Hotel account, when it is registered, then it
    represents exactly one physical location, consistent with `BDR-008` (BR-HOTEL-13).

---

## 11. Pending Business Decisions

Per `Project-Constitution.md` §4 ("AI must never invent business rules") and
`documentation-standards.md` §13 (TBD items require an explicit reason and owner), the items
below are **not** informal questions — each is a genuine business decision this module needs,
tracked here until it is formally raised through `business-decision-register.md`'s own
process (`Decision-Making-Principles.md` §5) and recorded there as its own `BDR-0##` entry,
beginning at `Proposed` status per the register's lifecycle (§2).

None of these block the business rules and journeys in §6–§10, which hold regardless of how
each is eventually decided — only the specific parameter or mechanism is undetermined. Each
should reach `Approved` in the register before this module's Technical Design finalizes the
corresponding behavior.

| # | Pending Decision (Future BDR Title) | Category | Business Problem | Related Rules / Journeys |
|---|---|---|---|---|
| 1 | Rejection / Resubmission Cycle Limit | Hotel Policies | `BDR-010` approves edit-and-resubmit but does not define whether a cap or other handling applies to repeated rejection cycles. | BR-HOTEL-06, BR-HOTEL-07, HM7–HM8 |
| 2 | Post-Withdrawal Reapplication | Hotel Policies | `BDR-011` approves withdrawal but does not define whether, or how, a Hotel Manager may submit a new application afterward. | BR-HOTEL-08, HM9 |
| 3 | Suspension vs. Deactivation Distinction | Platform Policies | `BDR-012` approves both suspension and deactivation as Platform-Administrator-controlled but does not distinguish their operational meaning or the grounds for choosing one over the other. | BR-HOTEL-09, §6 |
| 4 | Restriction Scope & Applicable Business Process | Platform Policies | `BDR-013` approves restriction-and-review for invalid required information but does not define which fields are "required," what makes them "invalid," or the review process itself. | BR-HOTEL-10, HM14 |
| 5 | Ordinary vs. Critical Information Classification | Platform Policies | `BDR-014` approves the two-tier review model but does not define which specific profile fields are "ordinary" versus "critical." | BR-HOTEL-11, BR-HOTEL-12, HM12–HM13 |
| 6 | Hotel Operational Status During Critical-Change Review | Platform Policies | `BDR-014` does not define whether a Hotel remains fully operational (on its prior information) while a critical change is pending review, or is restricted during that window. | BR-HOTEL-12, HM12 |
| ~~7~~ | ~~Required Business-Profile Content~~ — **RESOLVED 2026-08-26, see `BDR-015`** | Hotel Policies | Required: Hotel Name, Description, Location, Contact Phone. Optional: Email, Hotel Logo, Hotel Photos. Optional custom key/value fields are permitted but may never substitute for a required field. | BR-HOTEL-02, HM2 |

---

## 12. Dependencies & References

- `Project-Overview.md` §7 (Scope), §8 (Target Users) — this module's mandate and actors.
- `docs/04-business/business-decision-register.md` — `BDR-001`, `BDR-003`, `BDR-008`,
  `BDR-010`–`BDR-014` (§2.3).
- `Project-Glossary.md` §3 — Hotel, Hotel Manager, Platform Administrator definitions used
  throughout.
- `docs/04-business/modules/01-authentication-and-account-management/business-specification.md`
  (`Approved`) — owns Hotel Manager account creation, credentials, and authentication; this
  module cross-references its §5.2, §7.2, BR-AUTH-03, BR-AUTH-04, and BR-AUTH-07 for the
  account-level effect of this module's decisions (§3).
- `docs/04-business/modules/04-hall-management/business-specification.md` (`Not Started`) —
  owns Hall creation, pricing, availability, and customer-facing visibility mechanics
  referenced but not defined here (§3, BR-HOTEL-04).
- `docs/04-business/modules/13-administration-and-platform-management/business-specification.md`
  (`Not Started`) — owns the Platform Administrator's review, approval, rejection, and
  suspension interface and workflow referenced but not defined here (§3, BR-HOTEL-14).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.4 | 2026-08-31 | Ahmed | Approved `BDR-017` and the structured Hotel Location business rules: coordinates plus editable address, non-blocking reverse-geocoding fallback, and no change to Hotel approval behavior. |
| 1.3-proposed | 2026-08-30 | AI-drafted, pending Ahmed approval | Added a proposed structured Hotel Location workflow and cross-reference to `BDR-017`; no approved business rule is changed. |
| 1.2 | 2026-08-26 | Ahmed | Resolves Pending Business Decision #7 (§11): `BDR-015` (Required Hotel Business-Profile Content) reached `Approved`. §2.3 references the new BDR; §7 `BR-HOTEL-02` now states the actual required fields (Hotel Name, Description, Location, Contact Phone), optional fields (Email, Hotel Logo, Hotel Photos), and the custom-field rule (never a substitute for a required field); §11 item 7 marked resolved rather than removed, preserving the traceability record. No other business rule or journey changed. Ahmed directed and reviewed this change directly in the same session `BDR-015` was approved; no separate Mohamed/Abukar review round occurred for this specific update, the same transparently-flagged deviation this module's own Technical Design v1.3 already used for an analogous Ahmed-directed correction. |
| 1.1 | 2026-08-09 | Ahmed | Status changed `Draft` → `Approved`: independent review by Mohamed or Abukar is complete, per `documentation-architecture.md` §4's no-self-review rule and the pre-review documentation-quality check performed prior to review. This document is now the authoritative business source of truth for Hotel Management — Technical Design may begin. |
| 1.0 | 2026-08-09 | Ahmed | Initial draft Business Specification for Hotel Management, grounded in `BDR-001`, `BDR-003`, `BDR-008`, and newly-recorded `BDR-010`–`BDR-014`. Not yet reviewed — see status. |
