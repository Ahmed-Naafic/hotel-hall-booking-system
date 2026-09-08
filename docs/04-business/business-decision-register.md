---
title: "Business Decision Register"
document_type: Business / Governance
status: Approved
version: 2.9
owner: Ahmed (Product Governance Architect)
last_updated: 2026-09-08
---

# Business Decision Register
## Hotel Hall Booking Management System

This document is the authoritative register of every significant business decision made
during this project. It exists so business decisions are **centralized, traceable,
versioned, reviewable, and referenced by other documents** — not scattered across whichever
Business Specification happened to be written when the question came up.

**This register does not replace the Business Model or Business Specifications.** Instead,
those documents reference the approved decisions recorded here.

**Whenever the team approves a business decision, it is recorded here before any dependent
documentation is updated.** A Business Specification or Technical Design that reflects a
business decision not recorded here has skipped a step.

---

## 1. Purpose

Business decisions — what kind of platform this is, how it makes money, what policies apply
to Customers and Hotels — are often made before, or independently of, any single module's
Business Specification. Without a dedicated record, the reasoning behind them exists only in
conversation, or gets silently absorbed into whichever document happened to need it first,
with no trace for the next module that needs the same answer.

**How this register relates to other documents:**

- **Business Model.** This project does not currently maintain a separate "Business Model"
  document — the commercial rationale (vision, mission, business problem, objectives) lives
  in `docs/Project-Overview.md` §3–§6. This register does not replace that content; it
  records the discrete decisions that operationalize it (e.g., §3 states the Platform
  connects Customers and Hotels — BDR-001 below is where the specific commercial shape of
  that relationship was decided).
- **Business Specifications.** A Business Specification describes what a module does. Where
  that description depends on a decision that spans modules, or predates the module's own
  Business Specification, the specification references the relevant BDR ID rather than
  re-deriving or re-stating the reasoning.
- **Technical Design.** A Technical Design must never silently encode an unrecorded business
  answer. If a technical question turns out to require a business decision, that decision is
  proposed and approved here first — per `Decision-Making-Principles.md` §5 (Documentation
  before Implementation).
- **Architecture Decision Records (ADRs).** **ADRs record architectural decisions. This
  register records business decisions.** The two are not interchangeable, and a single
  real-world question can require both — e.g., BDR-006 (Booking Policy) may, separately,
  require an ADR if it turns out to demand a specific architectural approach to support.
  Neither document substitutes for the other.

---

## 2. Decision Lifecycle

```
Proposed
    ↓
Under Discussion
    ↓
Approved
    ↓
Implemented
    ↓
Superseded (if replaced)
    ↓
Archived
```

- **Proposed** — a business decision has been identified as needed and drafted, but not yet
  discussed or agreed. Anyone on the team may propose one; only Ahmed can move it forward
  (`Decision-Making-Principles.md` §4).
- **Under Discussion** — options and trade-offs are actively being evaluated (the Analysis /
  Options / Trade-offs steps of `Decision-Making-Principles.md` §5).
- **Approved** — Ahmed has made the decision. It is now binding, and dependent documents may
  rely on it.
- **Implemented** — the decision is reflected in the relevant Business Specification(s)
  and/or Technical Design(s); the record and reality now match. Distinct from a whole
  Feature reaching `Feature Accepted` — a decision can be Implemented well before every
  module it touches is fully built.
- **Superseded** — a later decision (a new BDR entry) has replaced this one. The old entry
  is never edited to reflect the new choice — a new BDR ID is created, and this entry's
  status changes to `Superseded` with a pointer to the new ID.
- **Archived** — the decision is no longer relevant to the current system (e.g. the scope it
  concerned was removed) and is kept only for historical record.

---

## 3. Decision Record Format

Every decision recorded in §5 uses this template:

| Field | Meaning |
|---|---|
| **Business Decision ID** | `BDR-001`, `BDR-002`, ... — sequential, never reused, even for a `Superseded` or `Archived` entry |
| **Title** | Short, specific name |
| **Category** | One of §4 |
| **Status** | One of §2 |
| **Decision Owner** | Always Ahmed once `Approved` (`Decision-Making-Principles.md` §4); may differ from who first proposed it |
| **Decision Date** | The date it reached `Approved`; blank while `Proposed` or `Under Discussion` |
| **Business Problem** | What need or open question prompted this decision |
| **Options Considered** | At least the status quo plus one genuine alternative (`Decision-Making-Principles.md` §5) |
| **Selected Decision** | The actual choice made |
| **Business Rationale** | Why — evaluated against `Decision-Making-Principles.md` §6, Business Value chief among them |
| **Impacted Documents** | Business Specifications / Technical Designs / other documents that depend on this decision |
| **Impacted Modules** | Which module(s) this decision affects |
| **Risks** | What could go wrong, or what this decision constrains later |
| **Future Review Required** | Yes / No — whether this decision should be proactively revisited per `Decision-Making-Principles.md` §11 |
| **Notes** | Anything else, including supersession pointers |

---

## 4. Decision Categories

- **Business Model** — decisions about the fundamental shape of the business itself (what
  kind of platform this is, who it serves, at what level of involvement).
- **Revenue Model** — how the Platform makes money.
- **Platform Policies** — platform-wide rules that apply across all Hotels.
- **Customer Policies** — rules governing Customer eligibility, accounts, or behavior.
- **Hotel Policies** — rules governing what a Hotel or Hotel Manager may or must do on the
  Platform.
- **Payment Policies** — policy-level decisions about how payment, deposits, and refunds are
  handled (not the technical implementation — that's a Technical Design concern).
- **Booking Policies** — policy-level decisions about holds, cancellation windows, and
  no-show handling.
- **Review Policies** — rules about how Reviews & Ratings work (who can review, moderation).
- **Pricing Policies** — how Hotels/Halls are permitted to price, discount, or promote.
- **Operational Policies** — day-to-day operational rules not covered above.

---

## 5. Register

| ID | Title | Category | Status | Owner | Date | Impacted Modules |
|---|---|---|---|---|---|---|
| BDR-001 | Platform Type | Business Model | Approved | Ahmed | 2026-08-02 | All modules |
| BDR-002 | Revenue Model | Revenue Model | Approved | Ahmed | 2026-08-02 | Payment Management, Administration & Platform Management, Hotel Management |
| BDR-003 | Hotel Approval Process | Platform Policies | Approved | Ahmed | 2026-08-02 | Hotel Management, Administration & Platform Management, Authentication & Account Management |
| BDR-004 | Payment Flow | Payment Policies | Approved | Ahmed | 2026-08-02 | Payment Management, Booking Management |
| BDR-005 | Customer Eligibility | Customer Policies | Approved | Ahmed | 2026-08-02 | Customer Management, Authentication & Account Management |
| BDR-006 | Booking Policy | Booking Policies | Approved | Ahmed | 2026-08-02 | Booking Management, Calendar & Scheduling Management |
| BDR-007 | Platform Administration Web Interface | Business Model | Approved | Ahmed | 2026-08-02 | Administration & Platform Management |
| BDR-008 | Multi-Branch Hotels | Business Model | Approved | Ahmed | 2026-08-02 | Hotel Management, Hall Management |
| BDR-009 | Customer Registration Timing | Customer Policies | Approved | Ahmed | 2026-08-03 | Authentication & Account Management, Customer Management, Hall Management, Booking Management |
| BDR-010 | Rejected Hotel Application Handling | Hotel Policies | Approved | Ahmed | 2026-08-09 | Hotel Management, Administration & Platform Management |
| BDR-011 | Pending Hotel Application Withdrawal | Hotel Policies | Approved | Ahmed | 2026-08-09 | Hotel Management |
| BDR-012 | Hotel Suspension Authority | Platform Policies | Approved | Ahmed | 2026-08-09 | Hotel Management, Administration & Platform Management |
| BDR-013 | Hotel Information Validity & Restriction | Platform Policies | Approved | Ahmed | 2026-08-09 | Hotel Management, Administration & Platform Management |
| BDR-014 | Hotel Profile Change Review Policy | Platform Policies | Approved | Ahmed | 2026-08-09 | Hotel Management, Administration & Platform Management |
| BDR-015 | Required Hotel Business-Profile Content | Hotel Policies | Approved | Ahmed | 2026-08-26 | Hotel Management |
| BDR-016 | Required Hall Information | Hotel Policies | Approved | Ahmed | 2026-08-26 | Hall Management |
| BDR-017 | Hotel Geographic Location Capture | Hotel Policies | **Approved** | Ahmed | 2026-08-31 | Hotel Management |
| BDR-018 | Required Customer Full Name at Registration | Customer Policies | **Approved** | Ahmed | 2026-09-08 | Authentication & Account Management, Customer Management, Booking Management |

This table grows for the life of the project. Full records for each entry above follow in
§9. New entries follow the same pattern: a row here, plus a full record using the §3
template.

---

## 6. Decision Rules

- **Every major business decision must be recorded here** before it is reflected in any
  Business Specification or Technical Design.
- **Business documents must reference Business Decision IDs** where applicable (e.g. "per
  BDR-004") rather than restating the reasoning inline.
- **Superseded decisions remain in the register permanently** for historical traceability —
  never deleted.
- **Decisions cannot be silently changed.** Any change to an `Approved` decision creates a
  new BDR entry that supersedes the old one, per §2 — the old entry's fields are never
  edited to reflect the new answer.
- **New decisions require Ahmed's approval**, consistent with `Decision-Making-Principles.md`
  §4 (Business Decisions: Ahmed).

---

## 7. Relationship to Other Documents

- **Business Model** — currently the commercial rationale in `Project-Overview.md` §3–§6;
  this register records the decisions that operationalize it (§1).
- **Stakeholders & Personas** — decisions here must stay consistent with the users described
  in `docs/04-business/stakeholders-and-personas.md`; a decision affecting who the Platform
  serves should reference, or trigger an update to, that document.
- **Business Policies** — policy-category decisions (§4) recorded here *are* the source of
  business policy on this project; there is no separate "Business Policies" document.
  Policy lives in this register plus the Business Specifications that implement it.
- **Business Rules** — individual, module-scoped business rules are defined in each module's
  Business Specification. A rule that spans modules, or represents a foundational policy
  choice, traces back to a BDR ID here.
- **Business Workflows** — workflows described in a Business Specification must not
  contradict an `Approved` decision recorded here. If a workflow needs a business decision
  that doesn't exist yet, that decision is proposed here first.
- **Module Business Specifications** — reference the relevant BDR ID(s) directly. A Business
  Specification is not complete if it silently assumes an answer to a question this register
  should have addressed.

---

## 8. Maintenance

- Ahmed is the document owner.
- New decisions require genuine discussion (the `Under Discussion` stage, §2) before
  approval — Mohamed and Abukar may raise, question, and discuss proposed decisions, even
  though final approval authority rests with Ahmed (`Decision-Making-Principles.md` §4).
- Business changes update this register **before** dependent documents (Business
  Specifications, Technical Designs) are updated, per the ordering rule stated at the top of
  this document.
- Every update to this document is recorded in the Version History below; every individual
  decision's own history is tracked through its `Status` and `Notes` fields plus any
  `Superseded` pointer.

---

## 9. Decisions

All fourteen decisions below are **`Approved`**, per the process in
`Decision-Making-Principles.md` §5: each was analyzed, at least two genuine options were
weighed against the evaluation criteria in §6 of that document, a recommendation was drafted
by AI assistance, and the decision itself was made by Ahmed — consistent with §4 (Business
Decisions: Ahmed) and §8 (AI may recommend; AI never becomes the decision maker). BDR-010
through BDR-014 record five Hotel Management lifecycle decisions the team had already reached
consensus on; Ahmed's sign-off recorded here formalizes them into the register per §6's
ordering rule (recorded here before any dependent Business Specification).

### BDR-001 — Platform Type

| Field | Value |
|---|---|
| Category | Business Model |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | The Platform's commercial positioning needed to be pinned down beyond "commercial multi-tenant mobile platform" (`Project-Overview.md`) — specifically, whether it operates as a booking intermediary with no operational involvement in a Hotel's business, or takes a deeper, more managed role. |
| Options Considered | (1) Pure marketplace/intermediary; (2) Managed-services model with deeper platform involvement; (3) Hybrid, varying by Hotel tier. |
| Selected Decision | **Pure marketplace/intermediary.** The Platform connects Customers and Hotels and provides the tools for each to operate independently; it does not take an operational role in running any Hotel's business. |
| Business Rationale | Matches the self-service design already established (Hotel Manager app, Staff Management module) — Hotels manage themselves. Requires no platform-side operations staff or tooling, which a 3-person team cannot support. Simplest option that satisfies the business need (`Project-Constitution.md` §3, Simplicity Over Complexity). |
| Impacted Documents | `Project-Overview.md`; every future Business Specification |
| Impacted Modules | All modules |
| Risks | None identified beyond standard marketplace risk (quality control now depends on BDR-003's approval process rather than direct operational oversight). |
| Future Review Required | Yes — revisit if the Platform ever considers offering managed services as a premium tier. |
| Notes | Resolved together with BDR-008 (both concern what a "Hotel" fundamentally is on this Platform); the two decisions are consistent with each other. |

### BDR-002 — Revenue Model

| Field | Value |
|---|---|
| Category | Revenue Model |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | How the Platform generates revenue was not yet decided. |
| Options Considered | (1) Per-booking commission from Hotels; (2) Hotel subscription/listing fee; (3) Customer-side service fee; (4) A combination of the above. |
| Selected Decision | **Per-booking commission.** The Platform takes a percentage of each completed Booking's payment, settled through Payment Management. |
| Business Rationale | Scales with actual usage rather than requiring upfront commitment, lowering the barrier to onboarding early Hotels (directly supports BDR-003's approval-gated onboarding by making onboarding itself free). Fits naturally into the payment flow Payment Management already needs to build (BDR-004) — no separate billing/subscription infrastructure required. |
| Impacted Documents | Payment Management, Administration & Platform Management, Hotel Management Business Specifications |
| Impacted Modules | Payment Management, Administration & Platform Management, Hotel Management |
| Risks | Revenue is zero until Bookings occur — acceptable for MVP validation, but a future review should confirm the commission rate is commercially sustainable once real volume exists. |
| Future Review Required | Yes |
| Notes | Resolved together with BDR-004 (Payment Flow) — the commission is calculated against the Full Payment amount defined there. |

### BDR-003 — Hotel Approval Process

| Field | Value |
|---|---|
| Category | Platform Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | Whether a Hotel can self-register and list Halls immediately, or requires Platform Administrator review/approval before going live. |
| Options Considered | (1) Self-service, no approval; (2) Manual Platform Administrator approval required; (3) Automated eligibility checks with manual fallback. |
| Selected Decision | **Manual Platform Administrator approval required.** A Hotel account is created but cannot list Halls or receive Bookings until a Platform Administrator approves it. |
| Business Rationale | The Platform processes real payments (BDR-002, BDR-004) — some trust and fraud control is warranted before a Hotel can transact. Automated verification (option 3) requires infrastructure not currently justified for MVP scale. A manual gate is simple to implement (a status flag plus a review action) and can evolve to automated checks later without breaking anything. |
| Impacted Documents | Hotel Management, Administration & Platform Management Business Specifications |
| Impacted Modules | Hotel Management, Administration & Platform Management, Authentication & Account Management |
| Risks | Manual approval does not scale indefinitely — flagged for review once Hotel onboarding volume grows. |
| Future Review Required | Yes — revisit toward automated checks (option 3) once volume justifies it. |
| Notes | This is the business justification for BDR-007 (Administration Web Interface) — a Platform Administrator needs somewhere to perform this review. |

### BDR-004 — Payment Flow

| Field | Value |
|---|---|
| Category | Payment Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | When and how payment is collected relative to a Booking — whether a Deposit is required platform-wide, when it's collected, and how a Hotel's share of funds is settled. |
| Options Considered | (1) Full payment upfront at Booking; (2) Deposit at Booking with balance due before the Event; (3) Hotel-configurable policy per Hotel. |
| Selected Decision | **Deposit at Booking, balance due before the Event** — a single Platform-wide default policy (not Hotel-configurable at this stage). |
| Business Rationale | Matches standard event/hall-booking customer expectations (the Deposit concept is already defined in `Project-Glossary.md`). A single default policy avoids building a per-Hotel policy engine before there's evidence it's needed (`Project-Constitution.md` §3, Simplicity Over Complexity) — Hotel-configurable payment policy remains a plausible future enhancement, not a day-one requirement. |
| Impacted Documents | Payment Management, Booking Management Business Specifications |
| Impacted Modules | Payment Management, Booking Management |
| Risks | A single fixed policy may not fit every Hotel's real-world practice; tracked for future review rather than solved now. |
| Future Review Required | Yes — revisit toward Hotel-configurable policy (option 3) post-MVP. |
| Notes | Resolved together with BDR-002 (commission calculated on the Full Payment this flow defines) and BDR-006 (Booking Policy governs cancellation/refund interplay with this Deposit). |

### BDR-005 — Customer Eligibility

| Field | Value |
|---|---|
| Category | Customer Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | Whether any individual or organization may register as a Customer, or whether eligibility is restricted (e.g. minimum age, identity verification, business-only for certain Event Types). |
| Options Considered | (1) Open registration, no restrictions; (2) Minimum age / identity verification required; (3) Tiered eligibility by Event Type or Hall category. |
| Selected Decision | **Open registration.** Any individual or organization may register as a Customer, subject only to the standard identity/contact verification already implied by Authentication & Account Management. |
| Business Rationale | No evidence exists that age or tier-based restriction is actually needed for hall/event bookings (unlike, say, alcohol sales). Open registration is simplest to build, matches the Customer definition already in `Project-Glossary.md`, and does not block Wave 1 (`Development-Roadmap.md`) with unnecessary verification infrastructure. |
| Impacted Documents | Customer Management, Authentication & Account Management Business Specifications |
| Impacted Modules | Customer Management, Authentication & Account Management |
| Risks | None significant identified; standard account-security verification (not eligibility restriction) still applies via Authentication & Account Management. |
| Future Review Required | No, unless a specific fraud or compliance issue emerges. |
| Notes | Resolved early given Authentication & Account Management is the dependency root of the entire roadmap (Wave 1). |

### BDR-006 — Booking Policy

| Field | Value |
|---|---|
| Category | Booking Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | The rules governing how long a Hold lasts before release, cancellation windows, and No Show handling were not yet defined at a policy level. |
| Options Considered | (1) Platform-wide fixed policy for all Hotels; (2) Hotel-configurable policy within Platform-defined limits; (3) Fully Hotel-defined policy. |
| Selected Decision | **Hotel-configurable policy within Platform-defined limits.** Hotels set their own Hold duration, cancellation window, and no-show rules, each bounded by a Platform-wide minimum/maximum defined in Booking Management's Business Specification. |
| Business Rationale | Real Hotels have genuinely different operational needs (a small hall and a large ballroom don't need the same cancellation window) — a single fixed policy (option 1) would not fit real adoption. Fully Hotel-defined (option 3) risks inconsistent customer trust across the Platform. Bounded configurability is a well-understood pattern that balances both. |
| Impacted Documents | Booking Management, Calendar & Scheduling Management Business Specifications |
| Impacted Modules | Booking Management, Calendar & Scheduling Management |
| Risks | Highest-blast-radius decision in this register (`Development-Roadmap.md` §5) — the specific Platform-wide bounds (exact min/max values) still need to be set during Booking Management's Business Specification; this decision approves the *model* (configurable within limits), not the specific numbers. |
| Future Review Required | Yes — the specific bound values should be reviewed once real Hotel usage exists. |
| Notes | Interacts directly with BDR-004 (Payment Flow) on cancellation/refund handling. |

### BDR-007 — Platform Administration Web Interface

| Field | Value |
|---|---|
| Category | Business Model |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | `Project-Overview.md` §7 (Out of Scope) stated non-mobile client applications were out of scope and the Platform was mobile-application-first, "unless a future, separately approved decision brings them into scope." The approved technology stack (`docs/02-architecture/technology-stack.md`, ADR-0001) includes a React + Vite frontend alongside Flutter, implying a web-based interface was intended. This decision reconciles the stack with the stated scope. |
| Options Considered | (1) React + Vite serves a web-based Administration & Platform Management dashboard only; Customer and Hotel Manager remain mobile-only, and `Project-Overview.md` §7 is updated to reflect this one exception. (2) React + Vite is reserved for future use and is not yet part of active scope. (3) Remove React + Vite from the approved stack entirely. |
| Selected Decision | **Option 1.** React + Vite is confirmed as the Platform Administration web dashboard. Customer and Hotel Manager remain mobile-only (Flutter); this is the one explicit exception to mobile-application-first scope. |
| Business Rationale | Resolves the stack/scope contradiction directly rather than leaving it open. Also gives BDR-003's manual Hotel approval process a concrete interface to happen in — a Platform Administrator reviewing Hotel applications is a genuinely desktop-shaped task. Removing React + Vite (option 3) would have meant amending an already-approved ADR for no real gain, since the need it serves (BDR-003) is real. |
| Impacted Documents | `Project-Overview.md` §7 (Out of Scope), `docs/02-architecture/technology-stack.md`, `folder-structure.md`, ADR-0001, Administration & Platform Management Business Specification |
| Impacted Modules | Administration & Platform Management |
| Risks | None — this decision resolves a risk (the prior contradiction) rather than introducing one. |
| Future Review Required | No. |
| Notes | Directly enables BDR-003 (Hotel Approval Process). Downstream documents (`Project-Overview.md`, `technology-stack.md`, `folder-structure.md`, ADR-0001) have been updated to reflect this — see their own version histories. |

### BDR-008 — Multi-Branch Hotels

| Field | Value |
|---|---|
| Category | Business Model |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-02 |
| Business Problem | Whether a single Hotel tenant may operate multiple physical branches/locations under one account, each with its own Halls, or whether "Hotel" always means exactly one physical location. A `branches` concept was considered during folder-structure design but not included pending this decision. |
| Options Considered | (1) One Hotel = one physical location, always; a hotel chain registers multiple separate Hotel accounts. (2) One Hotel tenant may own multiple Branches, each with its own Halls, under shared administration. (3) Defer — support only option (1) initially, revisit as a scope addition later. |
| Selected Decision | **Option 1.** One Hotel account represents exactly one physical location. A hotel chain wishing to list multiple locations registers a separate Hotel account per location. |
| Business Rationale | Keeps the MVP data model simple — option 2 would add a new entity layer (Branch) throughout Hotel Management, Hall Management, `data-architecture.md`, `domain-model-and-bounded-contexts.md`, and `folder-structure.md` before Wave 1 has even started, for a need not yet evidenced by real demand. Option 1 is fully functional for chains today (multiple accounts), and does not foreclose adding true multi-branch support later (`Development-Roadmap.md` §2, Design for Extensibility) — it is a scope choice, not an architectural dead end. |
| Impacted Documents | Hotel Management, Hall Management Business Specifications; `data-architecture.md`; `domain-model-and-bounded-contexts.md`; `folder-structure.md` §4 |
| Impacted Modules | Hotel Management, Hall Management |
| Risks | If multi-branch demand emerges post-MVP, adding it later is a genuine data-model addition, not a trivial one — tracked via Future Review. |
| Future Review Required | Yes — revisit once real Hotel chain demand is evidenced. |
| Notes | Resolved consistently with BDR-001 (Platform Type) — both concern the fundamental shape of what a "Hotel" is on this Platform. `folder-structure.md` §4's `branches/` exclusion is now confirmed, not provisional. |

### BDR-009 — Customer Registration Timing

| Field | Value |
|---|---|
| Category | Customer Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-03 |
| Business Problem | BDR-005 approved open Customer registration but did not settle *when* in the Customer's journey registration is required — specifically, whether a Customer must create an account before browsing Hotels and Halls, or only once they act on a specific Hall. Needed before Authentication & Account Management's Business Specification could define its account-creation triggers. |
| Options Considered | (1) Registration required before any use of the Customer application, including browsing. (2) Deferred registration — a Customer may browse Hotels and Halls freely, and is only required to register at the point of proceeding to book a specific Hall. (3) Partial browsing (e.g. Hotel list only, no Hall detail or availability) without an account, full detail gated behind registration. |
| Selected Decision | **Option 2 — Deferred ("Hall-First") registration.** A Customer may browse Hotels and Halls, including availability and pricing, without an account. Registration is required only when the Customer proceeds to book a Hall (or otherwise acts on their own account, e.g. saving a favorite). |
| Business Rationale | Removes friction from the top of the funnel — a Customer can evaluate whether the Platform has what they need before committing to an account, which directly serves Project Objective 1 (`Project-Overview.md` §5, "search, filter, and book... without manual coordination"). Consistent with BDR-005's open-registration stance: there is no eligibility barrier to browsing, so gating it behind registration would add friction without a corresponding trust or fraud control benefit. Registration at the point of booking is still early enough to capture the identity/contact verification Authentication & Account Management requires before a Booking (a real transaction) is created. |
| Impacted Documents | Authentication & Account Management Business Specification; Customer Management Business Specification; Hall Management Business Specification (Hall browsing/search); Booking Management Business Specification (registration as a precondition of the booking flow) |
| Impacted Modules | Authentication & Account Management, Customer Management, Hall Management, Booking Management |
| Risks | None identified — browsing without an account exposes no Customer or Hotel data beyond what a public listing already implies. |
| Future Review Required | No. |
| Notes | Directly informs Authentication & Account Management's account-creation trigger (Business Specification, §5–§7). |

### BDR-010 — Rejected Hotel Application Handling

| Field | Value |
|---|---|
| Category | Hotel Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-09 |
| Business Problem | Whether a Hotel application rejected under BDR-003's Platform Administrator review is final, or whether the Hotel has a path to pursue approval after rejection. |
| Options Considered | (1) Rejection is final — a rejected applicant must start over with an entirely new application. (2) The rejected Hotel may edit its existing application to address the rejection reason and resubmit it for another Platform Administrator review. (3) Automatic resubmission without any edit, as a retry. |
| Selected Decision | **Option 2.** A rejected Hotel may edit its application and resubmit it for another Platform Administrator review. |
| Business Rationale | A rejection reason (e.g. missing or incorrect information) is often correctable — treating it as final (option 1) would permanently lose a legitimate Hotel over a fixable problem, with no offsetting trust or fraud-control benefit over option 2. Requiring resubmission to go through Platform Administrator review again (rather than option 3's unreviewed retry) preserves BDR-003's manual-control gate rather than weakening it. |
| Impacted Documents | Hotel Management, Administration & Platform Management Business Specifications |
| Impacted Modules | Hotel Management, Administration & Platform Management |
| Risks | A Hotel could cycle between rejection and resubmission indefinitely without ever meeting requirements; whether a cap or other handling applies is not decided here — left to the Hotel Management Business Specification. |
| Future Review Required | Yes — revisit if repeated-rejection cycling becomes an operational problem. |
| Notes | Extends BDR-003 (Hotel Approval Process) — a rejection is no longer necessarily final; it now has a defined recourse path. |

### BDR-011 — Pending Hotel Application Withdrawal

| Field | Value |
|---|---|
| Category | Hotel Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-09 |
| Business Problem | Whether a Hotel that has submitted an application still awaiting Platform Administrator review (BDR-003) may withdraw it before a decision is made. |
| Options Considered | (1) No withdrawal — a submitted application must be resolved (approved or rejected) by the Platform Administrator. (2) The Hotel may withdraw its own application at any time while it remains pending. |
| Selected Decision | **Option 2.** A Hotel may withdraw its application while it remains pending Platform Administrator review. |
| Business Rationale | Gives a Hotel control over an application it no longer wants reviewed (e.g. submitted in error, or the Hotel changed its mind), and avoids the Platform Administrator spending review effort on an application the applicant has already abandoned. |
| Impacted Documents | Hotel Management Business Specification |
| Impacted Modules | Hotel Management |
| Risks | None significant identified — withdrawal only affects the Hotel's own not-yet-approved application. |
| Future Review Required | No. |
| Notes | Distinct from BDR-010 — this concerns a still-pending application, not a rejected one. |

### BDR-012 — Hotel Suspension Authority

| Field | Value |
|---|---|
| Category | Platform Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-09 |
| Business Problem | Whether an already-approved, operating Hotel can subsequently be suspended or deactivated, and who holds the authority to do so. |
| Options Considered | (1) No suspension mechanism — an approved Hotel remains approved indefinitely once it passes BDR-003's approval gate. (2) An approved Hotel may be suspended or deactivated, with the Platform Administrator holding sole authority to do so. (3) Suspension authority shared between the Platform Administrator and an automated policy-violation system. |
| Selected Decision | **Option 2.** An approved Hotel may be suspended (or deactivated); the Platform Administrator is the sole authority controlling suspension and deactivation of approved Hotels. |
| Business Rationale | BDR-003's approval gate only controls onboarding — it provides no ongoing control if an approved Hotel later needs to be taken offline. Concentrating this authority in the Platform Administrator keeps it consistent with BDR-003's existing manual-control model rather than introducing a separate automated enforcement system not yet justified (option 3). |
| Impacted Documents | Hotel Management, Administration & Platform Management Business Specifications |
| Impacted Modules | Hotel Management, Administration & Platform Management |
| Risks | The specific operational distinction (if any) between "suspended" and "deactivated," and the grounds that justify each, are not settled here — left to the Hotel Management Business Specification. |
| Future Review Required | Yes — revisit if suspension volume warrants a less fully-manual process. |
| Notes | Extends BDR-003's manual-control model to an approved Hotel's ongoing lifecycle, not just onboarding. |

### BDR-013 — Hotel Information Validity & Restriction

| Field | Value |
|---|---|
| Category | Platform Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-09 |
| Business Problem | What happens if information a Hotel was required to provide (e.g. at approval) later becomes invalid or out of date. |
| Options Considered | (1) No mechanism — required information is not actively enforced after initial approval. (2) A Hotel with invalid required information is restricted and placed into review under the applicable business process. |
| Selected Decision | **Option 2.** If required Hotel information becomes invalid, the Hotel is restricted and placed into review, per the applicable business process. |
| Business Rationale | Keeps the trust and fraud control BDR-003 established at onboarding meaningful on an ongoing basis — required information that becomes invalid after approval poses the same risk BDR-003 exists to control. |
| Impacted Documents | Hotel Management, Administration & Platform Management Business Specifications |
| Impacted Modules | Hotel Management, Administration & Platform Management |
| Risks | The specific "required information" fields, what makes them "invalid," and the exact review process are not defined here — left to the Hotel Management Business Specification. |
| Future Review Required | Yes — once the specific required-information fields and review process are defined in the Hotel Management Business Specification. |
| Notes | Complements BDR-012 — restriction-and-review is a narrower, data-integrity-triggered mechanism, distinct from Platform-Administrator-initiated suspension. |

### BDR-014 — Hotel Profile Change Review Policy

| Field | Value |
|---|---|
| Category | Platform Policies |
| Status | Approved |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-09 |
| Business Problem | Whether every change a Hotel makes to its own profile after approval requires Platform Administrator re-review, or only some changes do. |
| Options Considered | (1) Every profile change requires Platform Administrator re-review before taking effect. (2) No profile change ever requires re-review once a Hotel is approved. (3) A two-tier model — ordinary changes take effect immediately; critical changes require Platform Administrator review before taking full effect. |
| Selected Decision | **Option 3.** Ordinary Hotel profile changes do not require re-review. Critical Hotel information changes require Platform Administrator review before the change becomes fully effective. |
| Business Rationale | Option 1 would bottleneck every routine edit (e.g. a description update) on Platform Administrator availability, undermining BDR-001's self-service marketplace model. Option 2 would let critical information change unchecked, undermining the trust control BDR-003 established at onboarding. The two-tier model preserves self-service for routine changes while keeping manual review in place for anything as consequential as the original approval decision. |
| Impacted Documents | Hotel Management, Administration & Platform Management Business Specifications |
| Impacted Modules | Hotel Management, Administration & Platform Management |
| Risks | Which specific fields count as "ordinary" versus "critical" is not defined here — left to the Hotel Management Business Specification. |
| Future Review Required | Yes — once the specific ordinary/critical field classification is defined in the Hotel Management Business Specification. |
| Notes | Extends BDR-003's manual-review control to post-approval profile changes, consistent with BDR-012 (suspension) and BDR-013 (restriction) doing the same for other post-approval scenarios. |

### BDR-015 — Required Hotel Business-Profile Content

| Field | Value |
|---|---|
| Category | Hotel Policies |
| Status | **Approved** — recommendation drafted by AI assistance per `Decision-Making-Principles.md` §8 (AI may recommend; AI never becomes the decision maker); reviewed and approved by Ahmed, exactly as proposed, per §4 (Business Decisions: Ahmed). |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-26 |
| Business Problem | Hotel Management Business Specification §11 Pending Business Decision #7 ("Required Business-Profile Content") has been open since that document's `Approved` v1.1: what a Hotel's profile must contain before it can reach `PROFILE_COMPLETE` (`BR-HOTEL-02`) is undefined. The current implementation (`profile.service.js#completeProfile`) only enforces "at least one field, of any shape" — no real minimum bar a Customer or Platform Administrator could rely on. This blocks building a real Hotel Profile Completion UI (Manager Mobile), which today can only offer a generic key/value editor. |
| Options Considered | (1) **Status quo** — profile content remains entirely unconstrained free-form JSON; the "at least one field" check is the only gate, no field is ever required by name. (2) **Fully fixed schema** — a rigid, closed set of profile fields (e.g. Name, Description, Location, Contact Phone, Email); no Hotel-specific custom fields permitted. (3) **Hybrid** — a small set of standard fields (some required, some optional) plus optional media (Logo, Photos) plus optional Hotel-defined custom key/value fields, with custom fields explicitly unable to substitute for a required standard field. |
| Selected Decision | **Option 3 — Hybrid.** Required standard fields: Hotel Name, Description, Location, Contact Phone. Optional standard fields: Email, Hotel Logo, Hotel Photos. Optional extensibility: Hotel Manager-defined custom key/value fields, which must never satisfy or replace a required standard field. Approved by Ahmed exactly as proposed. |
| Business Rationale | Option 1 (status quo) gives Customers and the Platform Administrator no reliable minimum to evaluate a Hotel by, undermining the trust/fraud control `BDR-003`'s approval gate exists to provide — a Hotel could reach `PROFILE_COMPLETE` with a single arbitrary field. Option 2 (fully fixed) forecloses genuine per-Hotel variation (amenities, policies, specialties) that real Hotels will want to list, and breaks from the precedent this project already set for Hall's own `profileData` (deliberately unconstrained, Hall Management Business Specification Pending Decision #2) — a Hotel is a superset of that same "we don't yet know every field a real Hotel needs" problem, at a business-critical (not merely descriptive) level. Option 3 provides the minimum bar options 1 lacks, without options 2's rigidity — the required set is small and genuinely universal to any Hotel, while custom fields absorb whatever a real Hotel needs beyond that, an approach consistent with `architecture-principles.md`'s extensibility-by-default stance. |
| Impacted Documents | Hotel Management Business Specification (§2.3, §7 `BR-HOTEL-02`, §11 — Pending Decision #7 now resolved); Hotel Management Technical Design (§4 Domain Model, §8 Profile Management, §18); Manager Mobile Hotel Profile screen (not yet built — next implementation step, tracked outside this register) |
| Impacted Modules | Hotel Management |
| Risks | (a) The required-field list is a real constraint on every already-`REGISTERED` Hotel in any environment — a migration/backfill question for Hotels registered under the old "any field" rule (none exist yet in this project's live environments beyond development/test fixtures, confirmed 2026-08-26). (b) Logo/Photos being "optional standard fields" required an approved storage mechanism before they could actually be built — this BDR did not select one itself (a storage *provider* is an architecture decision, not a business one). **Resolved 2026-08-26 via `ADR-0006`:** Supabase is now the approved Hotel media storage provider. This BDR still approves only that Logo/Photos exist as *optional* profile attributes; `ADR-0006` is the authoritative record of the provider choice. |
| Future Review Required | Yes — revisit the required-field list once real Hotel onboarding data exists, the same review posture already applied to `BDR-003`, `BDR-006`, and `BDR-012`–`014`. |
| Notes | Resolves Hotel Management Business Specification §11 Pending Decision #7, per this register's own ordering rule (§6: recorded here first, dependent documents updated next — the Business Specification and Technical Design updates follow this approval in the same change). Distinct from the separate Cloudinary-vs-Supabase architecture question raised in Risks above, which this BDR never resolved itself — that question is now resolved, but by `ADR-0006`, not by this entry. |

### BDR-016 — Required Hall Information

| Field | Value |
|---|---|
| Category | Hotel Policies |
| Status | **Approved** — Ahmed directed the field model directly (the same pattern `ADR-0006` used); the full Options/Rationale analysis is still recorded in full, per `Decision-Making-Principles.md` §4/§8. |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-26 |
| Business Problem | Hall Management Business Specification §11 Pending Business Decision #2 ("Required Hall Information") has been open since that document's `Approved` v1.1: what a Hall's profile must contain is undefined, mirroring Hotel Management's own pre-`BDR-015` gap. The current implementation (`profile.service.js#updateHallProfile`) only enforces "at least one field, of any shape" — no real minimum bar exists, and the Manager Mobile Create/Edit Hall screens can only offer a generic key/value editor. |
| Options Considered | (1) **Status quo** — `profileData` remains entirely unconstrained free-form JSON; no field is ever required by name. (2) **Fully fixed schema** — a rigid, closed set of Hall fields; no Hotel-specific custom fields permitted. (3) **Hybrid**, the same model `BDR-015` already established for Hotel — a small set of standard fields (some required, some optional), optional media, and optional Hotel Manager-defined custom fields that can never substitute for a required standard field. |
| Selected Decision | **Option 3 — Hybrid.** Required standard fields: **Hall Name, Capacity**. Optional standard fields: **Description, Location / Area**. Optional standard media: **Hall Photos**. Optional extensibility: Hotel Manager-defined custom key/value fields, which must never satisfy or replace Hall Name or Capacity. Approved by Ahmed, directed exactly as specified. |
| Business Rationale | Same reasoning `BDR-015` already established for Hotel, applied to Hall: Option 1 gives a Hotel Manager no reliable minimum to describe a bookable space by — a Hall could exist with zero identifying information. Option 2 forecloses genuine per-Hall variation Halls legitimately have (a wedding hall and a conference room don't share every attribute) and breaks the `profileData` precedent this project has now used twice. Option 3 provides the minimum bar (a Hall must at least have a name and a capacity — the two facts a Customer or Manager cannot reasonably do without) while custom fields absorb everything else, consistent with `architecture-principles.md`'s extensibility-by-default stance. Location / Area is kept as a *named standard* field (not folded into custom fields) per explicit instruction, even though optional — it is common enough across real Halls to warrant a first-class slot, the same treatment Email received for Hotel despite also being optional. |
| Impacted Documents | Hall Management Business Specification (§2.3, §7 `BR-HALL-06`/`BR-HALL-07`, §11 — Pending Decision #2 now resolved); Hall Management Technical Design (§4 Domain Model, §7, §8 Profile Management, §18); Manager Mobile Create/Edit Hall screens (implemented in the same change) |
| Impacted Modules | Hall Management |
| Risks | (a) The required-field list is a real constraint on every already-created Hall in any environment — a migration/backfill question for Halls created under the old "any field" rule (none exist yet in this project's live environments beyond development/test fixtures, confirmed 2026-08-26). (b) This BDR does **not** resolve `BR-HALL-06`'s separate, still-open question of a *definitive Amenity list* — Amenities remain expressible only through the generic custom-field mechanism until (and unless) a future decision formalizes a dedicated Amenity taxonomy (Hall Management Technical Design §9); the two are related but distinct questions, and this entry resolves only the former. (c) Hall Photos being an "optional standard field" does **not** itself approve a storage/upload mechanism — unlike Hotel (`ADR-0006`, Supabase), no architecture decision yet extends Hall Photos to a real storage provider or upload contract; that remains a separate, unresolved dependency, tracked outside this register until an ADR addresses it. This BDR approves only that Hall Photos exist as an *optional* profile attribute. (d) This BDR does not resolve Pending Decision #7 (Hall Capacity Changes — whether/how capacity may be changed *after* creation); it only establishes that a Capacity *value* is required and must be a valid positive number, the same class of request-shape validation every other field already receives, not a business-permission gate on later changes. |
| Future Review Required | Yes — revisit the required-field list once real Hall creation data exists, the same review posture `BDR-015` already applies to Hotel. |
| Notes | Resolves Hall Management Business Specification §11 Pending Decision #2, per this register's own ordering rule (§6: recorded here first, dependent documents updated next). Distinct from, and does not resolve, Pending Decisions #6 (Hall Deletion), #7 (Hall Capacity Changes), or `BR-HALL-06`'s Amenity-list question — none of those are touched by this entry. |

---

### BDR-017 — Hotel Geographic Location Capture

| Field | Value |
|---|---|
| Category | Hotel Policies |
| Status | **Approved** — approved by Ahmed on 2026-08-31. |
| Decision Owner | Ahmed |
| Decision Date | 2026-08-31 |
| Business Problem | The approved Hotel profile requires Location, but does not define how a Hotel Manager selects, stores, or corrects it. Customers need a reliable address, while geographic calculations require coordinates. |
| Options Considered | (1) Store an address only. (2) Store coordinates only. (3) Store latitude/longitude together with an editable address, captured from an OpenStreetMap map with reverse-geocoding assistance and manual fallback. |
| Selected Decision | **Option 3.** A Hotel Location consists of `latitude`, `longitude`, and `address`. Coordinates are authoritative for geographic calculations and future nearby-Hotel search; the address is customer-facing and editable by the Hotel Manager. OpenStreetMap is used for map display. Reverse-geocoding is best-effort; if it fails, captured coordinates remain valid and a manually entered address is required before saving. |
| Business Rationale | Coordinates support distance-based behavior without unreliable text matching. Separating coordinates from the editable address lets the manager correct imperfect geocoding and prevents a geocoding outage from blocking onboarding after map capture. |
| Impacted Documents | Hotel Management Business Specification; Hotel Management Technical Design; Technology Stack; Hotel Manager implementation plan; API contract documentation |
| Impacted Modules | Hotel Management; future Customer discovery/search consumers |
| Risks | Provider usage limits and attribution must remain compliant as traffic grows. `ADR-0008` resolves the initial provider, persistence, and API architecture. No nearby-Hotel search is approved by this decision. |
| Notes | Approved by Ahmed on 2026-08-31. Nearby-Hotel search remains separately scoped and is not authorized by this decision. |

### BDR-018 — Required Customer Full Name at Registration

| Field | Value |
|---|---|
| Category | Customer Policies |
| Status | **Approved** |
| Decision Owner | Ahmed |
| Decision Date | 2026-09-08 |
| Business Problem | Customer registration (BR-AUTH-02) collects only a mobile number and password. A Hotel Manager reviewing a Booking has no way to know the Customer's identity beyond an opaque account id — Customer Management Business Specification's `BDR-CUST-01` (Required Customer Profile Information) has been `Pending` since that document's `Draft` v1.0, naming "Name" only as a candidate, never approved. |
| Options Considered | (1) **Status quo** — no Customer profile field is required; a Hotel Manager sees only `customerUserId`. (2) **Full Name required at registration**, collected alongside mobile number and password, before the Customer's account is created. (3) **Full Name required, but deferred to profile completion** — collected only when the Customer later completes their profile (Customer Management Business Specification §11), not at registration itself. |
| Selected Decision | **Option 2.** A Customer registration must include a Full Name, in addition to the already-required mobile number and password (BR-AUTH-02 updated accordingly). Mobile number verification remains required exactly as already defined; no other profile field (email, address, profile photo, or any other candidate under `BDR-CUST-01`/`BDR-CUST-02`) is made required by this decision — those remain genuinely pending. A Customer does not require Hotel Manager or Platform Administrator approval — `BDR-005`'s open-eligibility stance is unchanged. |
| Business Rationale | Option 1 leaves the Hotel Manager unable to identify who they are transacting with — a real operational gap, not a cosmetic one, given the Platform already processes real payments (`BDR-002`, `BDR-004`). Option 3 (defer to later profile completion) would let a Customer complete an entire Booking while still anonymous to the Hotel Manager, since Booking creation does not itself require a complete profile (Customer Management Business Specification §11, Pending Decision `BDR-CUST-03`) — it does not actually solve the business problem, only delays whether it's solved. Option 2 is the minimum change that guarantees a Hotel Manager always has a Customer's name by the time any Booking exists, without inventing new required fields beyond the one need identified (`Project-Constitution.md` §3, Simplicity Over Complexity) and without touching `BDR-CUST-02`/other pending optional fields. |
| Impacted Documents | Authentication & Account Management Business Specification (`BR-AUTH-02`, Journey C2); Customer Management Business Specification (§10, §19 `BR-CUST-11`, §21 `BDR-CUST-01`); Booking Management Business Specification (Manager-visible Booking information) |
| Impacted Modules | Authentication & Account Management, Customer Management, Booking Management |
| Risks | An account registered before this decision has no Full Name on file — existing accounts are not retroactively populated (no fabricated name), so a Hotel Manager may see no name for a pre-existing Customer until that Customer sets one via their own profile. Not a data-loss risk (Full Name was never collected before), but a visible gap in existing data the Hotel Manager will notice. |
| Future Review Required | No — this resolves the one specific field identified as a real gap; the broader `BDR-CUST-01`/`BDR-CUST-02` question (email, address, profile photo, other candidates) remains separately pending and is not reopened by this decision. |
| Notes | Partially resolves Customer Management Business Specification §21 `BDR-CUST-01` (Required Customer Profile Information) for Full Name only — every other candidate field there remains `Pending`, per `BDR-CUST-02` (Optional Customer Information). Does not touch `BDR-CUST-03` (Profile Completion Requirement), which governs whether an *incomplete* profile blocks a Booking — out of scope here. |

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 2.9 | 2026-09-08 | Ahmed | Added BDR-018 (**Approved**): Required Customer Full Name at Registration — a Customer registration must now include a Full Name alongside mobile number and password. Partially resolves Customer Management Business Specification §21 `BDR-CUST-01` for this one field only; every other candidate profile field remains separately pending (`BDR-CUST-02`). Does not touch `BDR-CUST-03` (Profile Completion Requirement). |
| 2.8 | 2026-08-31 | Ahmed | Approved `BDR-017`: structured Hotel coordinates and editable address, OpenStreetMap capture, best-effort reverse geocoding, and mandatory manual-address fallback. |
| 2.6 | 2026-08-26 | Ahmed | Added BDR-016 (**Approved**): Required Hall Information — resolves Hall Management Business Specification §11 Pending Decision #2, the same hybrid model `BDR-015` established for Hotel (required: Hall Name, Capacity; optional: Description, Location/Area, Hall Photos; optional custom fields). Directed by Ahmed with the field list already specified. Does not resolve `BR-HALL-06`'s separate Amenity-list question, Pending Decision #7 (Hall Capacity Changes), or approve any Hall-media storage mechanism (no Hall equivalent of `ADR-0006` exists yet). |
| 2.5 | 2026-08-26 | Ahmed | BDR-015's Risks/Notes fields updated: the separate Cloudinary-vs-Supabase media-storage question they flagged as open is now resolved by `ADR-0006` (Supabase selected) — an architecture decision, tracked in `docs/02-architecture/adr/`, not a change to BDR-015's own Selected Decision. No BDR content changed, only the surrounding cross-reference. |
| 2.4 | 2026-08-26 | Ahmed | **BDR-015 resolved to `Approved`**, exactly as proposed in v2.3: required Hotel profile fields (Hotel Name, Description, Location, Contact Phone), optional fields (Email, Hotel Logo, Hotel Photos), and optional Hotel Manager-defined custom fields that may never substitute for a required field. Resolves Hotel Management Business Specification §11 Pending Decision #7. Hotel Management Business Specification (→ v1.2) and Technical Design updated in the same change to reflect this decision, per §6's ordering rule. The separate Cloudinary-vs-Supabase media-storage architecture question remains open and unresolved. |
| 2.3 | 2026-08-26 | Ahmed (AI-drafted, pending Ahmed's approval) | Added BDR-015 (**Proposed**, not yet Approved): Required Hotel Business-Profile Content — resolves Hotel Management Business Specification §11 Pending Decision #7. Drafted per `Decision-Making-Principles.md` §8 (AI may recommend; AI never becomes the decision maker) in response to a hybrid-profile-model request (standard required/optional fields + optional media + optional custom fields). No dependent document (Business Specification, Technical Design) has been updated — per §6's ordering rule, that happens only once this entry reaches `Approved`. Also surfaced, but does not resolve, a separate architecture-level conflict: the request specified Supabase for Hotel media storage, but `ADR-0001`/`technology-stack.md` currently designate Cloudinary as the approved provider — flagged as its own open question, not decided by this BDR. |
| 2.2 | 2026-08-09 | Ahmed | Added BDR-010–BDR-014 (all `Approved`): five Hotel Management lifecycle decisions the team had already reached — rejected-application edit/resubmit (BDR-010), pending-application withdrawal (BDR-011), suspension authority (BDR-012), information-validity restriction (BDR-013), and ordinary-vs-critical profile-change review policy (BDR-014). Recorded ahead of Hotel Management's Business Specification, per §6's ordering rule. All five extend or complement BDR-003 (Hotel Approval Process)'s manual-control model to the approved Hotel's ongoing lifecycle, not just onboarding. |
| 2.1 | 2026-08-03 | Ahmed | Added BDR-009 (Approved): Customer Registration Timing ("Hall-First" deferred registration), settled while authoring Authentication & Account Management's Business Specification |
| 1.0 | 2026-08-02 | Ahmed | Initial approved Business Decision Register, with six proposed (unapproved) initial decisions |
| 1.1 | 2026-08-02 | Ahmed | Added BDR-007 (Proposed): a scope conflict between `Project-Overview.md` §7 and the newly-approved technology stack (React + Vite), surfaced while authoring `Architecture-Principles.md` and `technology-stack.md` |
| 1.2 | 2026-08-02 | Ahmed | Added BDR-008 (Proposed): whether Hotels may operate multiple branches, surfaced while authoring `folder-structure.md` §4 |
| 2.0 | 2026-08-02 | Ahmed | **All eight decisions (BDR-001–008) resolved to `Approved`**, following the process in `Decision-Making-Principles.md` §5 with AI-drafted recommendations and Ahmed's explicit sign-off on each. Downstream documents updated accordingly — see their own version histories. |
