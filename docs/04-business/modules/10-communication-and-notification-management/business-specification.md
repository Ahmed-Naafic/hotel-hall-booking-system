---
title: "Notification & Communication Management — Business Specification (Notification V1, Communication V1)"
document_type: Business Specification
module: 10-communication-and-notification-management
status: Approved
owner: Product (Ahmed)
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/05-booking-management/business-specification.md", "docs/04-business/modules/07-payment-management/business-specification.md", "docs/04-business/modules/03-hotel-management/business-specification.md"]
last_updated: 2026-09-14
---

## Naming Note

This module's approved name in `Development-Roadmap.md`/`Team-Management.md` is
"Communication & Notification Management." This document originally scoped Notification V1
only, with Communication (in-app chat/messaging) explicitly deferred as a separate future
feature. **Communication V1 is now approved and specified below** ("Communication V1"
section) — Ahmed approved its scope via direct instruction, 2026-09-14, per
`ai-governance.md`'s AI-drafts/human-approves model, the same model this document's own
Notification V1 Business Rules were approved under. The two remain genuinely separate
capabilities (different data, different recipients, different rules) documented in one file
because they share the same approved module number.

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
| M4 | Hotel Manager | Hotel application approved | `application.service.js#recordDecision` (`decision: 'APPROVED'`) |
| M5 | Hotel Manager | Hotel application rejected | `application.service.js#recordDecision` (`decision: 'REJECTED'`) |
| M6 | Hotel Manager | Hotel suspended | `suspension.service.js#suspendHotel` |
| M7 | Hotel Manager | Hotel deactivated | `suspension.service.js#deactivateHotel` |
| M8 | Hotel Manager | Hotel reactivated | `suspension.service.js#reactivateHotel` |
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
- ~~Admin Web notification UI, unless Technical Design finds the existing Admin Web
  architecture already supports it cheaply — not assumed here.~~ **Resolved 2026-09-11:**
  the existing Admin Web header already had a bell/dropdown shell (`NotificationsMenu.jsx`,
  built ahead of this module against the approved nav composition, but never wired to real
  data since no Notification module existed yet). Wiring it to the same `/notifications`
  routes Customer/Manager Mobile already use required no new frontend infrastructure — no
  push delivery, no new screen, no router — so it is in scope: a Platform Administrator now
  sees `NEW_HOTEL_APPLICATION`/`HOTEL_APPLICATION_WITHDRAWN`/`HOTEL_APPLICATION_RESUBMITTED`
  Notifications in-app (list, unread count, mark read), the same in-app treatment every
  other client gets alongside its push. See Technical Design's "Admin Web" section.

## Identified Gap — Resolved (`BDR-021`)

Hotel Management's approved lifecycle already let a Platform Administrator approve or reject
a Hotel's application (`application.service.js#recordDecision`), but the Notification
Catalog originally had no Hotel-Manager-facing "your application was approved/rejected"
entry — flagged here as a candidate future decision rather than assumed. Ahmed approved
closing this gap on 2026-09-11 (`BDR-021`): `M4`/`M5` above are the result — the Hotel
Manager who registered the Hotel now receives a Notification for both outcomes, the same
recipient rule and delivery mechanism `M1`–`M3` already use.

## Identified Gap — Resolved (`BDR-022`)

Hotel Management newly gained Platform-Administrator-triggered suspend/deactivate/reactivate
actions (`suspension.service.js`), but the Notification Catalog had no Hotel-Manager-facing
entry for any of the three. Ahmed approved closing this gap on 2026-09-11 (`BDR-022`), the
same category of fix `BDR-021` already made for application decisions: `M6`–`M8` above are
the result — the Hotel Manager who registered the Hotel now receives a Notification when
their Hotel is suspended, deactivated, or reactivated, using the same recipient rule and
delivery mechanism as every other Hotel Manager notification.

## Acceptance Criteria

- AC-1: Each of the 19 Notification Catalog events reliably produces exactly one persisted
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

---

## Communication V1

Approved by Ahmed via direct instruction, 2026-09-14, per `ai-governance.md`'s
AI-drafts/human-approves model — recorded here as this capability's authoritative scope
rather than left implicit in conversation (`Decision-Making-Principles.md` §5, Documentation
before Implementation).

### Scope

Communication V1 lets the Customer who made a Booking and the Hotel Manager whose Hotel it
belongs to exchange text messages about that Booking. It is a genuinely new capability, not a
Notification — a message is authored by a person for another person, never a side effect of
a business event. The two capabilities share this module's delivery mechanism (a new message
triggers a push Notification, reusing the exact Notification V1 infrastructure above) but are
otherwise independent: different data, different recipients, different rules.

### Recipients / Participants

- **Customer** — the individual who owns the Booking a conversation concerns
  (`Booking.customerUserId`).
- **Hotel Manager** — the single user who registered the Hotel the Booking's Hall belongs to
  (`Hotel.registeredByUserId`), the same recipient identity Notification V1 already uses.
- No other role participates in V1. Platform Administrator chat access, and any
  Manager-to-Administrator channel, are explicitly out of scope (see below).

### Business Rules

1. A conversation is scoped to exactly one Booking — there is no standalone/general
   Customer-Hotel conversation independent of a Booking, and no cross-Booking thread. The
   Booking itself is the thread; no separate "Thread" entity is created.
2. Only the Booking's own Customer and the Booking's Hotel's own Manager may send or read
   messages in that Booking's conversation — enforced the same own-Hotel/own-Booking way
   every other cross-tenant check in this codebase already is
   (`architecture-principles.md` §5).
3. A message is plain text only in V1 — no photo/file/media attachments (matches Notification
   V1's own decision to keep a first cut deliberately narrow).
4. A message cannot be edited or deleted once sent (no approved requirement for either;
   matches this codebase's general preference for an accurate, immutable history over
   editable state where not explicitly required).
5. A message has a read state: unread until the recipient (the participant who did not send
   it) marks it read. There is no partial/per-message read receipt UI in V1 beyond "has the
   other participant read up to this point" — marking read is an all-at-once action over a
   Booking's conversation (§7), the same shape Notification V1's own `read-all` already uses.
6. A user may view their own conversation's full message history, oldest first (a
   conversation is read top-to-bottom like a normal chat transcript — deliberately the
   opposite order from the Notification list, which is newest-first, because a Notification
   list is a history of separate events while a conversation is a single continuous
   exchange).
7. A user may mark every unread message in one Booking's conversation (sent by the other
   participant) read in a single action, the moment they open that conversation — mirroring
   how a real messaging app marks a thread read on open, not requiring a separate explicit
   tap per message.
8. A user may see a total unread-message count across all their own Bookings' conversations,
   for a badge — the same treatment Notification V1's own unread count already gets, kept as
   a second, independent badge (never merged into the Notification unread count, since a
   message and a Notification are different kinds of thing a user needs to notice
   separately).
9. Sending a message triggers exactly one push Notification to the other participant
   (`NEW_CHAT_MESSAGE`, added to the Notification Catalog below) — reusing Notification V1's
   existing persistence/push machinery (Business Rules 13-19 above apply to it unchanged: a
   push failure never blocks or is the record of the message itself).
10. A conversation is available for as long as its Booking exists — there is no separate
    retention/deletion policy for messages in V1 (matches Notification V1's own "no
    automatic retention" decision), and no restriction based on the Booking's own status
    (a Customer and Manager may keep messaging about a CANCELLED or COMPLETED Booking —
    e.g. post-event follow-up — same as they already could exchange Notifications about one).
11. Message creation logic lives entirely in backend business services, never in a mobile
    client (matches Notification V1's own Business Rule 18).
12. Every message access is scoped to the authenticated caller's own identity/role and (for a
    Hotel Manager) their own Hotel, the same way every other own-Hotel/own-Booking endpoint
    in this codebase already is scoped.

### Notification Catalog Addition

One new row is added to this document's existing Notification Catalog (above), since sending
a message triggers a Notification exactly like every other row there:

| # | Recipient | Event | Triggering backend transition |
|---|---|---|---|
| C9 | Customer | New message from the Hotel Manager | `chat.service.js#sendMessage` (sender is the Hotel Manager) |
| M9 | Hotel Manager | New message from the Customer | `chat.service.js#sendMessage` (sender is the Customer) |

### Out of Scope for V1

- **Platform Administrator participation.** No Admin Web chat UI, no Manager-to-Administrator
  support channel — V1 is Customer↔Hotel Manager only, per the Recipients section above. A
  future Communication V2 could add this as its own, separately-scoped feature request.
- **Live/real-time delivery.** No WebSocket, no typing indicators, no read-while-open live
  update. A new message is delivered the same way a Notification already is — persisted,
  then a best-effort push — and the recipient sees it by opening the conversation (or via
  in-app refresh), not through a live socket connection. This keeps V1 on infrastructure this
  codebase already has (`ADR-0001`, Firebase Cloud Messaging) rather than introducing a new
  real-time transport.
- **Attachments/media** — text only (Business Rule 3).
- **Per-message read receipts / delivery ticks** — only whole-conversation read state
  (Business Rule 5).
- **Editing or deleting a sent message** (Business Rule 4).
- **Any conversation not tied to a Booking** (Business Rule 1) — a Customer cannot message a
  Hotel before booking, and a Manager cannot start a conversation unprompted by an existing
  Booking.
- **Staff-account participation** — Staff Management (Module 9) is not yet implemented,
  matching Notification V1's own equivalent exclusion.

### Acceptance Criteria

- AC-6: A Customer and the Hotel Manager of that Booking's Hotel can each send and receive
  text messages in that Booking's conversation.
- AC-7: A user outside a Booking's own Customer/Manager pair cannot read or send into that
  Booking's conversation (403/404, matching this codebase's existing cross-tenant
  convention).
- AC-8: Opening a Booking's conversation marks every message from the other participant
  read, reflected on the next fetch and in the unread-count badge.
- AC-9: Sending a message reliably produces exactly one persisted `NEW_CHAT_MESSAGE`
  Notification for the other participant (AC-1's guarantee extended to this new catalog row).
- AC-10: A push delivery failure for a chat Notification never prevents the message itself
  from existing or being readable (same guarantee as AC-4).

### Traceability (Communication V1)

| Concern | Owning Module |
|---|---|
| Booking identity/ownership, Hotel ownership | Booking Management (05) / Hotel Management (03) |
| Recipient identity/role | Authentication & Account Management (01) |
| Push delivery, Notification Catalog | Notification Management (this module, Notification V1 above) |
| Message persistence, read state | Communication Management (this module, this section) |
