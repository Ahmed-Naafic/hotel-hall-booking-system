---
title: "Reviews & Ratings Management — Technical Design"
document_type: Technical Design
module: 11-reviews-and-ratings-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/11-reviews-and-ratings-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md"]
last_updated: 2026-09-07
---

## Architecture

Reviews & Ratings Management is a feature module under `backend/src/modules/reviews`. Eligibility is read directly from the existing Booking relationship (a completed Booking the reviewing Customer owns) rather than a duplicate/parallel eligibility model — `review.service.js` calls into Booking Management's own repository (`findForCustomer`) instead of re-deriving ownership or status rules.

A Review record stores `bookingId` (unique), `customerUserId`, `hotelId`, `rating`, and optional `text`. `hotelId` is copied from the Booking at submission time so the Hotel's review list and aggregate never need to join through Booking for every read.

## Consistency

A `@@unique(bookingId)` database constraint is the authoritative guard against a duplicate review, not just the application's pre-check — a race between the eligibility check and the write is caught as a unique-violation (`P2002`) and mapped to the same 409 the pre-check itself raises.

## API

Customer route: `POST /api/v1/bookings/:bookingId/review` (`CUSTOMER`, own Booking only). Public routes live under `/api/v1/hotels/:hotelId/reviews`: `GET /` (cursor-paginated, newest first) and an aggregate summary (average rating rounded to one decimal, or `null` with a Hotel's review count as the source of the zero-state, never a synthetic `0` average) consumed by Hotel Detail.

## Clients

Customer Mobile's Booking Detail screen offers "Leave a Review" only once the Booking's own status is Completed and no review exists yet, submitting a star rating plus optional text. Hotel Detail renders the Hotel's average rating, review count, and the paginated review list using the same public endpoints a Visitor can reach unauthenticated.
