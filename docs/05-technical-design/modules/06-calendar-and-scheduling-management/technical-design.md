---
title: "Calendar & Scheduling Management — Technical Design"
document_type: Technical Design
module: 06-calendar-and-scheduling-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/06-calendar-and-scheduling-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md"]
last_updated: 2026-09-07
---

## Architecture

Calendar & Scheduling Management is a feature module under `backend/src/modules/availability`. It reuses Hall Management's own-Hotel ownership check and Hall visibility component unmodified — it never re-implements tenant authorization or Hall visibility policy. Availability owns only the manual-block table and the Availability Query Interface (`assertPeriodIsFree`/`isPeriodFree`); Booking Management calls into that interface rather than duplicating overlap logic itself.

A pair of pure functions (`mogadishuDayToUtcRange`, `combineBlockPeriod`) centralize the fixed +03:00 conversion in one place, so no caller — backend or Flutter — performs its own timezone math.

## Consistency

Manual block writes and Booking writes acquire the same transaction-scoped PostgreSQL advisory lock for the Hall (`hallScheduleLock.js`), then perform cross-table overlap checks. A PostgreSQL GiST exclusion constraint independently prevents overlapping manual blocks and overlapping blocking Bookings, closing both an application race and a same-table database race; a caught exclusion violation (Prisma `P2039` / Postgres `23P01`) is mapped to the same 409 the pre-check itself raises.

Expiration is lazy: every read or write path that touches availability first expires overdue, still-unpaid Pending Bookings, so a block creation or an availability check never sees a stale blocking Booking. No scheduler exists or is required for V1.

## API

Own-Hotel Manager routes live under `/api/v1/hotels/:hotelId/halls/:hallId/availability/blocks`: list a day's blocks, create, update, and delete — `HOTEL_MANAGER` only, ownership enforced by the parent Hall route. The public Customer surface is flat, under `/api/v1/halls/:hallId/availability`: `GET /` returns a day's merged busy periods (unauthenticated), `POST /check` returns a yes/no for a candidate period (`CUSTOMER` only).

## Clients

Manager Mobile's Hall Availability screen lists a day's blocks and creates/edits/deletes them, sending plain `date`/`startTime`/`endTime` wall-clock strings exactly as picked — the +03:00 conversion to an absolute instant is entirely the backend's job. Customer Mobile's Book Hall screen shows the selected day's busy periods and performs a final availability check immediately before Booking submission.
