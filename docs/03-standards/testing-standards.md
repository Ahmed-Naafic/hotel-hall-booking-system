---
title: "Testing Standards"
document_type: Standard
status: Approved
version: 1.1
owner: Ahmed (Lead Quality Assurance Architect)
last_updated: 2026-08-26
---

# Testing Standards
## Hotel Hall Booking Management System

This document defines the official testing standards for this project. **Every feature
must satisfy these standards before it can be accepted. Every developer, reviewer, tester,
and AI assistant must comply with this document.**

> **Relationship to other documents:** this document is the exhaustive testing *standard*
> (levels, unit/integration/manual expectations, bug classification, Validation Report
> requirements). `07-validation-and-qa/test-strategy.md` (once authored) is narrower than
> originally planned — it applies this standard per release/module and defines UAT
> scheduling specifics; it does not redefine testing levels or standards, which live here.
> Test file *naming* and *placement* are already governed by `naming-conventions.md` §13
> and `folder-structure.md` §7 — not repeated here.

---

## 1. Purpose

A feature that hasn't been tested against its own Business Specification isn't done — it's
unverified. Testing is mandatory, not optional-if-time-permits, because
`Project-Constitution.md` §9 (Quality Principles) does not allow "validated before
acceptance" to be skipped under schedule pressure. **A feature cannot reach `Feature
Accepted` (`Development-Lifecycle.md` Phase 11) without satisfying this document.**

---

## 2. Testing Philosophy

- **Quality is everyone's responsibility** — not a separate phase owned only by whoever
  writes the Validation Report; the developer who implements a feature is responsible for
  its correctness first (`coding-standards.md` §1).
- **Test early.** A test is written alongside the code it verifies, not after the feature
  is "finished."
- **Test continuously.** Every Merge Request runs the test suite (`git-workflow-and-branching.md`
  §13) — testing isn't a phase that happens once at the end.
- **Test business behavior, not implementation details.** A test verifies what a Business
  Specification says should happen, not incidental internal structure that could change
  without changing correctness.
- **Automate where practical.** Manual testing (§7) is reserved for what genuinely benefits
  from human judgment (UX, exploratory testing) — not a substitute for automatable
  verification.
- **Repeatable and deterministic.** A test that passes or fails inconsistently for the same
  code is a defect in the test, fixed before it's trusted.

---

## 3. Testing Lifecycle

The testing-specific view of `Development-Lifecycle.md` Phases 8–11 — full detail (owners,
entry/exit criteria) lives there:

```
Implementation → Developer Verification → Peer Review → Unit Testing →
Integration Testing → Manual Functional Testing → Business Rule Validation →
Validation Report → Feature Acceptance
```

- **Developer verification** — the implementing developer runs and passes their own tests
  before opening a Merge Request (`git-workflow-and-branching.md` §5).
- **Peer review** — the assigned reviewer (`Team-Management.md` §5) checks test coverage
  and quality as part of Implementation Review (`Development-Lifecycle.md` Phase 9).
- **Unit / Integration Testing** (§5, §6) — automated, run in CI on every Merge Request.
- **Manual Functional Testing** (§7) — exploratory and UX-focused verification a script
  can't fully replace.
- **Business Rule Validation** (§8) — explicit confirmation against the Business
  Specification's acceptance criteria.
- **Validation Report** (§13) — the recorded evidence, owned by the assigned reviewer
  (`documentation-architecture.md` §13.2).

---

## 4. Testing Levels

| Level | Purpose |
|---|---|
| **Unit Testing** | Verifies one function/service/widget in isolation (§5). |
| **Integration Testing** | Verifies modules and layers work correctly together (§6). |
| **Manual Functional Testing** | Human verification of workflows, UX, and edge cases automation misses (§7). |
| **API Testing** | Verifies an endpoint's contract (`api-standards.md`) end to end — request in, response envelope and status code out. |
| **End-to-End Testing** *(future)* | Full user journey across a real or realistic client — not yet in scope; introduced once a module's complexity justifies the investment, per a future Technical Design. |
| **Performance Testing** *(future)* | Load/latency verification against `Architecture-Principles.md` §12 targets — introduced once real usage data exists to set meaningful targets against. |
| **Security Testing** *(future)* | Systematic penetration/vulnerability testing beyond `security-coding-standards.md`'s checklist — introduced ahead of production launch, not at MVP stage. |

"Future" levels are not skipped indefinitely — they're deferred because introducing them
now, before there's a real system to meaningfully test at that level, would violate
`Project-Constitution.md` §3 (Simplicity Over Complexity).

---

## 5. Unit Testing Standards

- **Scope** — one unit of business logic (typically one service method, one Flutter
  widget's logic, one React hook) per test.
- **Naming** — `naming-conventions.md` §13 (`bookings.service.test.js`); `describe`/`it`
  blocks name the behavior verified, not the function name alone.
- **Isolation** — a unit test never touches a real database, network call, or file system;
  dependencies are mocked (below).
- **Mocking** — a unit test mocks the repository/external-service layer it depends on, per
  `coding-standards.md` §5's layering — a service's unit test mocks its repository; it
  never runs the real Prisma query.
- **Expected behavior** — a test asserts on outcome (return value, thrown error, called
  dependency), not on internal implementation steps.
- **Failure reporting** — a failing test's output states which behavior failed and why,
  without needing to read the test's internals to understand the failure.

---

## 6. Integration Testing Standards

Verifies real interaction between layers/modules, with real infrastructure where it
matters:

- **API and database** — an integration test runs real Prisma queries against a real
  (test) database — this is where §5's mocked repository gets verified against the actual
  schema.
- **Cross-module interaction** — where one module calls another through its defined
  interface (`Architecture-Principles.md` §5), an integration test verifies that interface
  actually works, not just that each side's unit tests pass independently.
- **Authentication** — protected endpoints are integration-tested with real JWT
  verification, not a bypassed/mocked auth layer, since auth is exactly the kind of
  cross-cutting concern a unit test would miss.
- **External services** — Supabase, Firebase Cloud Messaging, and any payment provider
  are tested via mocks or test doubles (`Architecture-Principles.md` §11) — an integration
  test does not depend on a real external service being reachable to pass.

---

## 7. Manual Testing Standards

- **User workflow validation** — walking through a feature as the Customer, Hotel Manager,
  or Platform Administrator actually would, per `stakeholders-and-personas.md`.
- **UI verification** — visual correctness and usability that automated widget/component
  tests don't fully capture.
- **Error scenarios** — deliberately triggering failure paths (§9 of `api-standards.md`'s
  status codes) to confirm the user-facing behavior is correct, not just that the backend
  returns the right code.
- **Boundary conditions** — the edges of valid input (a Hold at exactly its expiry moment,
  a pagination request at the last page).
- **Negative testing** — confirming the system correctly rejects what it should reject, not
  only that it accepts what it should accept.

---

## 8. Business Rule Validation

**Every business rule documented in a Business Specification is validated before its
feature is accepted.** Every rule is traceable:

```
Business Specification rule → Validation result
```

A rule with no corresponding validation result is not considered verified, regardless of
how confident the implementation looks. **No undocumented behavior is accepted without
first updating the Business Specification** — if testing reveals behavior the
specification didn't anticipate, the specification is corrected and re-approved
(`Development-Lifecycle.md` §5, Failure Handling) before that behavior is accepted as
correct.

---

## 9. Test Data Standards

- **Test users, dummy hotels, dummy bookings** — synthetic, clearly-labeled data
  representative of real usage, defined per module as its Technical Design requires.
- **Seed data** lives in `scripts/seed/` (`folder-structure.md` §6), version-controlled and
  repeatable — running it twice produces the same starting state.
- **Repeatable datasets** — a test suite's data setup is deterministic; tests don't depend
  on data left over from a previous run.
- **Environment isolation** — test data lives only in test/development environments.
  **Production data is never used in development or testing**, per `Project-Constitution.md`
  §8 (Data privacy) — this is the same rule `database-standards.md` §17 states for backups,
  applied to test data specifically.

---

## 10. Bug Classification

| Severity | Meaning | Expected response |
|---|---|---|
| **Critical** | Data loss, security breach, or the system is unusable for a core flow (e.g. Bookings cannot be created). | Immediate fix, hotfix workflow if already released (`git-workflow-and-branching.md` §11). |
| **High** | A significant feature is broken or produces wrong results, with a workaround difficult or unavailable. | Fixed before the feature is accepted; blocks release if found post-release. |
| **Medium** | A feature is impaired but usable; a reasonable workaround exists. | Fixed before the feature is accepted where practical; may be scheduled if discovered late. |
| **Low** | A minor, cosmetic, or edge-case issue with minimal user impact. | Logged and scheduled; does not block acceptance by itself. |
| **Informational** | Not a defect — an observation, suggestion, or question worth recording. | No required action; may inform future work. |

---

## 11. Defect Workflow

```
Bug Found → Reproduce → Log Issue → Fix → Retest → Regression Test → Close
```

- **Reproduce** — a bug is confirmed reproducible before being logged; "cannot reproduce"
  is a valid, recorded outcome, not silently dropped.
- **Log issue** — recorded in GitLab (`git-workflow-and-branching.md` §13), with severity
  (§10) and a link to the affected Feature ID (`Team-Management.md` §7).
- **Fix** — follows the normal implementation and review process
  (`Development-Lifecycle.md` Phase 8–9) — a bug fix is not exempt from review.
- **Retest** — the original reproduction steps are re-run to confirm the fix.
- **Regression test** — the surrounding feature is re-verified to confirm the fix didn't
  break something else.
- **Close** — only after both retest and regression test pass.

---

## 12. AI Testing Rules

This restates and is governed by `Project-Constitution.md` §4 and
`coding-standards.md` §15 — see those for the canonical AI rules. Testing-specific
additions only:

- **AI must generate meaningful tests** — verifying actual business behavior (§2), not
  tests that merely execute code without asserting anything meaningful.
- **AI must never bypass testing** — never marking a test as skipped, or reducing coverage,
  to make a feature appear ready sooner.
- **AI must never remove a test without explicit approval** from the assigned reviewer.
- **AI must keep tests synchronized with implementation** — a change to behavior comes with
  a corresponding test update in the same change, not a follow-up "someday."

---

## 13. Validation Report Standards

Every Validation Report (`documentation-architecture.md` §13.2) includes:

- **Feature name** and Feature ID (`Team-Management.md` §7).
- **Test scope** — what was and wasn't covered by this validation pass.
- **Environment** — where testing was performed.
- **Test summary** — results across unit, integration, and manual testing (§4).
- **Business rule verification** — the traceability table from §8, rule by rule.
- **Defects found** — with severity (§10).
- **Defects resolved** — which of those were fixed and verified before this report closed.
- **Final recommendation** — Accept or Not Yet Accepted, with reasoning if the latter.

This is the required content for `08-templates/validation-report-template.md` once that
template is authored — this document defines the standard; the template operationalizes it.

---

## 14. Feature Acceptance Criteria

Restated from `Development-Lifecycle.md` Phase 11 and `Team-Management.md` §12 — a feature
is accepted only when **all** of the following are true:

- Business Specification, Technical Design, and Implementation Plan are `Approved`.
- Implementation is complete.
- Code review has passed (`coding-standards.md` §16).
- Unit tests pass (§5).
- Integration tests pass (§6).
- Manual validation is complete (§7).
- The Validation Report is `Approved` (§13).
- Documentation is updated to match what was actually built (`documentation-standards.md`
  §9).

---

## 15. Testing Checklist

What a reviewer checks specifically about testing coverage — the formal Implementation
Review approval itself is `review-checklists.md` and `Development-Lifecycle.md` Phase 9;
this is a reading aid.

- [ ] Business rules verified (§8), each traceable to the Business Specification.
- [ ] Positive scenarios tested.
- [ ] Negative scenarios tested (§7).
- [ ] Edge cases / boundary conditions tested (§7).
- [ ] Error handling verified (`coding-standards.md` §9).
- [ ] Authentication verified (§6).
- [ ] Authorization verified (`api-standards.md` §13).
- [ ] Validation verified (`coding-standards.md` §11).
- [ ] API behavior verified against `api-standards.md`.
- [ ] Database behavior verified against `database-standards.md`.
- [ ] Documentation updated.
- [ ] Validation Report completed (§13).

---

## 16. Continuous Improvement

Testing standards evolve the same way any standard does — through
`Decision-Making-Principles.md` §5, not informally. Lessons learned from defects (§11),
recurring bug classes (§10), or gaps discovered during Validation (§13) are proposed as
updates to this document, reviewed, and versioned (§8 of `documentation-standards.md`) —
testing practice is expected to genuinely improve as the project's real defect history
accumulates, not stay frozen at what seemed sufficient before any code existed.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.1 | 2026-08-26 | Ahmed | External-services example updated Cloudinary → Supabase, per `ADR-0006`. No standard changed, only the provider name. |
| 1.0 | 2026-08-03 | Ahmed | Initial approved Testing Standards |
