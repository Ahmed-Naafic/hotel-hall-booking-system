---
title: "Decision Log (ADR Index)"
document_type: Governance
status: Approved
version: 1.7
owner: Ahmed
last_updated: 2026-08-27
---

# Decision Log
## Hotel Hall Booking Management System

Chronological index of every Architecture Decision Record (ADR). Full detail lives in each
ADR itself, under `docs/02-architecture/adr/`; this is the single place to see what
architectural decisions exist, when, and their current status. See
`Decision-Making-Principles.md` §7 for when an ADR is required.

| ID | Title | Status | Date | Amends |
|---|---|---|---|---|
| ADR-0001 | Initial Technology Stack | Approved | 2026-08-02 | `docs/02-architecture/technology-stack.md` |
| ADR-0002 | Infrastructure Additions — Reverse Proxy and Logging | Approved | 2026-08-03 | `docs/02-architecture/technology-stack.md` |
| ADR-0003 | Repository Initialization Scaffolding | Approved | 2026-08-03 | `docs/02-architecture/folder-structure.md`, `docs/Project-Overview.md` |
| ADR-0004 | Workspace Initialization | Approved | 2026-08-03 | `docs/Project-Overview.md` |
| ADR-0005 | SMS Delivery Provider for Identity Verification & Password Reset (Twilio) | Approved | 2026-08-03 | `docs/02-architecture/system-architecture-overview.md`, `docs/02-architecture/technology-stack.md` |
| ADR-0006 | Hotel Media Storage Provider (Supabase) | Approved | 2026-08-26 | `docs/02-architecture/technology-stack.md`, `docs/02-architecture/system-architecture-overview.md`, `docs/02-architecture/architecture-principles.md` |
| ADR-0007 | Shared Media Infrastructure (Hotel + Hall) | Proposed | — | `docs/02-architecture/technology-stack.md`, `docs/02-architecture/system-architecture-overview.md`, `docs/02-architecture/architecture-principles.md` |

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial log; indexes ADR-0001 |
| 1.1 | 2026-08-03 | Ahmed | Indexes ADR-0002 |
| 1.2 | 2026-08-03 | Ahmed | Indexes ADR-0003 |
| 1.3 | 2026-08-03 | Ahmed | Indexes ADR-0004 |
| 1.6 | 2026-08-26 | Ahmed | Indexes ADR-0006 (`Approved`, Supabase selected for Hotel media storage) |
| 1.7 | 2026-08-27 | Prepared by AI assistant, per Ahmed's explicit instruction | Indexes ADR-0007 (`Proposed`, not yet `Approved` — unified Hotel + Hall shared media infrastructure) |
| 1.5 | 2026-08-03 | Ahmed | ADR-0005 status updated `Proposed` → `Approved` (Twilio selected) |
| 1.4 | 2026-08-03 | Ahmed | Indexes ADR-0005 (`Proposed`, not yet `Approved`) |
