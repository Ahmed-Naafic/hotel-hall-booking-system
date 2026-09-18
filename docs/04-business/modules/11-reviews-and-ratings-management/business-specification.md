---
title: "Reviews & Ratings Management — Business Specification"
document_type: Business Specification
module: 11-reviews-and-ratings-management
status: Approved
owner: Product
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/05-booking-management/business-specification.md", "docs/04-business/modules/02-customer-management/business-specification.md"]
last_updated: 2026-09-07
---

## Scope

Reviews & Ratings Management V1 lets a Customer leave one rating and an optional written review for a Hotel, tied to a Booking of theirs that actually completed. It surfaces an average rating and review count, and the review list, on the Hotel's own public detail page. Hall-level reviews, Hotel/Manager responses to a review, photo attachments, moderation/reporting, and edit/delete of a submitted review are outside V1.

## Approved Rules

- A review may only be submitted against a Booking the reviewing Customer owns, and only once that Booking's status is Completed.
- A Booking may be reviewed at most once; a second attempt against the same Booking is rejected, enforced by a database uniqueness constraint as well as an application check.
- A rating is a required integer from 1 to 5; written text is optional.
- The backend is the sole authority on review eligibility — the Customer Mobile client never independently decides whether a Booking may be reviewed.
- A review belongs to the Hotel the reviewed Booking was made against, not to the Hall.
- A Hotel's public review list and its average rating/count are visible to any Visitor or Customer viewing that Hotel's detail page, in newest-first order.
- A Hotel with zero reviews shows no average rating (never a synthetic zero).
