---
title: "Administration & Platform Management — Business Specification"
document_type: Business Specification
module: 13-administration-and-platform-management
status: Approved
owner: Product
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/03-hotel-management/business-specification.md"]
last_updated: 2026-09-07
---

## Scope

Administration & Platform Management V1 is limited to the Platform Administrator's review of Hotel applications: listing a Hotel's submitted applications and approving or rejecting them. Hotel Management remains the sole owner of Hotel data and the approval-status field itself; this module owns only the cross-tenant review workflow and interface. Platform-wide reporting, admin user management, and any other cross-tenant administrative tooling are outside V1.

## Approved Rules

- Only an authenticated Platform Administrator may list, approve, or reject a Hotel's applications.
- Listing and deciding an application first confirms the Hotel itself exists; a decision is recorded against a specific application, not the Hotel record directly.
- Approving an application requires no additional input; rejecting one requires a reason.
- The decision is attributed to the deciding Platform Administrator and timestamped.
- Administration & Platform Management does not duplicate or re-derive Hotel eligibility/visibility rules — those remain entirely Hotel Management's.
