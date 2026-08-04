---
title: "Business Decision Register"
document_type: Business / Governance
status: Approved
version: 2.1
owner: Ahmed (Product Governance Architect)
last_updated: 2026-08-03
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

All eight decisions below are **`Approved`**, per the process in
`Decision-Making-Principles.md` §5: each was analyzed, at least two genuine options were
weighed against the evaluation criteria in §6 of that document, a recommendation was drafted
by AI assistance, and the decision itself was made by Ahmed — consistent with §4 (Business
Decisions: Ahmed) and §8 (AI may recommend; AI never becomes the decision maker).

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

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 2.1 | 2026-08-03 | Ahmed | Added BDR-009 (Approved): Customer Registration Timing ("Hall-First" deferred registration), settled while authoring Authentication & Account Management's Business Specification |
| 1.0 | 2026-08-02 | Ahmed | Initial approved Business Decision Register, with six proposed (unapproved) initial decisions |
| 1.1 | 2026-08-02 | Ahmed | Added BDR-007 (Proposed): a scope conflict between `Project-Overview.md` §7 and the newly-approved technology stack (React + Vite), surfaced while authoring `Architecture-Principles.md` and `technology-stack.md` |
| 1.2 | 2026-08-02 | Ahmed | Added BDR-008 (Proposed): whether Hotels may operate multiple branches, surfaced while authoring `folder-structure.md` §4 |
| 2.0 | 2026-08-02 | Ahmed | **All eight decisions (BDR-001–008) resolved to `Approved`**, following the process in `Decision-Making-Principles.md` §5 with AI-drafted recommendations and Ahmed's explicit sign-off on each. Downstream documents updated accordingly — see their own version histories. |
