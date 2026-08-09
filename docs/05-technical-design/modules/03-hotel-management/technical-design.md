---
title: "Hotel Management — Technical Design"
document_type: Technical Design
module: 03-hotel-management
status: Approved
owner: Ahmed
reviewer: Mohamed or Abukar (per documentation-architecture.md §4, no self-review)
depends_on: ["docs/04-business/modules/03-hotel-management/business-specification.md", "docs/04-business/business-decision-register.md", "docs/02-architecture/system-architecture-overview.md", "docs/02-architecture/data-architecture.md", "docs/02-architecture/security-architecture.md", "docs/02-architecture/architecture-principles.md", "docs/02-architecture/folder-structure.md", "docs/02-architecture/technology-stack.md", "docs/03-standards/api-standards.md", "docs/03-standards/database-standards.md", "docs/03-standards/security-coding-standards.md", "docs/03-standards/coding-standards.md", "docs/03-standards/naming-conventions.md", "docs/05-technical-design/modules/01-authentication-and-account-management/technical-design.md"]
version: 1.3
last_updated: 2026-08-10
---

# Hotel Management — Technical Design
## Hotel Hall Booking Management System

> **Relationship to other documents:** this document answers *how* Hotel Management is
> built, never *what* it does or *why* — every business rule and journey referenced below is
> defined once, in `business-specification.md` (`Approved`, v1.1), and cited here by ID
> (`BR-HOTEL-##`, `HM#`) rather than restated. Where this document and the Business
> Specification appear to disagree, the Business Specification governs
> (`documentation-standards.md` §2) and this document has a defect to correct. Where this
> document and an approved architecture or standards document appear to disagree, the more
> detailed/canonical document governs (`system-architecture-overview.md`'s own relationship
> rule) — except where §18 identifies a genuine, unresolved conflict *between* two already-
> approved documents, which is flagged rather than silently arbitrated.

---

## 1. Technical Overview

This Technical Design translates the `Approved` Hotel Management Business Specification
(v1.1) into a concrete technical architecture: components, domain model, data design, state
model, API contract, and module interactions — conforming to `architecture-principles.md`,
`system-architecture-overview.md`, `data-architecture.md`, and the Standards Layer
(`api-standards.md`, `database-standards.md`, `coding-standards.md`, `naming-conventions.md`).

It does not restate business rules, journeys, or acceptance criteria — every technical
decision below traces to one (§19, Traceability Matrix). It contains no Prisma schema, SQL,
Express controller implementation, or client (Flutter/React) code — those belong to
Implementation Planning and Development (`documentation-architecture.md` §12), once this
document reaches `Approved`.

Hotel Management is the technical realization of the Hotel as a **business entity and
tenant** (`data-architecture.md` §3–§4): its registration, profile, application lifecycle,
and operational-eligibility state. It is the second module in `Development-Roadmap.md`
Wave 1 ("Identity & Tenant Foundation"), depending only on Authentication & Account
Management (Module 1, `Approved` and implemented) and unblocked by any other module.

---

## 2. Architecture Context

### 2.1 Module Position

Per `system-architecture-overview.md` §6, this module is **"Hotel — Hotel (tenant) profile
and management,"** the backend module folder `hotels/` (`folder-structure.md` §4,
`naming-conventions.md` §4). It is one of the fourteen approved feature-based modules
(`architecture-principles.md` §3) and introduces no component outside that approved list.

### 2.2 Responsibilities

Directly realizing Business Specification §5 (Business Capabilities):

- **Hotel Registration** — establishing the Hotel business entity.
- **Profile Management** — Hotel profile completion and maintenance.
- **Application Submission & Review Tracking** — the application lifecycle and its status.
- **Application Outcome Handling** — approval, rejection (with edit/resubmit), withdrawal.
- **Operational Eligibility Control** — activation, suspension, deactivation.
- **Information Validity Enforcement** — restriction and review.
- **Change Impact Management** — ordinary vs. critical profile change handling.

### 2.3 Dependencies

| Dependency | Relationship |
|---|---|
| PostgreSQL + Prisma (`technology-stack.md`) | This module's persistence layer, per `database-standards.md`. |
| Authentication & Account Management (Module 1, `Approved`, implemented) | Provides the authenticated Hotel Manager identity and role claim (via the Access Gate) this module operates under; this module never re-implements identity, credentials, or session logic (§10). |
| Hall Management (Module 4, `Not Started`) | Consumes this module's operational-eligibility signal to decide whether a Hotel's Halls may be listed/visible (`BR-HOTEL-04`, `BR-HOTEL-05`); this module never owns Hall data (§10). |
| Administration & Platform Management (Module 13, `Not Started`) | Owns the Platform Administrator's review/approval/rejection/suspension **interface and workflow**; consumes this module's Hotel-lifecycle write interface to record its decisions (`BR-HOTEL-14`, §7, §10). |

### 2.4 Architectural Boundaries

Per Business Specification §3, restated technically:

- This module **owns** the Hotel entity, its profile, its application lifecycle, and its
  operational-eligibility state (§4–§6).
- This module **does not own** Hotel Manager identity/credentials/authentication (Module 1),
  Hall data (Module 4), or the Platform Administrator's review interface/workflow
  (Module 13) — §10 defines each interaction precisely.
- **§18 Item 1 (resolved 2026-08-10)** — `data-architecture.md` §9 and Module 1's Technical
  Design §2.4/§3.2 previously attributed "Hotel approval status" ownership to Module 13,
  conflicting with this boundary. Both documents have been corrected to match this Business
  Specification's approved boundary; see §18 for the resolution record.

---

## 3. Module Architecture

Internal components of the `hotels/` module (`folder-structure.md` §4), each with a single
responsibility (`architecture-principles.md` §4). No implementation code — conceptual
responsibility only.

| Component | Responsibility |
|---|---|
| **Hotel Component** | Creates and retrieves the Hotel entity (§4) — the aggregate root every other component operates on. The single point every other module resolves "which Hotel is this" through. |
| **Profile Component** | Manages Hotel profile data and profile-completion state (`BR-HOTEL-02`); classifies an incoming profile change as ordinary or critical and routes it accordingly (`BR-HOTEL-11`, `BR-HOTEL-12`, §8). |
| **Application Component** | Manages the application lifecycle: submission, editing after rejection, resubmission, withdrawal (`BR-HOTEL-03`, `BR-HOTEL-06`–`BR-HOTEL-08`, §7). |
| **Lifecycle (State) Component** | The single point that enforces valid Hotel state transitions (§6) — every other component requests a transition through this component; no other code path mutates Hotel status directly (`architecture-principles.md` §4). |
| **Eligibility Query Interface** | A narrow, read-only interface other modules (Module 1, Module 4) query to determine a Hotel's current operational eligibility, without exposing this module's internals (`architecture-principles.md` §5). |
| **Suspension / Restriction Component** | Handles suspension, deactivation (Platform-Administrator-triggered, `BR-HOTEL-09`), and restriction triggered by invalid required information (`BR-HOTEL-10`, §9). |

```mermaid
graph TD
    subgraph "Hotel Management (Module 3)"
        HC["Hotel Component"]
        PC["Profile Component"]
        AppC["Application Component"]
        LC["Lifecycle (State) Component"]
        EQ["Eligibility Query Interface"]
        SR["Suspension / Restriction Component"]
    end

    Client["Hotel Manager client (Module 1-authenticated)"] -->|register, profile, apply, edit, resubmit, withdraw| PC
    Client --> AppC
    PC --> HC
    AppC --> HC
    PC --> LC
    AppC --> LC
    SR --> LC
    LC --> HC

    AdminMod["Administration & Platform Management (Module 13)"] -.->|records approve/reject/suspend/deactivate decision, §7| AppC
    AdminMod -.-> SR

    AG["Access Gate (Module 1)"] -.->|authenticated identity + role| Client
    HallMod["Hall Management (Module 4)"] -.->|queries operational eligibility, §10| EQ
    EQ --> HC
```

---

## 4. Domain Model

Logical entities only, per `data-architecture.md` §4's convention — no Prisma models, no
columns.

| Entity | Business Purpose | Owning Component |
|---|---|---|
| **Hotel** | The persistent tenant entity — one record per Hotel, existing from registration onward. Holds profile data (content deliberately unspecified, §18 Item 7) and a current lifecycle status (§6). The aggregate root. | Hotel Component |
| **Hotel Application** | One record per review cycle — the initial submission, and a new record for each resubmission after rejection (`BR-HOTEL-07`). Captures the submission and its eventual decision. Historical, append-only — never overwritten. | Application Component |
| **Critical Information Change Request** | One record per critical-information change awaiting Platform Administrator review (`BR-HOTEL-12`) — the proposed change, its submission, and its eventual decision, independent of the Hotel's own status (§6, §18 Item 6). | Profile Component |

**Entities investigated but not modeled separately**, with rationale:

- **Hotel Profile** — not a separate entity. The Business Specification leaves "required
  business-profile content" entirely undefined (Pending Business Decision #7); modeling a
  granular profile sub-entity now would invent field-level structure no approved decision
  supports. Profile data is treated as an attribute set on **Hotel** itself, of deliberately
  unspecified shape.
- **Restriction Record** — not modeled as a dedicated entity. `BDR-013`'s "applicable
  business process" is undefined (Pending Business Decision #4); restriction is represented
  as a Hotel status value (§6) plus a generic Audit Record (§13), not a bespoke tracking
  entity whose shape would have to anticipate an undefined process.
- **Suspension Record** — not modeled as a dedicated entity, for the same reason. Suspension
  and deactivation are Hotel status values (§6); accountability (who, when, why) is captured
  through Audit Records (§13), consistent with how Module 1's Technical Design treats
  security-significant actions it doesn't own a dedicated entity for.

### 4.1 Relationships

- A **Hotel** is referenced by one or more Hotel Manager **User Accounts** (Module 1) — the
  Business Specification does not address whether more than one Hotel Manager account may
  represent one Hotel, but `Project-Glossary.md`'s approved definition of Hotel ("represented
  by *at least one* Hotel Manager account") supports a one-to-many relationship. This module
  never stores Module 1's identity/credential data — only a reference (§10).
- A **Hotel** has zero or more **Hotel Applications** over its lifetime, historically, but at
  most one *open* (Under Review) Application at a time (§5) — mirroring the same "at most one
  active request" pattern Module 1 already applies to its own Verification and Password
  Reset Requests.
- A **Hotel** has zero or more **Critical Information Change Requests** over its lifetime,
  but at most one *open* (pending decision) request at a time (§5).
- A **Hotel Application** and a **Critical Information Change Request** are each decided by
  exactly one Platform Administrator **User Account** (Module 1, referenced, never owned).

---

## 5. Data Architecture (Logical)

Business-purpose persistence design only, per `data-architecture.md`'s convention — no
Prisma schema, no SQL (`database-standards.md` governs the physical shape, not written here).

- **Ownership** — Hotel, Hotel Application, and Critical Information Change Request are
  owned exclusively by this module (`architecture-principles.md` §5); no other module reads
  or writes these tables directly — only through this module's defined interfaces (§3, §10).
- **Constraints** (business-level, not `CHECK`-constraint detail) —
  - A Hotel has exactly one current status (§6) at all times; the status is never null.
  - At most one *open* Hotel Application per Hotel (§4.1) — a new submission or resubmission
    is only valid when no other Application for that Hotel is currently Under Review.
  - At most one *open* Critical Information Change Request per Hotel (§4.1).
- **Audit requirements** — every state-changing action (§13) is recorded as an Audit Record
  with actor, action, and timestamp, per `api-standards.md` §19 and
  `Project-Constitution.md` §8 (Auditability) — the same cross-cutting pattern Module 1
  already uses (§18 Item 4 notes the same ownership gap for the Audit Record entity itself).
- **Historical information** — a Hotel Application is never overwritten; a resubmission
  creates a new Application record (§4), preserving the full review history without relying
  on soft delete. `database-standards.md` §9 explicitly distinguishes soft delete from
  suspension/deactivation, using a Hotel as its own illustrative example ("A Hotel being
  temporarily deactivated by a Platform Administrator is a different business concept from a
  Hotel being deleted") — this design follows that rule precisely: `deleted_at` is reserved
  for a genuinely disposable/erroneous Hotel record, never for Suspended, Deactivated, or any
  other lifecycle status (§6).
- **Classification** (`data-architecture.md` §13) — Hotel profile data is provisionally
  **Public** to **Internal** depending on the specific field (final classification depends on
  Pending Business Decision #7 resolving what the profile actually contains); no field
  currently anticipated by this module reaches **Restricted** classification (no payment
  credentials or authentication material are stored here — that remains Module 1's and
  Payment Management's domain).

---

## 6. State Machine

The Hotel's lifecycle status (Business Specification §6) is modeled as a single status field
on the **Hotel** entity. Two states from the Business Specification's lifecycle table are
deliberately **not** separate persisted status values, for reasons explained below —
transparently, not silently:

- **"Rejected — Editing"** is a client-side/workflow distinction, not a persisted status. A
  Rejected Hotel remains `REJECTED` at the data layer while its Hotel Manager drafts edits;
  the status changes only on actual resubmission (`BR-HOTEL-07`).
- **"Pending Critical Change Review"** is **not** modeled as a Hotel status change. This is a
  direct consequence of Pending Business Decision #6 (Hotel Operational Status During
  Critical-Change Review) being genuinely undefined: whether a Hotel remains fully
  operational during this window, or is restricted, is not decided. Modeling it as a Hotel
  status would silently pick an answer (restricted). Instead, the pending change is tracked
  entirely on the **Critical Information Change Request** entity (§4), independent of Hotel
  status — the technical design is deliberately parameterized to accommodate either
  resolution without a schema change, the same technique Module 1's Technical Design uses
  for its own undecided parameters.

### 6.1 Hotel Status

```mermaid
stateDiagram-v2
    [*] --> REGISTERED: Hotel Manager registers Hotel (HM1)
    REGISTERED --> PROFILE_COMPLETE: Profile completed (HM2, BR-HOTEL-02)
    PROFILE_COMPLETE --> UNDER_REVIEW: Application submitted (HM3, BR-HOTEL-03)
    UNDER_REVIEW --> APPROVED_ACTIVE: Module 13 approves (HM5, BDR-003)
    UNDER_REVIEW --> REJECTED: Module 13 rejects (HM6, BDR-003)
    UNDER_REVIEW --> WITHDRAWN: Hotel Manager withdraws (HM9, BR-HOTEL-08)
    REJECTED --> UNDER_REVIEW: Edited and resubmitted (HM7-HM8, BDR-010)
    APPROVED_ACTIVE --> SUSPENDED: Module 13 suspends (HM11, BR-HOTEL-09)
    APPROVED_ACTIVE --> DEACTIVATED: Module 13 deactivates (BR-HOTEL-09)
    APPROVED_ACTIVE --> RESTRICTED_UNDER_REVIEW: Invalid required information detected (HM14, BR-HOTEL-10)
    RESTRICTED_UNDER_REVIEW --> APPROVED_ACTIVE: Review resolved (process undefined, Pending Decision #4)
    WITHDRAWN --> [*]: Reapplication path undefined (Pending Decision #2)
```

### 6.2 Transition Table

| From | To | Trigger | Precondition | Result |
|---|---|---|---|---|
| — | `REGISTERED` | Hotel Manager registers a Hotel (HM1) | Hotel Manager has an authenticated account (Module 1) | Hotel entity created |
| `REGISTERED` | `PROFILE_COMPLETE` | Profile completion (HM2) | Required profile fields supplied (content TBD, §18 Item 7) | Hotel eligible to submit |
| `PROFILE_COMPLETE` | `UNDER_REVIEW` | Application submission (HM3) | Profile complete; no other open Application | Hotel Application created |
| `UNDER_REVIEW` | `APPROVED_ACTIVE` | Platform Administrator approves (HM5) | Module 13 authorization confirmed | Hotel operationally eligible (`BR-HOTEL-05`) |
| `UNDER_REVIEW` | `REJECTED` | Platform Administrator rejects (HM6) | Module 13 authorization confirmed | Application marked rejected |
| `UNDER_REVIEW` | `WITHDRAWN` | Hotel Manager withdraws (HM9) | Application still open | Application marked withdrawn |
| `REJECTED` | `UNDER_REVIEW` | Edit + resubmit (HM7–HM8) | New Application record created | Re-enters review (`BDR-010`) |
| `APPROVED_ACTIVE` | `SUSPENDED` | Platform Administrator suspends (HM11) | Module 13 authorization confirmed | Operational eligibility ends |
| `APPROVED_ACTIVE` | `DEACTIVATED` | Platform Administrator deactivates | Module 13 authorization confirmed | Operational eligibility ends |
| `APPROVED_ACTIVE` | `RESTRICTED_UNDER_REVIEW` | Invalid required information detected (HM14) | Detection mechanism undefined (§18 Item 4) | Operational eligibility suspended pending review |
| `RESTRICTED_UNDER_REVIEW` | `APPROVED_ACTIVE` | Review resolved favorably | Resolution process undefined (§18 Item 4) | Operational eligibility restored |

No transition exists out of `WITHDRAWN` (Pending Decision #2), a defined negative exit from
`RESTRICTED_UNDER_REVIEW` (Pending Decision #4), or reactivation out of `SUSPENDED`/
`DEACTIVATED` back to `APPROVED_ACTIVE` — all three absences are deliberate, not omissions.
**Added during technical review:** the original draft flagged the first two explicitly but
left reactivation silently absent; `BR-HOTEL-09` approves that a Hotel may be suspended or
deactivated but does not address whether either is reversible, so no reactivation transition
is shown, consistent with how `WITHDRAWN` and `RESTRICTED_UNDER_REVIEW`'s own open questions
are handled.

---

## 7. Application Review Workflow

Technical orchestration only; business policy is defined in the Business Specification and
never re-decided here.

1. **Submission** (HM3) — the Application Component creates a Hotel Application, requests a
   `PROFILE_COMPLETE → UNDER_REVIEW` transition from the Lifecycle Component (§6), and the
   Application becomes visible to Module 13's review workflow.
2. **Administrator review** — owned entirely by Module 13's own interface and workflow
   (`BR-HOTEL-14`); this module exposes no review UI.
3. **Approval / Rejection** — Module 13, after its own authorization check confirms the
   caller is a Platform Administrator, calls this module's Application Component through a
   defined service interface (`architecture-principles.md` §5 — an in-process call within the
   single Express backend, `system-architecture-overview.md` §5, not a second HTTP
   round-trip) to record the decision. The Lifecycle Component then executes the
   corresponding transition (§6).
4. **Resubmission** (HM7–HM8) — the Application Component creates a **new** Hotel Application
   record (§4) rather than mutating the rejected one, requests `REJECTED → UNDER_REVIEW`.
5. **Withdrawal** (HM9) — the Application Component marks the open Application withdrawn and
   requests `UNDER_REVIEW → WITHDRAWN`.

**Reconciliation for §2.4/§18's ownership conflict (resolved 2026-08-10):** this
service-interface pattern — Hotel Management owns and persists the Hotel/Application data
and exposes a narrow write interface; Module 13 owns the review action and calls it — is
consistent with *both* the Business Specification's boundary (Hotel Management owns the
data) and `architecture-principles.md` §5 (modules communicate through defined interfaces,
never direct table access). `data-architecture.md` §9 and Module 1's Technical Design
§2.4/§3.2 have been corrected to match (§18 Item 1); this pattern is now the agreed
architecture, not merely a proposal.

---

## 8. Profile Management

- **Profile creation** — occurs at `REGISTERED` (§6); fields are supplied incrementally until
  complete (`BR-HOTEL-02`).
- **Profile updates** — every update request is classified by the Profile Component as
  **ordinary** or **critical** before being applied.
- **Ordinary changes** (`BR-HOTEL-11`) — applied immediately to the Hotel entity; no Lifecycle
  Component transition, no Module 13 involvement.
- **Critical changes** (`BR-HOTEL-12`) — routed to a new Critical Information Change Request
  (§4) instead of being applied directly; the change takes effect only once Module 13
  approves it, through the same service-interface pattern as §7.
- **Field classification** (ordinary vs. critical) — **not decided here.** Pending Business
  Decision #5 leaves the exact field list undefined. The Profile Component's routing
  mechanism is fully specified (a classification lookup that decides immediate-apply vs.
  review-required); the classification data itself is treated as an injectable ruleset the
  component consults, not a hardcoded list — so the mechanism can be implemented and tested
  today, and the actual field classification supplied once Pending Business Decision #5 is
  resolved, without redesigning this component.
- **Validation** — request-shape validation (required fields present, correct types) happens
  before this component runs, per `coding-standards.md` §11 / `api-standards.md` §14; the
  specific completeness criteria for `PROFILE_COMPLETE` (§6) are equally dependent on Pending
  Business Decision #7 (Required Business-Profile Content).
- **Review interaction** — a Critical Information Change Request's approval/rejection follows
  the identical Module-13-calls-in pattern as §7's Application decisions.

---

## 9. Suspension / Restriction Architecture

**Technically known (approved, not reopened):**

- An `APPROVED_ACTIVE` Hotel may transition to `SUSPENDED` or `DEACTIVATED` (§6), each ending
  operational eligibility identically as far as this design is concerned.
- Only a Platform Administrator may trigger either transition (`BR-HOTEL-09`) — enforced by
  Module 13's own authorization check before it calls this module's interface (§7's pattern),
  never by this module re-implementing role checks Module 1/Module 13 already own.
- An `APPROVED_ACTIVE` Hotel may transition to `RESTRICTED_UNDER_REVIEW` when required
  information becomes invalid (`BR-HOTEL-10`).

**Genuinely dependent on Pending Business Decisions — not invented here:**

- **Suspension vs. Deactivation distinction** (Pending Decision #3) — both are modeled as
  sibling status values with identical technical effect (operational eligibility ends). If a
  future decision differentiates their behavior (e.g., different reactivation paths), it is
  an additive change to the Lifecycle Component (§3), not a redesign.
- **Restriction detection mechanism** (Pending Decision #4) — what makes information
  "invalid," and what automatically or manually triggers the `APPROVED_ACTIVE →
  RESTRICTED_UNDER_REVIEW` transition, is undefined. This design provides the status value
  and the transition itself (§6); it does not invent a detection process.
- **Restriction resolution process** (Pending Decision #4) — the exit path from
  `RESTRICTED_UNDER_REVIEW` back to `APPROVED_ACTIVE` (or elsewhere) is shown in §6 as a
  single resolved-favorably transition; no negative/alternate outcome is invented.

---

## 10. Module Interactions

- **Authentication & Account Management (Module 1, `Approved`, implemented)** — this module
  trusts the Access Gate's authenticated identity and role claim exactly as every other
  module does (`architecture-principles.md` §7); it never re-implements authentication,
  credentials, or session logic. Conversely, Module 1's own Access Gate reads this module's
  operational-eligibility status (via the Eligibility Query Interface, §3) to evaluate
  `BR-AUTH-04`/`BR-AUTH-07` when a Hotel account attempts an operational feature. **Resolved
  2026-08-10:** Module 1's Technical Design §6.2 sequence diagram, §2.4, §3.2, §4, §5.1, and
  §13.1 previously showed this read directed at Administration & Platform Management
  (Module 13); all have been corrected to target Hotel Management (Module 3), matching this
  Business Specification's boundary (§18 Item 1).
- **Hall Management (Module 4, `Not Started`)** — queries this module's Eligibility Query
  Interface to determine whether a Hotel's Halls may be listed/visible (`BR-HOTEL-04`,
  `BR-HOTEL-05`). This module never reaches into Hall Management's data, and never defines
  hall visibility mechanics itself (Business Specification §3).
- **Administration & Platform Management (Module 13, `Not Started`)** — consumes this
  module's Application/Lifecycle write interface (§7, §8, §9) for its review, approval,
  rejection, suspension, and deactivation workflow, and its read/query interface
  (`GET /hotels`, §11) to populate its Hotel approval queue. This module never implements a
  review UI or duplicates Module 13's authorization logic.
- **Audit** — cross-cutting, same gap Module 1's Technical Design already flags (§18 Item 4):
  no approved module owns the Audit Record entity. This module produces Audit Records for
  security-significant, state-changing actions (§13) without claiming ownership, consistent
  with Module 1's own precedent.
- **Notification** — the Business Specification does not require notifying a Hotel Manager of
  a decision or state change; no such requirement is invented here. A future integration with
  Notification Management (Module 10) is plausible but not designed, since nothing approved
  currently requires it.

---

## 11. API Design

Every endpoint follows `api-standards.md` in full: `/api/v1/...` versioning (§3), the
success/error envelopes (§7–§8), the status codes in §9, and `naming-conventions.md` §9's
field casing (`/api/v1/hotels`, per `naming-conventions.md` §4/§9). Endpoints are conceptual;
exact request/response field lists are an Implementation Planning concern once Pending
Business Decisions #5 and #7 resolve.

**Note:** the Platform-Administrator-facing approve/reject/suspend/deactivate REST endpoints
are Administration & Platform Management's own API surface (Module 13, not yet designed,
`BR-HOTEL-14`). This module exposes only the internal service interface those endpoints
would call (§7) — no `POST /hotels/:id/approve`-style endpoint is designed here, since that
action does not belong to this module's own API surface.

#### `POST /api/v1/hotels`
- **Purpose** — register a new Hotel — `HM1`.
- **Actor** — Hotel Manager.
- **Authentication** — Required (Module 1 access token).
- **Authorization** — Any authenticated Hotel Manager identity may register a Hotel (no
  additional role check beyond authentication).
- **Request concept** — initial profile fields (shape TBD, §18 Item 7).
- **Response concept** — `201 Created`; the created Hotel's identifier and status
  (`REGISTERED`).
- **Validation** — `400` for malformed request shape.
- **State transition** — `— → REGISTERED` (§6).

#### `GET /api/v1/hotels/:id`
- **Purpose** — retrieve a Hotel's own profile and current status — supports `HM2`–`HM15`.
- **Actor** — Hotel Manager (own Hotel only) or Platform Administrator.
- **Authentication** — Required.
- **Authorization** — Hotel Manager restricted to their own Hotel (`api-standards.md` §13);
  cross-tenant access returns `404`, not `403` (tenant-isolation rule).
- **Response concept** — Hotel profile fields, current status, and (if open) the pending
  Application or Critical Information Change Request summary.
- **Validation** — `404` if not found or not owned by the caller.

#### `PATCH /api/v1/hotels/:id`
- **Purpose** — update Hotel profile fields — `HM2`, `HM12`, `HM13`.
- **Actor** — Hotel Manager (own Hotel only).
- **Authentication** — Required.
- **Authorization** — Own-Hotel only (`404` cross-tenant, as above).
- **Request concept** — one or more profile fields to change.
- **Response concept** — `200 OK`; indicates whether each change applied immediately
  (ordinary, `BR-HOTEL-11`) or is now pending Platform Administrator review (critical,
  `BR-HOTEL-12`).
- **Validation** — `400` for malformed fields; `422` if the Hotel's current status does not
  permit profile changes (e.g. `RESTRICTED_UNDER_REVIEW` — exact rule pending §18 Item 4).
- **State transition** — none for ordinary changes; creates a Critical Information Change
  Request for critical changes (§8), independent of Hotel status (§6).

#### `POST /api/v1/hotels/:id/applications`
- **Purpose** — submit an application for review (`HM3`), or resubmit after editing a
  rejected application (`HM7`–`HM8`) — modeled as a non-idempotent sub-resource action, per
  `api-standards.md` §5's pattern (`POST /bookings/:id/cancellations` is the precedent
  example).
- **Actor** — Hotel Manager (own Hotel only).
- **Authentication** — Required.
- **Authorization** — Own-Hotel only.
- **Response concept** — `201 Created`; the new Hotel Application record and updated Hotel
  status (`UNDER_REVIEW`).
- **Validation** — `422` if the Hotel's profile is not complete (`BR-HOTEL-02`,
  `BR-HOTEL-03`), or an open Application already exists (`409 Conflict`).
- **State transition** — `PROFILE_COMPLETE → UNDER_REVIEW` or `REJECTED → UNDER_REVIEW`.

#### `POST /api/v1/hotels/:id/applications/:applicationId/withdrawal`
- **Purpose** — withdraw a pending application — `HM9`, `BR-HOTEL-08`.
- **Actor** — Hotel Manager (own Hotel only).
- **Authentication** — Required.
- **Authorization** — Own-Hotel only.
- **Response concept** — `200 OK`; Application marked withdrawn, updated Hotel status
  (`WITHDRAWN`).
- **Validation** — `409` if the Application is no longer open (already decided).
- **State transition** — `UNDER_REVIEW → WITHDRAWN`.

#### `GET /api/v1/hotels`
- **Purpose** — list Hotels, filterable by status — the query interface Module 13's Hotel
  approval queue (`system-architecture-overview.md` §4) reads from to discover Applications
  awaiting review. **Added during technical review** — the original draft specified the
  write-side interfaces Module 13 calls (§7) but omitted the corresponding read-side query
  interface, without which the approval-queue feature has no way to discover pending work.
- **Actor** — Platform Administrator only.
- **Authentication** — Required.
- **Authorization** — Platform Administrator role only — a Hotel Manager may not list Hotels
  other than their own (already served by `GET /hotels/:id`).
- **Request concept** — `?status=UNDER_REVIEW` (or any other status value, §6) as a query
  filter, per `api-standards.md` §11; paginated per `api-standards.md` §10 (offset
  pagination — a bounded, page-numbered administrative list view).
- **Response concept** — `200 OK`; a page of Hotel summaries matching the filter.
- **Validation** — `400` for an unrecognized `status` filter value.

---

## 12. Security Design

- **Authentication dependency on Module 1** — this module never issues, validates, or stores
  any token or credential; every request passes through Module 1's Access Gate first
  (`architecture-principles.md` §7). No duplication of Module 1's implementation.
- **Authorization** — Hotel Manager actions are scoped to their own Hotel only, enforced as
  part of authorization per `api-standards.md` §13 (cross-tenant access returns `404`, never
  `403`, so tenant existence is never leaked). Platform-Administrator-only actions
  (approve/reject/suspend/deactivate/critical-change review, `BR-HOTEL-09`, `BR-HOTEL-14`)
  are authorized by Module 13's own layer before it calls into this module (§7) — this module
  does not re-implement that role check.
- **Hotel data protection** — profile data classified per `data-architecture.md` §13 (§5);
  no Restricted-classification data is expected in this module's scope.
- **Administrative actions** — every Platform-Administrator-triggered transition (§6) is
  attributable to a specific administrator identity via the audit trail (§13).
- **Sensitive profile information** — until Pending Business Decision #7 resolves the actual
  profile content, no assumption is made about whether any field requires stricter-than-
  Internal classification; this is revisited once that decision resolves.
- **Auditability** — every state-changing action is logged (§13), per `api-standards.md` §19.
- **State-transition protection** — only the Lifecycle Component (§3) may mutate Hotel status;
  no other component, including the Profile and Application Components, writes it directly.

**`security-architecture.md` and `security-coding-standards.md` are both currently `Not
Started`** (§18 Item 2) — this section is grounded instead in `architecture-principles.md`
§6–§7, `api-standards.md` §12–§13/§19, and `database-standards.md` §16, the same gap Module
1's Technical Design already flags and works around.

---

## 13. Audit & Traceability

Hotel actions requiring an Audit Record, each derived directly from an approved rule —
nothing invented beyond the Business Specification's own scope:

| Action | Rule / Journey |
|---|---|
| Hotel registered | `HM1` |
| Profile completed | `HM2`, `BR-HOTEL-02` |
| Application submitted | `HM3`, `BR-HOTEL-03` |
| Application edited after rejection | `HM7`, `BR-HOTEL-06` |
| Application resubmitted | `HM8`, `BR-HOTEL-07` |
| Application withdrawn | `HM9`, `BR-HOTEL-08` |
| Application approved (Platform Administrator) | `HM5`, `BDR-003` |
| Application rejected (Platform Administrator) | `HM6`, `BDR-003` |
| Hotel suspended (Platform Administrator) | `HM11`, `BR-HOTEL-09` |
| Hotel deactivated (Platform Administrator) | `BR-HOTEL-09` |
| Hotel restricted (invalid required information) | `HM14`, `BR-HOTEL-10` |
| Restriction resolved | `BR-HOTEL-10` (resolution process itself pending, §18 Item 4) |
| Ordinary profile change applied | `HM13`, `BR-HOTEL-11` |
| Critical profile change submitted | `HM12`, `BR-HOTEL-12` |
| Critical profile change approved/rejected (Platform Administrator) | `BR-HOTEL-12` |

Each record captures actor, action, timestamp, and the affected Hotel — the same shape
Module 1 already uses for its own Audit Records, subject to the same unresolved ownership
gap (§18 Item 4, inherited from Module 1's Technical Design §17 Item 4).

---

## 14. Sequence Diagrams

Only flows supported by approved business rules.

### 14.1 Hotel Registration / Onboarding (`HM1`–`HM3`)

```mermaid
sequenceDiagram
    participant Client as Hotel Manager (Module 1-authenticated)
    participant HC as Hotel Component
    participant PC as Profile Component
    participant AppC as Application Component
    participant LC as Lifecycle Component

    Client->>HC: POST /hotels — register Hotel (HM1)
    HC->>LC: Create Hotel (status REGISTERED)
    LC-->>HC: Created
    HC-->>Client: 201 — Hotel created

    Client->>PC: PATCH /hotels/:id — supply profile fields (HM2)
    PC->>LC: Request REGISTERED to PROFILE_COMPLETE
    LC-->>PC: Transition applied
    PC-->>Client: 200 — profile complete

    Client->>AppC: POST /hotels/:id/applications (HM3)
    AppC->>LC: Request PROFILE_COMPLETE to UNDER_REVIEW
    LC-->>AppC: Transition applied
    AppC-->>Client: 201 — application submitted
```

### 14.2 Administrator Approval (`HM5`)

```mermaid
sequenceDiagram
    participant Admin as Administration & Platform Management (Module 13)
    participant AppC as Application Component
    participant LC as Lifecycle Component

    Admin->>Admin: Authorize caller as Platform Administrator
    Admin->>AppC: Record approval decision (BDR-003)
    AppC->>LC: Request UNDER_REVIEW to APPROVED_ACTIVE
    LC-->>AppC: Transition applied
    AppC-->>Admin: Recorded
```

### 14.3 Administrator Rejection (`HM6`)

```mermaid
sequenceDiagram
    participant Admin as Administration & Platform Management (Module 13)
    participant AppC as Application Component
    participant LC as Lifecycle Component

    Admin->>Admin: Authorize caller as Platform Administrator
    Admin->>AppC: Record rejection decision (BDR-003)
    AppC->>LC: Request UNDER_REVIEW to REJECTED
    LC-->>AppC: Transition applied
    AppC-->>Admin: Recorded
```

### 14.4 Rejected Hotel Resubmission (`HM7`–`HM8`)

```mermaid
sequenceDiagram
    participant Client as Hotel Manager
    participant PC as Profile Component
    participant AppC as Application Component
    participant LC as Lifecycle Component

    Client->>PC: PATCH /hotels/:id — edit application (HM7, BR-HOTEL-06)
    PC-->>Client: 200 — draft updated (Hotel remains REJECTED)

    Client->>AppC: POST /hotels/:id/applications — resubmit (HM8, BR-HOTEL-07)
    AppC->>AppC: Create new Hotel Application record (§4)
    AppC->>LC: Request REJECTED to UNDER_REVIEW
    LC-->>AppC: Transition applied
    AppC-->>Client: 201 — resubmitted, under review again
```

### 14.5 Pending Application Withdrawal (`HM9`)

```mermaid
sequenceDiagram
    participant Client as Hotel Manager
    participant AppC as Application Component
    participant LC as Lifecycle Component

    Client->>AppC: POST /hotels/:id/applications/:applicationId/withdrawal (BR-HOTEL-08)
    AppC->>AppC: Mark Application withdrawn
    AppC->>LC: Request UNDER_REVIEW to WITHDRAWN
    LC-->>AppC: Transition applied
    AppC-->>Client: 200 — withdrawn
```

### 14.6 Approved Hotel Suspension (`HM11`)

```mermaid
sequenceDiagram
    participant Admin as Administration & Platform Management (Module 13)
    participant SR as Suspension / Restriction Component
    participant LC as Lifecycle Component

    Admin->>Admin: Authorize caller as Platform Administrator (BR-HOTEL-09)
    Admin->>SR: Record suspension decision
    SR->>LC: Request APPROVED_ACTIVE to SUSPENDED
    LC-->>SR: Transition applied
    SR-->>Admin: Recorded
```

### 14.7 Critical Profile Change / Review (`HM12`)

```mermaid
sequenceDiagram
    participant Client as Hotel Manager
    participant PC as Profile Component
    participant Admin as Administration & Platform Management (Module 13)

    Client->>PC: PATCH /hotels/:id — critical field change (HM12, BR-HOTEL-12)
    PC->>PC: Classify change as critical (ruleset TBD, §18 Item 5)
    PC->>PC: Create Critical Information Change Request (pending)
    PC-->>Client: 200 — pending Platform Administrator review

    Admin->>Admin: Authorize caller as Platform Administrator
    Admin->>PC: Record review decision
    alt Approved
        PC->>PC: Apply change to Hotel profile
    else Rejected
        PC->>PC: Discard proposed change
    end
    PC-->>Admin: Recorded
```

---

## 15. Data / State Diagrams

### 15.1 Hotel Lifecycle

See §6.1 (`stateDiagram-v2`) — the authoritative Hotel status model.

### 15.2 Hotel Application Lifecycle

```mermaid
stateDiagram-v2
    [*] --> OPEN: Submitted (HM3) or Resubmitted (HM8)
    OPEN --> APPROVED: Platform Administrator approves (HM5)
    OPEN --> REJECTED: Platform Administrator rejects (HM6)
    OPEN --> WITHDRAWN: Hotel Manager withdraws (HM9)
    APPROVED --> [*]
    REJECTED --> [*]
    WITHDRAWN --> [*]
```

Each Hotel Application record is immutable once it leaves `OPEN` (§4) — history is
preserved by creating a new record on resubmission, never by reopening a decided one.

### 15.3 Critical Information Change Request Lifecycle

```mermaid
stateDiagram-v2
    [*] --> PENDING: Critical change submitted (HM12, BR-HOTEL-12)
    PENDING --> APPLIED: Platform Administrator approves
    PENDING --> REJECTED: Platform Administrator rejects
    APPLIED --> [*]
    REJECTED --> [*]
```

Independent of Hotel status throughout (§6) — the deliberate design response to Pending
Business Decision #6.

---

## 16. Error & Failure Handling

All categories use `api-standards.md` §8's error envelope and §9's status codes — no new
status code is introduced.

| Category | Status Code | Handling |
|---|---|---|
| Invalid state transition (e.g. submitting while already `UNDER_REVIEW`) | `409 Conflict` | Rejected before any Lifecycle Component transition is attempted (§6). |
| Unauthorized administrative operation (non-Platform-Administrator attempts approve/reject/suspend) | `403 Forbidden` | Refused by Module 13's own authorization layer before this module's interface is ever called (§7, §12). |
| Invalid Hotel data (malformed request) | `400 Bad Request` | Request-shape validation, before business logic runs (`api-standards.md` §14). |
| Invalid Hotel data (business rule, e.g. incomplete profile) | `422 Unprocessable Entity` | Well-formed request, business rule not satisfied (`BR-HOTEL-02`, `BR-HOTEL-03`). |
| Application submission failure (profile incomplete) | `422 Unprocessable Entity` | Same as above. |
| Review conflict (e.g. Module 13 attempts to decide an already-withdrawn Application) | `409 Conflict` | The Application is no longer `OPEN` (§15.2). |
| Suspended/restricted Hotel attempting an operational action | `422 Unprocessable Entity` | A well-formed, authenticated, authorized request that fails because the Hotel's current status does not permit the action — a business-rule failure, not an authentication (`401`) or authorization (`403`) failure. |
| Cross-tenant access attempt | `404 Not Found` | Never `403` — consistent with `api-standards.md` §9's tenant-isolation rule. |

---

## 17. Dependencies

- **Internal** — Authentication & Account Management (Module 1, satisfied); Hall Management
  (Module 4, `Not Started` — not a blocking dependency for this module's own architecture,
  since Hall Management is the *consumer* of this module's Eligibility Query Interface, not
  the reverse); Administration & Platform Management (Module 13, `Not Started` — same
  relationship, this module is the interface provider).
- **External services** — none required by this module's approved scope. A future document-
  or photo-upload requirement (if Pending Business Decision #7 resolves to include one) would
  introduce a dependency on the Cloudinary storage abstraction (`architecture-principles.md`
  §10, `technology-stack.md`) — not assumed here.
- **Infrastructure** — PostgreSQL + Prisma, Express (shared, no module-specific addition).
- **Pending BDR dependencies** — see §18 for the full classification of whether each of the
  seven Pending Business Decisions blocks architecture, blocks only specific future
  Development-phase work, or blocks neither.

---

## 18. Technical Risks & Assumptions

Per this project's own rule that a Technical Design must never silently encode an unrecorded
answer (`business-decision-register.md` §1) and must never bypass an architectural principle
rather than flag it (`architecture-principles.md` §14), the following were identified while
authoring this document.

1. **Architecture conflict — Hotel approval status ownership. RESOLVED 2026-08-10.**
   `data-architecture.md` §9 ("Administration Domain owns... Hotel approval status") and
   Module 1's `Approved` Technical Design (§2.4, §3.2, §4, §5.1, §6.2, §13.1) previously
   attributed ownership of Hotel approval status to Module 13, conflicting with the
   `Approved` Hotel Management Business Specification §3, which makes Hotel Management "the
   upstream source of truth for the Hotel-entity decisions (approval, rejection, suspension,
   restriction)," with Module 13 owning only the review interface/workflow. **Resolution:**
   Ahmed confirmed the Business Specification's boundary as authoritative. `data-architecture.md`
   §9 was corrected (v1.1) to attribute Hotel approval status to the Hotel Domain, narrowing
   the Administration Domain to cross-tenant administrative data only. Module 1's Technical
   Design was corrected (v1.8) at every reference — the component diagram (§4), Dependencies
   (§2.4), Does Not Own (§3.2), Data Design relationships (§5.1), the §6.2 sequence diagram,
   and the §13.1 state-diagram note — to read Hotel approval status from Hotel Management
   (Module 3) rather than Module 13. No business decision changed; `BDR-003` never assigned
   data ownership, so this was an architecture-layer correction, not a reopened decision. The
   service-interface reconciliation pattern this document proposed in §7 (Hotel Management
   owns and persists the data; Module 13 owns the review action and calls in through a
   defined interface) is now the agreed architecture.
2. **`security-architecture.md` and `security-coding-standards.md` are both `Not Started`.**
   The same gap Module 1's Technical Design already flags (its own §17 Item 1) — inherited
   here, not newly introduced. §12 is grounded in everything already `Approved` that touches
   security.
3. **`domain-model-and-bounded-contexts.md` does not exist.** Referenced as "once authored" by
   both `data-architecture.md` and `system-architecture-overview.md`. This document's §4 and
   §5 are grounded directly in `data-architecture.md` §3–§5 instead. Not a blocker; recommend
   reconciling once that document exists (same recommendation Module 1's Technical Design
   already makes).
4. **Audit Record has no assigned owning domain** — the same gap Module 1's Technical Design
   flags in its own §17 Item 4. This module participates in audit logging (§13) without
   claiming ownership, for the same reason.
5. **A secondary, smaller Data Architecture staleness:** `data-architecture.md` §9 attributes
   "Hall inventory data" to the "Hotel Domain," but the approved module list
   (`system-architecture-overview.md` §6, `folder-structure.md` §4) treats Hall Management as
   its own separate module — consistent with this Business Specification's own boundary (§3,
   Hall Management is a separate feature). Worth Ahmed's attention alongside Item 1's
   correction, same document.

**Pending Business Decisions — classified against this document's architecture:**

| # | Pending Decision | Blocks this Technical Design's architecture? | Blocks specific future work? |
|---|---|---|---|
| 1 | Rejection/Resubmission Cycle Limit | No — unlimited cycles supported by default via historical Application records (§4); a future cap is an additive validation rule. | No |
| 2 | Post-Withdrawal Reapplication | No — `WITHDRAWN`'s outgoing transition is simply absent (§6); adding one later is additive. | No |
| 3 | Suspension vs. Deactivation Distinction | No — both modeled as sibling status values with identical current effect (§9); differentiating them later is additive. | No |
| 4 | Restriction Scope & Applicable Business Process | No, for the status value and transition itself (§6). | **Yes** — the detection mechanism and resolution process for `RESTRICTED_UNDER_REVIEW` cannot be implemented until this resolves; flag before scheduling that Development-phase work. |
| 5 | Ordinary vs. Critical Field Classification | No — the routing *mechanism* is fully specified (§8) as an injectable ruleset. | **Yes** — the Profile Component cannot be fully implemented/tested without the actual field list; flag before scheduling that work. |
| 6 | Hotel Operational Status During Critical-Change Review | No — deliberately parameterized; Hotel status is unaffected by design (§6, §15.3). | No, until the eligibility business rule itself needs the answer. |
| 7 | Required Business-Profile Content | No, for this document's architecture (profile is an unspecified attribute set on Hotel, §4). | **Yes** — the Hotel entity's actual schema/migration cannot be finalized without this; flag before scheduling that Development-phase work. |

**Conclusion:** none of the seven Pending Business Decisions block this Technical Design
itself — the architecture is deliberately parameterized to accommodate any resolution, the
same technique Module 1's Technical Design uses. Three (#4, #5, #7) block specific future
Development-phase tasks and should be resolved before those particular tasks are scheduled,
not before this document proceeds. Item 1 (the ownership conflict) was the one genuine
architecture-level risk requiring resolution above the level of a single Pending Business
Decision — **resolved 2026-08-10** (see above); no remaining blocker at the architecture
level.

---

## 19. Traceability Matrix

| Business Rule / Journey | Technical Component / Design Element | API / Flow / Data Element |
|---|---|---|
| `BR-HOTEL-01` (account precondition) | §2.3 (Dependencies), §10 | — (boundary statement, no dedicated flow) |
| `BR-HOTEL-02` (profile completion) | Profile Component (§3), Hotel entity (§4) | `PATCH /hotels/:id` (§11), §14.1 |
| `BR-HOTEL-03` (submission precondition) | Application Component (§3) | `POST /hotels/:id/applications` (§11), §14.1 |
| `BR-HOTEL-04` (halls hidden pre-approval) | Eligibility Query Interface (§3) | §10 (Module 4 interaction) |
| `BR-HOTEL-05` (operational eligibility) | Lifecycle Component (§3), §6 | Hotel status `APPROVED_ACTIVE` |
| `BR-HOTEL-06` (edit after rejection) | Profile Component (§3) | §14.4 |
| `BR-HOTEL-07` (resubmission) | Application Component (§3) | `POST /hotels/:id/applications` (§11), §14.4 |
| `BR-HOTEL-08` (withdrawal) | Application Component (§3) | `POST .../withdrawal` (§11), §14.5 |
| `BR-HOTEL-09` (suspension authority) | Suspension / Restriction Component (§3) | §14.6 |
| `BR-HOTEL-10` (restriction) | Suspension / Restriction Component (§3), §6 | Hotel status `RESTRICTED_UNDER_REVIEW` |
| `BR-HOTEL-11` (ordinary changes) | Profile Component (§3) | `PATCH /hotels/:id` (§11) |
| `BR-HOTEL-12` (critical changes) | Profile Component (§3), Critical Information Change Request (§4) | §14.7, §15.3 |
| `BR-HOTEL-13` (single location) | §4 (no Branch entity, `BDR-008`) | — |
| `BR-HOTEL-14` (Module 13 interface boundary) | §7, §10, §12 | Service-interface pattern (§7), `GET /hotels` query interface (§11) |
| `HM1`–`HM15` | §14 (Sequence Diagrams) | Each journey maps to a named sequence diagram or transition table row (§6.2) |
| Pending Business Decisions #1–#7 | §18 | Classified individually, none invented |
| `BDR-001`, `BDR-003`, `BDR-008` | §1, §6, §4.1 | Foundational architecture grounding |
| `BDR-010`–`BDR-014` | §6, §7, §8, §9 | Direct realization of each decision |

Every row traces to an approved source; no technical element in this document lacks one.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.3 | 2026-08-10 | Ahmed | Status changed `Draft` → `Approved`. Ahmed directed and personally reviewed the reconciliation of Major Finding #1 in the preceding session turns (proposal reviewed and confirmed "it's right" before any edit was made); no separate Mohamed/Abukar review round occurred for this Technical Design specifically, unlike the Business Specification's review gate. Recorded transparently as a deviation from that pattern. This document is now the authoritative technical source of truth for Hotel Management — Implementation Planning may begin. |
| 1.2 | 2026-08-10 | Ahmed | Major Finding #1 (Hotel approval status ownership conflict) resolved — `data-architecture.md` §9 and Module 1's Technical Design corrected to attribute Hotel approval status to Hotel Management, matching this document's own boundary. §2.4, §7, §10, §18 Item 1, and §18's Pending-Decision conclusion updated from "flagged/proposed" to "resolved." No content of this document's own architecture changed — only its description of the (now-corrected) surrounding documents. |
| 1.1 | 2026-08-10 | Ahmed | Technical review performed (findings below). Two corrections applied: (1) §11 — added the missing `GET /hotels` query interface, without which Module 13's Hotel approval queue had no way to discover pending Applications; (2) §6 — reactivation from `SUSPENDED`/`DEACTIVATED` explicitly flagged as an undefined open question, for symmetry with how `WITHDRAWN` and `RESTRICTED_UNDER_REVIEW` were already handled. Remaining findings (the §18 Item 1 ownership conflict, and several Suggestion-level items) reported, not altered — see review record. Still `Draft`, pending Mohamed/Abukar's actual sign-off. |
| 1.0 | 2026-08-09 | Ahmed | Initial draft Technical Design for Hotel Management, authored against the `Approved` Business Specification (v1.1). Identified one genuine architecture-level conflict (Hotel approval status ownership, §18 Item 1) between `data-architecture.md` §9, Module 1's `Approved` Technical Design, and this module's `Approved` Business Specification — not resolved here, flagged for architecture-governance correction. Not yet reviewed — see status. |
