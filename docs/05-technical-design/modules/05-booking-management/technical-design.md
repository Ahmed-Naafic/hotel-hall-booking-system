---
title: "Booking Management — Technical Design"
document_type: Technical Design
module: 05-booking-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/05-booking-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md"]
last_updated: 2026-09-16
---

## Architecture

Booking Management is a feature module under `backend/src/modules/bookings`. It consumes Hotel Management's existing ownership and eligibility query interfaces and Availability's period-free query interface. It does not duplicate tenant authorization or Hall visibility policy.

Hall owns nullable named commercial columns: rent amount in integer cents, fixed 24-hour duration, advance percentage, customer-service number, and payment-receiving number. Nullable rollout preserves legacy Hall rows; Booking creation requires complete terms.

Booking owns lifecycle and payment state, immutable price snapshots, payment deadline, report/verification metadata, cancellation metadata, and audit events. Amounts are integer USD cents. Times are absolute UTC instants.

## Consistency

Manual block writes and Booking writes acquire the same transaction-scoped PostgreSQL advisory lock for the Hall, then perform cross-table overlap checks. PostgreSQL GiST exclusion constraints independently prevent overlapping manual blocks and overlapping Pending/Confirmed Bookings. This closes both application races and same-table database races.

Expiration is lazy and transactional: reads, mutations, and availability checks transition overdue Pending non-Paid Bookings to Expired. No scheduler is required for V1.

## API

Customer routes live under `/api/v1/bookings`: create, list, retrieve, report payment, and cancel. Own-Hotel Manager routes live under `/api/v1/hotels/:hotelId/bookings`: list, retrieve, payment verification/rejection, confirmation, rejection, cancellation, completion, and no-show. All responses use the shared API envelope and cursor pagination.

`POST /bookings/:bookingId/cancellation` (Customer only) accepts an optional body `{ reason?: string }` (BDR-024). `booking.validation.js#validateCancelCustomer` only checks that `reason`, if present, is a string — whether one is actually *required* depends on the Booking's current status, so that check lives in `booking.service.js#cancelCustomer` (a `BusinessRuleError`, 422, if the Booking is `CONFIRMED` and no non-empty `reason` was given), the same input-shape-vs-state-dependent-rule split `validatePaymentDecision`/`verifyPayment` already use for payment-rejection's own `reason`. The value is persisted to `Booking.cancellationReason` (null unless supplied) and returned on every Booking read (`booking.mapper.js`), visible to both the Customer and the Hotel Manager. The Hotel Manager's own `POST /hotels/:hotelId/bookings/:bookingId/cancellation` is unchanged — this rule applies only to a Customer-initiated cancellation.

## Clients

Customer Mobile performs a final availability check and submits a Booking with event and guest details. Manager Mobile lists own-Hotel Bookings and exposes only actions valid for the visible lifecycle/payment state. No server credential is exposed to Flutter.
