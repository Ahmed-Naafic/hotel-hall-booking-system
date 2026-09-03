---
title: "Booking Management — Business Specification"
document_type: Business Specification
module: 05-booking-management
status: Approved
owner: Product
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md"]
last_updated: 2026-09-03
---

## Scope

Booking Management lets a verified Customer request a future period for an eligible Hotel's Hall and lets that Hotel's Manager administer payment verification and the Booking lifecycle. Payment gateways, refunds, notifications, discounts, reviews, Customer media, and Administrator booking powers are outside V1.

## Approved Rules

- A Booking contains its Customer, Hotel, Hall, start/end instants, guest count, Event Type, and optional special request.
- Event Types are Wedding, Conference, Birthday, Meeting, Graduation, and Other.
- A Booking must start in the future and may not overlap a manual Hall block or another blocking Booking.
- Non-expired Pending and Confirmed Bookings block availability. Periods use `[start, end)` semantics.
- Hall rent is denominated in USD per fixed 24-hour unit. Chargeable units are `ceil(duration / 24 hours)`; therefore 25 hours at $500 per 24 hours costs $1,000.
- The Hall defines an advance-payment percentage, customer-service number, and payment-receiving number. A Booking snapshots its calculated total and required advance.
- A Customer reports payment; only the own-Hotel Manager verifies it as Paid. An insufficient report is rejected. A rejected report may be resubmitted, while an active report may not be duplicated or replaced.
- Pending unpaid or customer-reported Bookings expire 24 hours after creation. Pending Paid Bookings do not expire.
- Statuses are Pending, Confirmed, Rejected, Cancelled, Completed, No-show, and Expired.
- Cancellation is allowed only while Pending and not Paid, by the owning Customer or own-Hotel Manager. Paid Bookings cannot be cancelled.
- A Confirmed Booking may become Completed after `endsAt`, or No-show after `startsAt`.
- Cross-tenant and cross-owner access is reported as Not Found.
