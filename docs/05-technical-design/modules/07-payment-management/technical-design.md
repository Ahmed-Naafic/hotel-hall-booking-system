---
title: "Payment Management — Technical Design"
document_type: Technical Design
module: 07-payment-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/07-payment-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md"]
last_updated: 2026-09-07
---

## Architecture

There is no standalone `payments` backend module in V1 — Payment Management is a set of fields and state transitions owned entirely by `backend/src/modules/bookings`. Hall Management supplies the commercial terms (advance percentage, payment-receiving number, customer-service number) that Booking Management snapshots onto each Booking at creation; Payment Management never re-fetches or duplicates those fields afterward. This keeps a single authoritative owner for both the Booking lifecycle and the payment state attached to it, since the two are never independently valid (a payment always belongs to exactly one Booking).

## Data

Booking carries `paymentStatus` (`UNPAID` / `CUSTOMER_REPORTED` / `PAID` / `REJECTED`), `reportedAmountCents`, `paymentReportedAt`, `paymentVerifiedAt` / `paymentVerifiedById`, and `paymentRejectionReason`. Amounts are integer USD cents throughout, matching Booking Management's own pricing convention — no floating-point currency arithmetic anywhere in the path.

## Business Rule Note

The backend deliberately does not compare `reportedAmountCents` against `requiredAdvanceCents` as a hard gate on verification. The comparison is computed and returned to the Manager (Manager Mobile renders it as a warning before the Manager confirms), but the `verifyPayment` service function accepts a `VERIFY` decision regardless of the amount — ownership and status are the only two things the backend enforces on this transition. This was an explicit, approved relaxation of an earlier stricter rule that hard-rejected any under-amount verification; the amount judgment belongs to the Hotel Manager, not the platform.

## API

Customer route: `POST /api/v1/bookings/:bookingId/payment-report` (own Booking only, `CUSTOMER`). Own-Hotel Manager route: `POST /api/v1/hotels/:hotelId/bookings/:bookingId/payment-verification`, taking a `decision` of `VERIFY` or `REJECT` (`REJECT` requires a `reason`). Both live inside the existing Booking Management route files (`booking.routes.js`) rather than a separate router.

## Clients

Customer Mobile shows the Booking's payment terms after a successful Booking request and lets the Customer either defer ("I'll pay later") or report a sent amount immediately. Manager Mobile's Bookings queue shows the reported amount next to the required advance for any Customer-Reported Booking, and exposes Verify/Reject actions with an in-progress spinner and, when the reported amount is short, a client-side confirmation dialog before the Manager can proceed with Verify.
