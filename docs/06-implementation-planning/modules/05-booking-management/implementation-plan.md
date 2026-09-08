---
title: "Booking Management — Implementation Plan"
document_type: Implementation Planning
module: 05-booking-management
status: Implemented
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/05-technical-design/modules/05-booking-management/technical-design.md"]
last_updated: 2026-09-08
---

## Delivered Work

1. Add Hall commercial terms and the Booking schema, enums, indexes, foreign keys, checks, and overlap exclusion migration.
2. Extend Availability with lazy expiration, blocking Booking queries, and a shared per-Hall transaction lock used by manual blocks and Bookings.
3. Implement Customer and own-Hotel Manager Booking APIs with validation, mapping, repository isolation, lifecycle rules, payment rules, pagination, and audit events.
4. Publish the Booking and Hall commercial contracts in OpenAPI.
5. Replace Customer Mobile's availability placeholder with real Booking submission.
6. Replace Manager Mobile's Booking placeholder with an own-Hotel booking queue and lifecycle actions.
7. Add pricing, lifecycle, payment, overlap, expiration, Flutter flow, regression, lint, OpenAPI, and migration verification.
8. Add an explicit post-Booking confirmation step on Customer Mobile ("I'll pay later" / "Report Payment Sent") so a successful Booking is never silently acknowledged.
9. Add cross-screen refresh so a new Booking's effects (My Bookings, Booking Detail, the Manager's Bookings queue, Hall Availability, and Popular Hotels ranking) are visible without an app restart or manual reload, using per-screen fresh-fetch-on-return and stale-flag invalidation rather than polling.
10. **(2026-09-08, BDR-018, Customer Management)** Add a `customer: { id, fullName, mobileNumber }` object to every Booking response (`booking.repository.js`'s shared `includeDetails` now joins `customer.customerProfile`; `booking.mapper.js#toBooking` reads `fullName` from it) — a Hotel Manager viewing a Booking (list or detail; Manager Mobile has no separate detail screen) can now identify the Customer without a separate lookup. `fullName` is `null`, never fabricated, for a Customer registered before `BDR-018` with none on file. Manager Mobile's Bookings screen (`bookings_coming_soon_screen.dart`) updated to display it.

## Rollout Note

Existing Halls remain valid after migration. A legacy Hall cannot receive a Booking until its Manager completes the commercial terms in Edit Hall.
