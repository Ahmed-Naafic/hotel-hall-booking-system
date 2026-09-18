---
title: "Calendar & Scheduling Management — Business Specification"
document_type: Business Specification
module: 06-calendar-and-scheduling-management
status: Approved
owner: Product
reviewer: Approved by stakeholder
depends_on: ["docs/Project-Overview.md", "docs/04-business/stakeholders-and-personas.md", "docs/04-business/business-decision-register.md", "docs/04-business/modules/04-hall-management/business-specification.md", "docs/04-business/modules/05-booking-management/business-specification.md"]
last_updated: 2026-09-07
---

## Scope

Calendar & Scheduling Management is the shared availability model for a single Hall: the Hotel Manager's manual blocks, and the busy periods a Customer sees before requesting a Booking. It prevents double-booking by giving Booking Management one authoritative overlap check, rather than each module deciding availability its own way. A visual month/week calendar UI, recurring blocks, and multi-Hall scheduling are outside V1.

## Approved Rules

- A manual availability block belongs to one Hall and marks a period unavailable independent of any Booking; it is defined by a Mogadishu calendar date plus start/end wall-clock times.
- Mogadishu is a fixed UTC+3 offset with no DST — every block and every Booking period is computed from that fixed offset, never the device's own timezone.
- An end time at or before its start time rolls the block to the next calendar day (an overnight block); an identical start/end time produces a full 24-hour block, never a zero-length one.
- A block must start in the future, both when created and when edited.
- Periods use `[start, end)` semantics — two periods that only touch at a boundary do not overlap.
- A block may not overlap another block, or a blocking Booking (non-expired Pending or Confirmed), for the same Hall.
- Only the Hall's own-Hotel Manager may view, create, edit, or delete that Hall's manual blocks.
- The public Customer surface exposes a Hall's busy periods (blocks and blocking Bookings merged) for one calendar day, and a yes/no availability check for a candidate period — never block or Booking detail beyond that.
- A Hidden Hall (its Hotel not currently eligible for Customer-facing operation) exposes no availability information.
