---
title: "ADR-0005: SMS Delivery Provider for Identity Verification & Password Reset"
document_type: Architecture Decision Record
status: Approved
last_updated: 2026-08-03
---

# ADR-0005: SMS Delivery Provider for Identity Verification & Password Reset

**Status:** Approved
**Date:** 2026-08-03
**Owner:** Ahmed (per `Decision-Making-Principles.md` §4, every ADR is approved by Ahmed)

## Context

Authentication & Account Management's Business Specification requires two flows that
deliver a message outside the app: mobile number verification (`BR-AUTH-02`) and password
recovery (`BR-AUTH-09`, "a verified contact channel already on file"). The only contact
channel the Business Specification actually establishes is the **mobile number** collected
at registration (`C2`, `BR-AUTH-02`) — it does not establish email as a registered or
verified channel for any account type. This ADR is therefore scoped to **SMS delivery
only**; introducing email as an additional channel would require its own Business
Specification change first, not this ADR (`Project-Constitution.md` §4, AI must never invent
business requirements).

`system-architecture-overview.md` §8 currently states: *"Maps, Email, SMS — Not currently
approved integrations. No Business Specification or ADR has introduced them; they are not
assumed into this architecture."* The Authentication & Account Management Technical Design
(§17, Item 2) and Implementation Plan (§6, §7) both identified this as a genuine blocker for
two specific flows (Technical Design §7.4 Password Recovery, §7.5 Identity Verification) and
raised it here rather than assuming an answer inside either document, per
`Decision-Making-Principles.md` §7's test: two different engineers would otherwise each have
to independently guess the same answer.

This meets the bar for an ADR because it introduces a new entry into
`system-architecture-overview.md` §8 (External Integrations) and, if approved, a new row in
`technology-stack.md` — both `docs/02-architecture/*` documents.

## Options Considered

Evaluated against `Decision-Making-Principles.md` §6 (Business Value, Security,
Maintainability, Scalability, Performance, Complexity, Cost, Risk, Developer Experience,
Future Growth). All options assume the provider sits behind a provider-agnostic abstraction
(`Architecture-Principles.md` §10–§11) — the same pattern already established for storage
(Cloudinary) and push notifications (Firebase Cloud Messaging) — so none of them is a hard
dependency regardless of which is chosen.

1. **Status quo — no approved SMS integration.** Leaves `BR-AUTH-02` and `BR-AUTH-09`
   unimplementable. Not a genuine option, listed only to satisfy
   `Decision-Making-Principles.md` §5's "status quo plus one genuine alternative" baseline.
   - *Business Value:* Fails it directly — two approved business rules stay unbuilt.
   - *Risk:* The dependency-root module (`Project-Overview.md` §23) remains partially
     blocked indefinitely.

2. **Twilio (Programmable SMS).** Widely-adopted, well-documented SMS API with an official
   Node.js SDK.
   - *Business Value:* Directly enables `BR-AUTH-02` and `BR-AUTH-09`.
   - *Security:* Mature provider with established delivery-status and fraud-monitoring
     tooling; credentials handled the same as any other secret
     (`naming-conventions.md` §10, `Project-Constitution.md` §8).
   - *Maintainability:* Large ecosystem, extensive documentation — lowers the cost of a
     three-person team supporting it long-term.
   - *Scalability:* Usage-based, scales with the Platform's actual Hotel/Customer volume
     without a capacity decision up front.
   - *Performance:* Low, predictable latency for transactional SMS; not a bottleneck for
     `BR-AUTH-02`/`BR-AUTH-09`'s flows.
   - *Complexity:* Low integration complexity behind the Verification Component's existing
     abstraction (Technical Design §4, §11).
   - *Cost:* Usage-based (per-message) pricing; exact current rates are a
     provider-published figure to confirm at implementation time, not fixed here — consistent
     with `Project-Overview.md` §13 treating provider cost as an operational detail, not an
     architectural one.
   - *Risk:* Low — a widely-used provider with no unusual dependency risk.
   - *Developer Experience:* Strong SDK and documentation reduce onboarding cost for
     whichever developer implements WBS-10/WBS-11b.
   - *Future Growth:* Same provider can later support additional channels (voice, WhatsApp)
     if a future Business Specification ever requires them — not assumed or scoped in now.

3. **AWS SNS (SMS support).** Usable if the project's eventual hosting provider is AWS
   (currently `TBD`, `Project-Overview.md` §13).
   - *Business Value:* Same as Option 2.
   - *Complexity/Developer Experience:* Adds a dependency on the AWS SDK and an AWS account
     specifically for this feature, ahead of any hosting-provider decision — couples an
     Authentication concern to an infrastructure decision that hasn't been made yet.
   - *Cost:* Usage-based, similar shape to Option 2.
   - *Risk:* Medium — if a different hosting provider is later chosen, this creates a
     second, unrelated cloud-provider dependency purely for SMS.
   - *Future Growth:* Reasonable if AWS is later chosen as the hosting provider; premature
     otherwise (`Architecture-Principles.md` §2, Simplicity before complexity — no evidence
     yet that AWS is the hosting answer).

4. **Vonage (SMS API, formerly Nexmo).** A credible alternative to Twilio with a comparable
   feature set.
   - Materially similar trade-offs to Option 2 across every criterion; included to satisfy
     `Decision-Making-Principles.md` §5's requirement that a genuine alternative — not just
     the status quo — is considered, and to leave a documented reason on record if Twilio is
     ever reconsidered later (§11 there).

## Recommendation

**Option 2 (Twilio)**, as a default provider behind the existing abstraction — not a hard
dependency, per `Architecture-Principles.md` §10–§11's "replaceable integrations" principle,
the same relationship `technology-stack.md` already establishes between Cloudinary and the
storage abstraction. Option 3 (AWS SNS) is not recommended ahead of a hosting-provider
decision (`Project-Overview.md` §13) it would otherwise be coupled to. Option 4 (Vonage) is a
reasonable fallback if Option 2 is rejected for a reason not yet identified.

This is a recommendation only, per `Decision-Making-Principles.md` §8 — AI may recommend and
compare options; it does not decide. The Decision below is Ahmed's to make.

## Decision

**Approved — Option 2 (Twilio).** Twilio Programmable SMS is the approved default SMS
delivery provider for Authentication & Account Management's identity-verification
(`BR-AUTH-02`) and password-reset (`BR-AUTH-09`) flows, behind the provider-agnostic
abstraction already built into the Verification Component (Technical Design §4, §11) — not
a hard dependency, per `Architecture-Principles.md` §10–§11. Decided by Ahmed, 2026-08-03,
per `Decision-Making-Principles.md` §4.

## Consequences

- `system-architecture-overview.md` §8 is updated: SMS moves from "not currently approved"
  to an approved integration (Twilio), scoped specifically to Authentication & Account
  Management's verification and password-reset flows — not a general-purpose SMS capability
  for every module.
- `technology-stack.md` gains a new row (SMS delivery: Twilio), following the same
  provider-abstraction pattern already documented there for storage and push notifications.
- Technical Design §7.4 and §7.5, and Implementation Plan WBS-10/WBS-11b, are now
  **unblocked** — no redesign of either document is required, since both were already built
  against the abstraction this decision fills in.
- A `TWILIO_*` credential set joins the environment-variable naming pattern in
  `naming-conventions.md` §10, never committed with real values — provisioning them is a
  Development-phase (WBS-10/WBS-11b) task, not resolved by this ADR itself.
- This ADR does not resolve Business Specification Pending Decision #2 (Mobile Number
  Verification Method — exact code format and validity window), which remains a separate,
  module-scoped business rule for Ahmed to settle in `business-specification.md` §10, not
  this ADR (`Decision-Making-Principles.md` §3 — a delivery *provider* is an architecture
  decision; a verification *code's* format and expiry is a business rule).
- Email remains out of scope for this module until a future Business Specification
  introduces it as a registered contact channel — this ADR does not open that door.

## Related

- Amends: `docs/02-architecture/system-architecture-overview.md` §8,
  `docs/02-architecture/technology-stack.md` (both updated alongside this approval)
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR(s): None — this is a technical/integration decision, not a business one
  (`business-specification.md` §10 explicitly distinguishes the two for this exact gap).
- Unblocks: `docs/05-technical-design/modules/01-authentication-and-account-management/technical-design.md`
  §7.4, §7.5, §17 (Item 2 — resolved); `docs/06-implementation-planning/modules/01-authentication-and-account-management/implementation-plan.md`
  WBS-10, WBS-11b.

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.1 | 2026-08-03 | Ahmed | Status changed `Proposed` → `Approved`: Ahmed selected Option 2 (Twilio). Decision and Consequences sections updated from conditional/recommended language to final; `Related` updated from "Blocks" to "Unblocks". `system-architecture-overview.md` and `technology-stack.md` updated to match, per `Decision-Making-Principles.md` §7 ("the ADR comes first; the architecture document is then updated to match it"). |
| 1.0 | 2026-08-03 | Ahmed | Initial `Proposed` ADR — drafted (Options, Trade-offs, Recommendation) per `Decision-Making-Principles.md` §5/§8; Decision awaiting Ahmed's approval. |
