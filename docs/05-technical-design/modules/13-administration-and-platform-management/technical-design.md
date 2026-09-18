---
title: "Administration & Platform Management — Technical Design"
document_type: Technical Design
module: 13-administration-and-platform-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/13-administration-and-platform-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md"]
last_updated: 2026-09-11
---

## Architecture

Administration & Platform Management is a thin feature module under `backend/src/modules/administration` — routes, a controller, and request validation only. It has no service, repository, or data model of its own: every operation calls directly into Hotel Management's existing `hotel.service.js`, `application.service.js` (`listApplicationsForHotel`, `recordDecision`), and `suspension.service.js` (`suspendHotel`, `deactivateHotel`, `reactivateHotel`). Hotel Management's `recordDecision`, `suspendHotel`, `deactivateHotel`, and `reactivateHotel` perform no role check themselves and are reachable only through this module's `PLATFORM_ADMINISTRATOR`-gated routes — the review/operational-control workflow and its authorization live in Module 13, while the Hotel/Application data and lifecycle transition each triggers stay owned entirely by Hotel Management. This mirrors Hall Management's own precedent of calling into another module's query interface rather than duplicating its data model.

## API

All routes under `/api/v1/admin`, `PLATFORM_ADMINISTRATOR` only: `GET /hotels/:hotelId/applications` (list), `POST /hotels/:hotelId/applications/:applicationId/approval`, `POST /hotels/:hotelId/applications/:applicationId/rejection` (body: `reason`), `POST /hotels/:hotelId/suspension`, `POST /hotels/:hotelId/deactivation`, and `POST /hotels/:hotelId/reactivation` (`BDR-012`, `BR-HOTEL-09`). Suspension and deactivation are only valid from `APPROVED_ACTIVE`; reactivation is only valid from `SUSPENDED` or `DEACTIVATED`, back to `APPROVED_ACTIVE`. Hotel Management's Lifecycle Component rejects any other starting status with `409` (`lifecycle.service.js`).

## Clients

Admin Web's Hotel Applications and Hotel Detail pages list a Hotel's applications and let a Platform Administrator approve or reject the open one, reusing the same public Hotel application shape (`toPublicApplication`) Hotel Management already exposes elsewhere. The Hotel Detail page also lets a Platform Administrator suspend, deactivate, or reactivate a Hotel — the Suspend/Deactivate actions show only when the Hotel is `APPROVED_ACTIVE`, and Reactivate only when it is `SUSPENDED` or `DEACTIVATED` — reusing the public Hotel shape (`toPublicHotel`).
