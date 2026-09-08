---
title: "Customer Management — Implementation Plan"
document_type: Implementation Planning
module: 02-customer-management
status: Partially Implemented
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/05-technical-design/modules/02-customer-management/technical-design.md"]
last_updated: 2026-09-08
---

## Delivered Work

1. Add the bare Customer profile record (existence + empty `profileData`) and its create/view/update endpoints.
2. Add the profile-field allow-list guard so no field can be stored before BDR-CUST-01/02 approves it.
3. Add the Favorites schema and save/unsave/list endpoints.
4. Build Customer Mobile's My Profile screen (existence + pending-approval messaging) and the Favorites bookmark toggle + Saved Hotels list.
5. **(2026-09-08, BDR-018)** Approve and deliver `fullName` as the first named `profileData` field. A `CUSTOMER` registration (`POST /api/v1/auth/register`) now requires it and creates the CustomerProfile automatically, atomically with the User Account (`authentication.service.js#register`, one `prisma.$transaction`). `customerProfilePolicy.js#allowedProfileFields` updated from `[]` to `['fullName']`, with real (non-empty, ≤200 char) validation. Customer Mobile's registration form gained a Full Name field (shared `RegisterForm`'s new `requireFullName` flag — Hotel Manager registration is unaffected); My Profile screen now shows the Full Name and lets a pre-`BDR-018` account (no profile, or a profile with no name) set one. Booking Management's `booking.mapper.js` now includes `customer: { id, fullName, mobileNumber }` on every Booking response, so Manager Mobile's Bookings screen can show who a Booking belongs to — the stated business problem `BDR-018` exists to solve.

## Remaining Scope (Blocked on Pending Business Decisions)

- Every Customer profile field beyond `fullName` — required or optional (BDR-CUST-01, BDR-CUST-02).
- Profile completion requirement and the resulting `isComplete`/`missingRequiredFields` computation (BDR-CUST-03) — unaffected by `BDR-018`, which only guarantees `fullName` exists going forward, not what "complete" means.
- Customer eligibility rules beyond authentication (BDR-CUST-04), if any prove necessary beyond what Booking Management already enforces.

## Rollout Note

No prior data required migration when this module was first built — both the Customer profile and Favorites schemas were new tables with no legacy rows to reconcile. `BDR-018` (2026-09-08) added no schema migration either — `fullName` reuses the pre-existing `profileData` JSON column — but it is not retroactive: a Customer account registered before this change may have no CustomerProfile, or one with no `fullName`. No existing row is backfilled with a fabricated name; a Hotel Manager simply sees no name for that Customer until the Customer sets one via My Profile.
