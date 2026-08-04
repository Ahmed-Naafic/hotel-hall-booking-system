---
title: "Authentication & Account Management — Business Specification"
document_type: Business Specification
module: 01-authentication-and-account-management
status: Approved
owner: Ahmed
reviewer: Mohamed or Abukar (per documentation-architecture.md §4; confirmed complete by Ahmed 2026-08-03)
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md", "docs/Project-Glossary.md"]
version: 1.2
last_updated: 2026-08-03
---

# Authentication & Account Management — Business Specification
## Hotel Hall Booking Management System

> **Dependency note:** `docs/04-business/stakeholders-and-personas.md` is a formal dependency
> of every Business Specification (`documentation-architecture.md` §10.2) but is currently
> `Not Started`. This document grounds its actors instead in the approved Target Users table
> in `Project-Overview.md` §8, the only approved source of who these users are at the time of
> writing. It should be reconciled against `stakeholders-and-personas.md` once that document
> is authored, in case it introduces persona-level detail (goals, pain points) not captured
> here.
>
> **Process note:** `Project-Overview.md` §23 (Next Milestone) originally sequenced this
> Business Specification *after* several architecture and governance documents currently
> still `Not Started` (`security-architecture.md`, `docs/00-governance/definition-of-ready-and-done.md`,
> `docs/01-ai-governance/ai-governance.md`, `docs/07-validation-and-qa/review-checklists.md`)
> and one referenced-but-missing document (`domain-model-and-bounded-contexts.md`). This
> document was authored ahead of that sequencing on Ahmed's explicit instruction
> (2026-08-03). It does not depend on any of those documents' contents — none define business
> rules — but the Business Review gate (`documentation-architecture.md` §4) and the
> Definition of Ready (once authored) still apply before Technical Design begins.

---

## 1. Purpose

This document defines the business rules, account lifecycles, user journeys, and acceptance
criteria for **Authentication & Account Management** — Module 1 of the Platform, and the
dependency root of every other module (`Project-Overview.md` §23): no Customer, Hotel, or
Platform Administrator can use any other module's functionality without first authenticating
through this one.

This module governs **identity, credentials, login, logout, verification, password recovery,
account activation state, and session validity** for all three account types on the
Platform: Customer, Hotel, and Platform Administrator. It does not govern what an
authenticated user is *permitted to do* once logged in (§3 defines that boundary), and it
does not define any account type's business profile data beyond what is needed to create and
gate the account itself.

---

## 2. Scope

### 2.1 In Scope

- Customer account creation, login, logout, mobile number verification, password reset, and
  password change.
- Hotel account creation, onboarding-application submission, and the approval/rejection gate
  that determines whether a Hotel account may authenticate into Hotel features.
- Platform Administrator login, logout, and password change for an already-provisioned
  account.
- Account activation state (active / inactive / deactivated) for all three account types, and
  its effect on the ability to log in.
- The business-level guarantee of session validity (a logged-in state must eventually expire
  or be invalidated) — the specific duration and mechanism are a Technical Design concern
  (§10).
- Exception handling for invalid credentials, unauthorized access attempts, expired sessions,
  and deactivated-account login attempts, at the business-rule level.

### 2.2 Out of Scope

- **Hotel business profile content** (hotel name, address, halls, amenities, branch
  information) — owned by Hotel Management (Module 3). This module governs only the
  account-and-application-status fields needed to gate login and access (§6, §7.2).
- **Provisioning of Platform Administrator accounts.** Platform Administrator accounts are
  created through an internal process owned by Administration & Platform Management
  (Module 13); this module governs only how an already-provisioned Platform Administrator
  authenticates (§7.3).
- **Authorization / permission policy** — what an authenticated role may see or do once
  logged in is owned by Security & Access Control (Module 14). This module produces the
  authenticated identity and role that Module 14's policies are then applied to (§3).
- **Reviewing, approving, or rejecting a Hotel's onboarding application** as a business
  workflow — owned by Administration & Platform Management (Module 13) and governed by
  `BDR-003`. This module defines only the *effect* that application status has on the Hotel
  account's ability to authenticate (§7.2).
- Booking of hotel rooms, payment processing, and every other module's own business rules —
  per `Project-Overview.md` §7.
- Any specific numeric security parameter (password complexity rules, verification-code
  format, session/token duration, failed-attempt lockout thresholds) — tracked as pending
  business decisions in §10, not decided here, because no approved document currently sets
  them.

---

## 3. Actors / Roles Covered

Sourced from `Project-Overview.md` §8 (Target Users) and `Project-Glossary.md` §3, pending
`stakeholders-and-personas.md`:

| Role | Description | Account Origin |
|---|---|---|
| **Customer** | An individual or organization that books Halls through the Customer mobile application. | Self-registers (§7.1), subject to `BDR-005` (open eligibility) and `BDR-009` (deferred registration timing). |
| **Hotel** (represented by a **Hotel Manager** account) | The account representing a Hotel tenant, used to manage that Hotel's Halls, Bookings, Staff, and Events once approved. | Self-registers, then gated by Platform Administrator approval per `BDR-003` (§7.2). |
| **Hotel Staff** | Operates under a Hotel Manager, with scoped access. | Created by a Hotel Manager (Staff Management, Module 9) — not self-registered. Staff authentication follows the same login/session/password rules as any other account type in this module; account *creation* is Module 9's concern. |
| **Platform Administrator** | Operates the Platform: reviews Hotel applications, activates/deactivates accounts. | Provisioned internally (Administration & Platform Management, Module 13) — not self-registered (§2.2). |

---

## 4. Referenced Business Decisions

Per `business-decision-register.md` §6, this specification references rather than restates
the following approved decisions:

| BDR | Title | Relevance to this module |
|---|---|---|
| `BDR-001` | Platform Type | The Platform is a marketplace connecting independently-operating Customers and Hotels — this module authenticates both sides of that relationship without inserting Platform operational involvement. |
| `BDR-003` | Hotel Approval Process | Defines the manual Platform Administrator approval gate a Hotel account must pass before it can authenticate into Hotel features (§7.2). |
| `BDR-005` | Customer Eligibility | Confirms open Customer registration, subject only to the identity/contact verification this module defines (§6, §7.1). |
| `BDR-007` | Platform Administration Web Interface | The Platform Administrator reviews Hotel applications (Module 13) through the approved web dashboard; this module's Platform Administrator login (§7.3) is the entry point to that dashboard. |
| `BDR-009` | Customer Registration Timing | A Customer may browse Hotels and Halls without an account; registration is required only when proceeding to book a Hall (§7.1). |

---

## 5. Account Types & Lifecycle States

### 5.1 Customer Account

| State | Meaning | Entered When |
|---|---|---|
| *(No account)* | Browsing only — not a system state, but the default starting point per `BDR-009`. | Before registration. |
| **Active** | Registered, verified, able to log in and book. | Registration completed and mobile number verified (§6, BR-AUTH-02). |
| **Inactive / Deactivated** | Login is blocked. | A Platform Administrator deactivates the account, or a Customer-initiated deactivation if the Platform later approves one (§10 — pending business decision). |

### 5.2 Hotel Account

| State | Meaning | Entered When |
|---|---|---|
| **Registered** | Account and credentials exist; profile incomplete. | Hotel completes account creation (§7.2). |
| **Profile Complete** | Required business-profile information (owned by Hotel Management, Module 3) has been supplied. | Hotel finishes profile completion. |
| **Submitted / Under Review** | Onboarding application has been submitted to the Platform for review. | Hotel submits its application (§7.2). |
| **Approved / Active** | Platform Administrator has approved the application. | Approval action recorded by Administration & Platform Management (Module 13), per `BDR-003`. |
| **Rejected** | Platform Administrator has declined the application. | Rejection action recorded by Module 13. |
| **Deactivated** | A previously Approved Hotel account has had access revoked. | Platform Administrator action (§7.3). |

A Hotel account may authenticate (log in) at any state, but **may only access Hotel
operational features once in the Approved / Active state** (§6, BR-AUTH-07). A Rejected
Hotel is not automatically deleted; re-application handling is tracked as a pending business
decision (§10).

### 5.3 Platform Administrator Account

| State | Meaning |
|---|---|
| **Active** | Able to log in and perform administrative actions. |
| **Deactivated** | Login blocked — used when an administrator leaves the role or access must be revoked. |

Platform Administrator accounts do not pass through a registration or approval workflow —
they exist as Active from provisioning (Module 13, out of scope here per §2.2).

---

## 6. Business Rules

| ID | Rule |
|---|---|
| BR-AUTH-01 | A Customer may browse Hotels, Halls, availability, and pricing without an account or being logged in (`BDR-009`). |
| BR-AUTH-02 | A Customer must register an account, providing at minimum a mobile number and a password, and must verify that mobile number, before completing a Booking or accessing any account-specific feature (e.g. booking history, saved favorites). Registration eligibility is open per `BDR-005` — no age or category restriction applies. |
| BR-AUTH-03 | A Hotel must create an account, complete its business profile (Module 3), and submit an onboarding application before it can be reviewed by a Platform Administrator (`BDR-003`). |
| BR-AUTH-04 | A Hotel account may log in at any application state (Registered through Rejected), but may only access Hotel operational features (halls, bookings, staff, payments, events) once its application has reached **Approved / Active** (`BDR-003`). A Hotel attempting to access operational features before approval, or after rejection, must be blocked with a clear, business-worded explanation of its current application state. |
| BR-AUTH-05 | A Platform Administrator account is not self-registrable; it must already exist (provisioned by Module 13) before this module's login rules apply to it. |
| BR-AUTH-06 | Any account (Customer, Hotel, Platform Administrator) in a **Deactivated** or equivalent inactive state must be blocked from logging in, with a message indicating the account is inactive rather than a generic credential failure. |
| BR-AUTH-07 | A Hotel account whose application is **Under Review** or **Rejected** is a distinct condition from **Deactivated** (BR-AUTH-06) and must be communicated to the Hotel using its actual application state (§7.2, §8), not a generic "inactive account" message. |
| BR-AUTH-08 | Every account type must be able to change its own password while authenticated, after confirming its current password. |
| BR-AUTH-09 | Every account type must be able to request a password reset when it cannot log in due to a forgotten password, using a verified contact channel already on file for that account. A password reset must not reveal whether a given contact identifier is registered on the Platform (to prevent account enumeration). |
| BR-AUTH-10 | A logged-in session must not remain valid indefinitely; it must expire or otherwise require re-authentication after a period defined in the module's Technical Design (§10). |
| BR-AUTH-11 | An expired or otherwise invalid session attempting to access any account-specific or operational feature must be treated as unauthenticated and redirected to login, not shown a generic error. |
| BR-AUTH-12 | Repeated invalid login attempts against the same account must be treated as a business-relevant security event; the specific response (e.g. temporary lockout, warning) is not yet defined (§10). |
| BR-AUTH-13 | Logging out must fully end the authenticated session such that no further account-specific or operational action can be performed without logging in again. |
| BR-AUTH-14 | This module produces the authenticated identity and role of a user; what that identity and role are permitted to do is governed by Security & Access Control (Module 14), not by this module (§2.2). |

---

## 7. User Journeys

### 7.1 Customer

| # | Journey | Preconditions | Flow | Result |
|---|---|---|---|---|
| C1 | Browse without an account | None | Customer opens the Customer application and searches/views Hotels, Halls, availability, and pricing. | No account is required or created (BR-AUTH-01). |
| C2 | Register when booking | Customer has selected a Hall to book | Customer proceeds to book; is prompted to register (mobile number, password); submits registration. | A Customer account is created in an unverified state pending C3. |
| C3 | Verify mobile number | Customer has just registered, or has an unverified account | Customer receives and enters a verification credential tied to their mobile number. | Account becomes Active (§5.1); Customer may proceed to complete the Booking. |
| C4 | Log in | Customer has an Active account | Customer enters credentials. | Customer is authenticated and reaches their account-specific and booking features. |
| C5 | Log out | Customer is logged in | Customer chooses to log out. | Session ends (BR-AUTH-13); Customer returns to the unauthenticated browsing experience (C1). |
| C6 | Forgot password | Customer cannot log in | Customer requests a password reset via their verified contact channel; follows the reset flow; sets a new password. | Customer can log in with the new password (BR-AUTH-09). |
| C7 | Change password | Customer is logged in | Customer provides current password and a new password. | Password is updated (BR-AUTH-08); no other session state changes. |
| C8 | Access protected resources | Customer is logged in | Customer navigates to an account-specific feature (e.g. booking history). | Access is granted, subject to Module 14's authorization policy (BR-AUTH-14). |
| C9 | Inactive account attempt | Customer's account has been deactivated | Customer attempts to log in. | Login is blocked with an inactive-account message (BR-AUTH-06), not a generic credential error. |

### 7.2 Hotel

| # | Journey | Preconditions | Flow | Result |
|---|---|---|---|---|
| H1 | Create account | None | Hotel provides account credentials and basic identifying information. | Hotel account created in **Registered** state (§5.2). |
| H2 | Complete profile | Hotel account exists | Hotel supplies its business profile information (Module 3 scope). | Account reaches **Profile Complete**. |
| H3 | Submit onboarding application | Profile is complete | Hotel submits the application for Platform review. | Account reaches **Submitted / Under Review** (BR-AUTH-03). |
| H4 | Application under review | Application submitted | No Hotel action; a Platform Administrator is reviewing (Module 13). | Account remains **Under Review**; Hotel may log in but not access operational features (BR-AUTH-04, BR-AUTH-07). |
| H5 | Application approved | Platform Administrator approves (Module 13, `BDR-003`) | — | Account reaches **Approved / Active**; full Hotel operational access unlocked. |
| H6 | Application rejected | Platform Administrator rejects (Module 13, `BDR-003`) | — | Account reaches **Rejected**; Hotel may log in but not access operational features, and is shown its rejected status (BR-AUTH-07). Re-application handling is tracked as a pending business decision (§10). |
| H7 | Log in after approval | Account is Approved / Active | Hotel enters credentials. | Full access to Hotel operational features. |
| H8 | Access attempt before approval | Account is Registered, Profile Complete, or Under Review | Hotel logs in and attempts to reach an operational feature (e.g. Hall listing). | Blocked with the account's actual application state explained (BR-AUTH-04, BR-AUTH-07). |

### 7.3 Platform Administrator

| # | Journey | Preconditions | Flow | Result |
|---|---|---|---|---|
| A1 | Log in | Account provisioned and Active (Module 13) | Administrator enters credentials. | Authenticated into the Platform Administration web dashboard (`BDR-007`). |
| A2 | Log out | Administrator is logged in | Administrator logs out. | Session ends (BR-AUTH-13). |
| A3 | Change password | Administrator is logged in | Same as C7. | Password updated. |
| A4 | Deactivated account attempt | Administrator's account has been deactivated | Administrator attempts to log in. | Blocked with an inactive-account message (BR-AUTH-06). |

*Reviewing, approving, rejecting Hotel applications, and activating/deactivating accounts are
Administration & Platform Management (Module 13) workflows — out of scope here per §2.2. This
module governs only the authentication (A1–A4) that gets a Platform Administrator into that
workflow.*

---

## 8. Exception Scenarios

| Scenario | Business Rule | Expected Business Behavior |
|---|---|---|
| Invalid login credentials | — | Login is rejected with a message that does not reveal whether the identifier (mobile number/email) exists on the Platform (consistent with BR-AUTH-09's anti-enumeration intent), distinguishing this case from BR-AUTH-06 (inactive account) and BR-AUTH-07 (Hotel application state). |
| Unauthorized access attempt | BR-AUTH-11, BR-AUTH-14 | An unauthenticated or insufficiently-privileged request for a protected feature is denied and, if unauthenticated, redirected to login. Privilege-level denial (an authenticated but unauthorized role) is a Module 14 concern this module surfaces the identity for. |
| Session expiration | BR-AUTH-10, BR-AUTH-11 | The user is treated as logged out and returned to login when next attempting an account-specific or operational action; no destructive action is silently performed on an expired session. |
| Password recovery | BR-AUTH-09 | Handled per C6 for any account type capable of self-service reset. Whether Platform Administrator accounts self-reset or require Module 13 intervention is tracked as a pending business decision (§10). |
| Password change | BR-AUTH-08 | Handled per C7 / A3 for any authenticated account. |
| Invalid or expired session | BR-AUTH-11 | Same handling as session expiration above — treated as unauthenticated, not as an error state requiring special messaging. |
| Deactivated account login attempt | BR-AUTH-06 | Blocked with an explicit inactive-account message, for all three account types. |
| Hotel accessing features before approval | BR-AUTH-04, BR-AUTH-07 | Blocked with the Hotel's actual application state explained, distinct from a deactivated-account message. |

---

## 9. Acceptance Criteria

Written in Given/When/Then form against the journeys in §7 and rules in §6. Numeric
parameters left as **[defined in Technical Design]** are intentionally not fixed here — see
§10.

1. **Browsing without an account** — Given a Customer with no account, when they search or
   view Hotels and Halls, then no login prompt or account creation is required (BR-AUTH-01).
2. **Deferred registration** — Given a Customer with no account, when they attempt to proceed
   with booking a Hall, then they are prompted to register before the Booking can be created
   (BR-AUTH-02, `BDR-009`).
3. **Mobile verification gate** — Given a Customer who has registered but not verified their
   mobile number, when they attempt to complete a Booking or access account-specific
   features, then they are required to complete verification first (BR-AUTH-02).
4. **Hotel approval gate** — Given a Hotel account that is not in the Approved / Active
   state, when the Hotel Manager attempts to access an operational feature, then access is
   denied and the account's actual application state is shown (BR-AUTH-04, BR-AUTH-07).
5. **Approved Hotel access** — Given a Hotel account in the Approved / Active state, when the
   Hotel Manager logs in, then all Hotel operational features are accessible, subject to
   Module 14's role policy.
6. **Deactivated account blocked** — Given any account type in a Deactivated state, when
   login is attempted with otherwise-correct credentials, then login is refused with an
   inactive-account message, not a generic credential error (BR-AUTH-06).
7. **Invalid credentials** — Given any account type, when login is attempted with incorrect
   credentials, then login is refused without revealing whether the identifier exists on the
   Platform.
8. **Session expiry** — Given an authenticated user whose session has expired
   **[duration defined in Technical Design]**, when they attempt an account-specific or
   operational action, then they are treated as unauthenticated and redirected to login
   (BR-AUTH-10, BR-AUTH-11).
9. **Password reset** — Given a user who cannot log in due to a forgotten password, when they
   request and complete a password reset through their verified contact channel, then they
   can log in with the new password and not the old one (BR-AUTH-09).
10. **Password change** — Given an authenticated user, when they submit their correct current
    password and a new password, then the password is updated and future logins require the
    new password (BR-AUTH-08).
11. **Logout completeness** — Given an authenticated user, when they log out, then no further
    account-specific or operational action succeeds without logging in again (BR-AUTH-13).

---

## 10. Pending Business Decisions

Per `Project-Constitution.md` §4 ("AI must never invent business rules") and
`documentation-standards.md` §13 (TBD items require an explicit reason and owner), the items
below are **not** informal questions — each is a genuine business decision this module needs,
tracked here until it is formally raised through `business-decision-register.md`'s own
process (`Decision-Making-Principles.md` §5: options considered, trade-offs evaluated, Ahmed
decides) and recorded there as its own `BDR-0##` entry, beginning at `Proposed` status per
the register's lifecycle (§2).

None of these block the business rules and journeys in §5–§9, which hold regardless of how
each is eventually decided — only the specific parameter or policy is undetermined. Each
should reach `Approved` in the register before this module's Technical Design finalizes the
corresponding behavior; a Technical Design must not silently encode an answer to any of these
on its own (`business-decision-register.md` §1).

| # | Pending Decision (Future BDR Title) | Category | Business Problem | Related Rules / Journeys |
|---|---|---|---|---|
| 1 | Password Strength Policy | Operational Policies | No approved document (`security-coding-standards.md`, `security-architecture.md` — both `Not Started`) sets a minimum password strength standard for any account type. | BR-AUTH-08, BR-AUTH-09 |
| 2 | Mobile Number Verification Method | Customer Policies | The business timing of mobile verification is set (BR-AUTH-02), but the verification mechanism and how long a verification credential remains valid are not defined in any approved document. | BR-AUTH-02, C3 |
| 3 | Session Validity Duration | Platform Policies | `mobile-application-architecture.md` §12 defers session duration to this module's Technical Design, but how long a user stays logged in is a business-relevant policy, not purely a technical default, and should be decided as one. | BR-AUTH-10, Acceptance Criterion 8 |
| 4 | Failed Login Attempt Handling | Platform Policies | No lockout, throttling, or warning policy for repeated invalid login attempts is currently approved for any account type. | BR-AUTH-12 |
| 5 | Customer Self-Deactivation | Customer Policies | Whether a Customer may deactivate their own account, or deactivation is always Platform-Administrator-initiated, is not addressed by any approved decision. | §5.1 |
| 6 | Hotel Re-Application After Rejection | Hotel Policies | `BDR-003` approves the Hotel approval *gate* but not whether, or how, a Rejected Hotel may resubmit an application. | H6 |
| 7 | Platform Administrator Credential Recovery | Operational Policies | Whether a Platform Administrator uses the same self-service password-reset flow as Customers and Hotels, or administrator credential recovery is instead an Administration & Platform Management (Module 13) process, is not addressed by any approved decision. | §7.3 |

---

## 11. Dependencies & References

- `Project-Overview.md` §5 (Objectives), §6–§7 (Scope), §8 (Target Users), §23 (Next
  Milestone) — this module's mandate and place in the roadmap.
- `docs/04-business/business-decision-register.md` — `BDR-001`, `BDR-003`, `BDR-005`,
  `BDR-007`, `BDR-009` (§4).
- `Project-Glossary.md` §3 — Customer, Hotel, Hotel Manager, Staff, Platform Administrator
  definitions used throughout.
- `docs/02-architecture/mobile-application-architecture.md` §8, §12 — confirms session
  handling and re-authentication are treated as this module's Technical Design output, not
  fixed at the architecture layer.
- `docs/04-business/modules/03-hotel-management/business-specification.md` (`Not Started`) —
  owns the Hotel business-profile content referenced but not defined in §7.2.
- `docs/04-business/modules/13-administration-and-platform-management/business-specification.md`
  (`Not Started`) — owns the Hotel application review/approve/reject workflow and Platform
  Administrator provisioning referenced but not defined in §7.2–§7.3.
- `docs/04-business/modules/14-security-and-access-control/business-specification.md`
  (`Not Started`) — owns the authorization policy this module's authenticated identity feeds
  into (BR-AUTH-14).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.2 | 2026-08-03 | Ahmed | Status changed `Draft` → `Approved`: independent review by Mohamed or Abukar is complete, per `documentation-architecture.md` §4's no-self-review rule. This document is now the authoritative source of truth for Module 1 — Technical Design may begin (`documentation-architecture.md` §5). |
| 1.1 | 2026-08-03 | Ahmed | §10 renamed from "Open Business Questions" to "Pending Business Decisions" and reframed: each item is now a named future `BDR-0##` candidate (title, category, business problem) to be formally proposed in `business-decision-register.md`, rather than an informal open question — keeps unresolved policy tracked through the same governance mechanism as every other business decision. Cross-references elsewhere in the document (§2.2, §5.1, §5.2, H6, Password recovery) updated to match. |
| 1.0 | 2026-08-03 | Ahmed | Initial draft Business Specification for Authentication & Account Management, authored ahead of the `Project-Overview.md` §23 sequencing on Ahmed's explicit instruction. Grounded in `BDR-001`, `BDR-003`, `BDR-005`, `BDR-007`, and newly-recorded `BDR-009`. Not yet reviewed — see status. |
