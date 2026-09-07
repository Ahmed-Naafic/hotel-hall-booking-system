---
title: "Notification Management — Business Specification (Notification V1)"
document_type: Business Specification
module: 10-communication-and-notification-management
status: Approved
owner: Product (Ahmed)
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/05-booking-management/business-specification.md", "docs/04-business/modules/07-payment-management/business-specification.md", "docs/04-business/modules/03-hotel-management/business-specification.md"]
last_updated: 2026-09-07
---

## Naming Note

This module's approved name in `Development-Roadmap.md`/`Team-Management.md` is
"Communication & Notification Management." **Notification V1, scoped by this document, is
Notification only.** Communication (in-app chat/messaging between Customer, Hotel Manager,
and Platform Administrator) is an explicitly separate, future feature and is out of scope
here — nothing in this document, its Technical Design, or its Implementation Plan introduces
any chat/messaging capability.

## Scope

Notification V1 tells a Customer, Hotel Manager, or Platform Administrator about a real
business event that has already happened elsewhere in the system (a Booking, a payment
report/verification, a Hotel application). It is read-only with respect to those events — a
Notification is a side effect of an existing business operation, never a new way to trigger
one. Delivery is in-app persistence (source of truth) plus a best-effort push notification
(Firebase Cloud Messaging, already the platform's approved provider — `technology-stack.md`,
ADR-0001). Chat/messaging, per-type notification preferences, email/SMS delivery, and
Staff-account notifications (Staff Management, Module 9, is not yet implemented) are all out
of scope for V1.

## Recipients

- **Customer** — the individual who owns the Booking a notification concerns.
- **Hotel Manager** — the single user who registered the Hotel a notification concerns
  (`Hotel.registeredByUserId`; Hotel Management has no multi-manager assignment yet).
- **Platform Administrator** — broadcast to every account of that type. Hotel-application
  review already has no per-administrator assignment (any Platform Administrator may act on
  any Hotel's application — `administration.routes.js`), so a targeted "which admin" concept
  does not exist to route around; every admin notification is visible to the whole role.

## Notification Catalog

| # | Recipient | Event | Triggering backend transition |
|---|---|---|---|
| C1 | Customer | Booking request submitted | `booking.service.js#createBooking` |
| C2 | Customer | Booking confirmed | `transitionHotel` → `CONFIRMED` |
| C3 | Customer | Booking rejected | `transitionHotel` → `REJECTED` |
| C4 | Customer | Booking cancelled | `cancelCustomer` or `transitionHotel` → `CANCELLED` (cancelled by the Manager) |
| C5 | Customer | Payment reported | `reportPayment` (confirms the Customer's own report was recorded) |
| C6 | Customer | Payment verified | `verifyPayment` → `PAID` |
| C7 | Customer | Payment rejected | `verifyPayment` → `REJECTED` |
| C8 | Customer | Booking expired | lazy expiration (`expireOverdue`) transitioning `PENDING` → `EXPIRED` |
| M1 | Hotel Manager | New booking request | `createBooking` (own Hotel) |
| M2 | Hotel Manager | Customer reported payment | `reportPayment` (own Hotel) |
| M3 | Hotel Manager | Customer cancelled booking | `cancelCustomer` (own Hotel) |
| A1 | Platform Administrator | New hotel application | `application.service.js#submitOrResubmitApplication` (fresh submission) |
| A2 | Platform Administrator | Hotel application withdrawn | `withdrawApplication` |
| A3 | Platform Administrator | Hotel application resubmitted | `submitOrResubmitApplication` (resubmission after rejection) |

C4's "cancelled by the Manager" case and M3 are the same underlying event
(`transitionHotel`/`cancelHotel` → `CANCELLED`) viewed from each side — the Customer is
notified their Booking was cancelled regardless of who cancelled it; the Manager is notified
only when the *Customer* was the actor, since a Manager does not need to be told about their
own action.

## Business Rules

Approved by the Product Owner (Ahmed) via direct instruction, 2026-09-07, per
`ai-governance.md`'s AI-drafts/human-approves model — recorded here as this module's
authoritative rule set rather than left implicit in conversation
(`Decision-Making-Principles.md` §5, Documentation before Implementation).

1. A Notification is created only as a side effect of a real backend business event listed in
   the Notification Catalog above — never speculatively, never from a Flutter screen.
2. Every Notification is persisted before anything else happens to it.
3. A Notification has exactly one of two states: `UNREAD` or `READ`.
4. A user may mark a single Notification of their own `READ`.
5. A user may mark all of their own Notifications `READ` in one action.
6. A user may view their own Notification history, newest first.
7. There is no automatic retention or deletion policy in V1 — a read Notification remains in
   history.
8. Tapping a Notification navigates to the existing screen most relevant to it (§"Navigation
   Targets" in the Technical Design) where one exists; it never invents a new screen.
9. Every Notification access is scoped to the authenticated caller's own identity, role, and
   (for a Hotel Manager) own Hotel — enforced the same way every other own-Hotel/own-Booking
   check in this codebase already is (`architecture-principles.md` §5).
10. A Customer can never read another Customer's Notification.
11. A Hotel Manager can never read a Notification about a Hotel they do not own.
12. An Admin Notification is visible only to authenticated Platform Administrators.
13. The persisted Notification is the source of truth for whether it exists and its
    read/unread state — push delivery never changes either.
14. Push delivery is a best-effort side channel, not the record of whether a Notification
    "happened."
15. A push delivery failure never prevents or removes the persisted Notification.
16. Successful push delivery never marks a Notification `READ` by itself — only the user
    opening/acting on it does.
17. The same business event never creates two Notifications for the same recipient
    (idempotent by construction — see Technical Design's per-event trigger points, each
    called at most once per transition).
18. Notification creation logic lives entirely in backend business services, never in
    Flutter.
19. A push delivery failure never rolls back or fails the underlying business operation that
    triggered it (the Booking, payment action, or Hotel application transition it describes
    already succeeded before the Notification is even created).
20. Communication/Chat is not part of Notification V1 (see "Naming Note").

## Out of Scope for V1

- Per-type notification preferences/opt-out — explicitly deferred by
  `mobile-application-architecture.md` §11 ("per the eventual Notification Management
  Business Specification — not assumed here") to this document, and not included, since nothing
  in the approved rule set above requires it.
- Email or SMS delivery of a Notification (push + in-app only).
- Any notification for a Staff account (Module 9 is not implemented).
- Admin Web notification UI, unless Technical Design finds the existing Admin Web
  architecture already supports it cheaply — not assumed here.

## Identified Gap (Recommendation Only — Not Implemented)

Hotel Management's approved lifecycle already lets a Platform Administrator approve or
reject a Hotel's application (`application.service.js#recordDecision`), but the Notification
Catalog above has no Hotel-Manager-facing "your application was approved/rejected" entry —
the Phase 2 instruction's Hotel Manager list only specifies M1–M3. This looks like a natural
gap (the Hotel Manager arguably needs to know the outcome of their own application), but it
is not in the approved catalog, so **it is not implemented in V1** — adding it would be this
document inventing a business event rather than the Product Owner approving one
(`Project Rule 1`). Recorded here as a candidate for a future Notification V1.1 decision.

## Acceptance Criteria

- AC-1: Each of the 14 Notification Catalog events reliably produces exactly one persisted
  Notification for its listed recipient(s).
- AC-2: A Notification list is scoped to the caller's own identity/role/Hotel, verified
  against another user's/Hotel's Notifications being unreachable (403/404, matching this
  codebase's existing cross-tenant convention).
- AC-3: Marking one Notification read, and marking all read, both persist correctly and are
  reflected on the next fetch.
- AC-4: A push delivery failure (simulated) never prevents the Notification from existing or
  being readable.
- AC-5: Tapping a Notification in Customer Mobile/Manager Mobile opens the correct existing
  destination screen for its type.

## Traceability

| Concern | Owning Module |
|---|---|
| Booking lifecycle events | Booking Management (05) |
| Payment report/verify events | Payment Management (07) |
| Hotel application events | Hotel Management (03) / Administration & Platform Management (13) |
| Recipient identity/role | Authentication & Account Management (01) |
| Push delivery provider | ADR-0001 (Firebase Cloud Messaging) |
| Notification persistence, read state, delivery orchestration | Notification Management (this module) |
