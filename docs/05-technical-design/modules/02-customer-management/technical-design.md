---
title: "Customer Management — Technical Design"
document_type: Technical Design
module: 02-customer-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/02-customer-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md"]
last_updated: 2026-09-08
---

## Scope Note

This document covers only the V1 slice actually delivered: Customer profile (now including `fullName`, `BDR-018`), and Favorites. It does not attempt a technical design for the full aspirational scope in the business specification's §1–§24 — every field beyond `fullName` remains pending BDR-CUST-01/02/03 (other required/optional profile fields, completion requirement). Favorites is documented here because it is a Customer Management concern (§25 of the business specification), even though it was not part of that document's original §3.1 scope.

## Architecture

Customer profile: `backend/src/modules/customers`. `profileData` is a JSON column with an explicit allow-list (`customerProfilePolicy.js#allowedProfileFields`) — currently `['fullName']` (`BDR-018`); any other field submitted before BDR-CUST-01/02 approves it is rejected by validation, not silently dropped or silently accepted. `getReadiness()` returns `isComplete`/`missingRequiredFields` as `null` rather than guessing, since BDR-CUST-03 has not defined what "complete" means yet — `fullName` being required at registration does not itself answer that separate question.

A `CUSTOMER` registration (`authentication.service.js#register`) creates the User Account and this CustomerProfile (with `fullName`) together, in one `prisma.$transaction` — Authentication (identity) and Customer Management (business profile) remain separately owned components, but the write is atomic: a Customer registered after `BDR-018` always has a profile, never a Customer with an identity but no name on file. An account registered before `BDR-018` may still have no profile, or a profile without `fullName`; `customer.mapper.js`/`booking.mapper.js` treat a missing name as `null`, never a fabricated placeholder.

Favorites: `backend/src/modules/favorites`, a separate module. A bookmark requires only that the Hotel currently exist at save time; once saved, it is never silently removed if the Hotel later becomes ineligible for ordinary browsing — the same precedent Booking History already follows for a Booking's Hotel.

## API

Customer profile: `GET /api/v1/customers/me`, `POST /api/v1/customers/me/profile`, `PATCH /api/v1/customers/me/profile` — all `CUSTOMER`, own account only. `profileData.fullName` is readable/writable through all three; `POST` now typically returns `409` for an account registered after `BDR-018` (a profile already exists) — it remains reachable for the pre-`BDR-018` case where one does not. Favorites: `GET /api/v1/favorites/hotels` (returns saved Hotel IDs, not full Hotel objects — the client cross-references against Hotel lists it has already fetched), `PUT /api/v1/favorites/hotels/:hotelId`, `DELETE /api/v1/favorites/hotels/:hotelId`.

Booking Management's own `GET /api/v1/bookings/:id`, `GET /api/v1/hotels/:hotelId/bookings[/:id]` responses include a `customer: { id, fullName, mobileNumber }` object (`booking.mapper.js`) — `fullName` sourced from this module's CustomerProfile, `mobileNumber` from Authentication's User Account — so a Hotel Manager viewing a Booking can identify the Customer without a separate lookup (`BDR-018`'s stated business problem). `fullName` is `null`, never fabricated, for a pre-`BDR-018` Customer with none on file.

## Clients

Customer Mobile's My Profile screen shows the Customer's Full Name when their profile has one, and a form to set it (via `POST` if no profile exists yet, `PATCH` otherwise) when it doesn't — the pre-`BDR-018` case. Discover and Hotel Detail show a bookmark toggle backed by an app-wide `FavoritesController`; Saved Hotels lists the Customer's bookmarked Hotels.

Manager Mobile's Bookings screen (`bookings_coming_soon_screen.dart` — the Manager's combined Booking list/detail view, no separate detail screen exists) shows the Customer's Full Name and Mobile Number on each Booking card when present, sourced from the same `customer` object.
