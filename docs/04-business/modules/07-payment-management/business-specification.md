---
title: "Payment Management — Business Specification"
document_type: Business Specification
module: 07-payment-management
status: Approved
owner: Product
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/05-booking-management/business-specification.md"]
last_updated: 2026-09-07
---

## Scope

Payment Management V1 is a manual, off-platform reporting-and-verification workflow layered on the Booking record: a Customer reports having sent the advance by mobile-money/bank transfer to the Hall's published payment number, and the Booking's own-Hotel Manager verifies or rejects that report. No payment gateway, no in-app money movement, no automatic reconciliation, no refunds, and no invoicing exist in V1.

## Approved Rules

- A Hall publishes a payment-receiving number and a customer-service number as part of its commercial terms; a Booking snapshots the Hall's advance-payment percentage and the resulting required advance amount at creation time.
- A Customer may report a payment (an amount in USD) against their own Pending Booking whenever that Booking's payment status is Unpaid or Rejected. An already-active report cannot be duplicated or replaced while it is pending review.
- Reporting a payment moves the Booking's payment status to Customer-Reported and clears any prior rejection reason.
- Only the Booking's own-Hotel Manager may review an active Customer-Reported payment, and only while the Booking is still Pending.
- The Manager is shown the reported amount alongside the required advance amount. A reported amount below the required advance is surfaced to the Manager as a warning, never a hard system block — the Manager's own judgment, not the backend, is the final check on whether to accept a report.
- Verifying a report moves payment status to Paid and records who verified it and when. Rejecting it moves payment status to Rejected with a required reason; the Customer may then report again.
- A Booking cannot be confirmed until its payment status is Paid.
- A Paid Booking's payment status can never be reset or rejected by a later report or verification action.
