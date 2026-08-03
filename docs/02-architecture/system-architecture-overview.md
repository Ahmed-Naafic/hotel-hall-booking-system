---
title: "System Architecture Overview"
document_type: Architecture
status: Approved
version: 1.0
owner: Ahmed (Chief Solution Architect)
last_updated: 2026-08-03
---

# System Architecture Overview
## Hotel Hall Booking Management System

This is the master architecture document for the project. It defines the overall
architecture of the platform and how every major component interacts — the single source
of truth for the platform's technical architecture.

> **Relationship to other documents — this document is the map, not the territory:** it
> ties together documents already written in full detail and does not repeat them.
> `Architecture-Principles.md` — the non-negotiable principles every component below
> follows. `folder-structure.md` — how each component is organized on disk.
> `mobile-application-architecture.md` — the two Flutter apps in full detail.
> `data-architecture.md` — business data domains and entities. `database-standards.md` —
> physical schema. `api-standards.md` — the REST contract connecting everything.
> `security-architecture.md` (once authored) — the full security model, summarized only in
> §10 here. Where this document and one of those disagree, the more detailed document
> governs and this one is corrected.

---

## 1. Purpose

Every other architecture document describes one part of the system in depth. This document
is the one place that shows how those parts fit together — what talks to what, in what
order, and why. It exists because a Technical Design for any single module still needs to
understand the whole platform it's joining, and no developer or AI session should have to
reconstruct that picture by reading eight other documents and inferring the connections.

---

## 2. Architectural Vision

The platform-level restatement of `Architecture-Principles.md` §2 — not redefined here,
only named for reference: **Modular** (§6), **Feature-based** (`folder-structure.md`),
**Documentation-first** (`Project-Constitution.md` §5), **API-first** (§9), **Multi-tenant**
(§11), **Scalable** (§13), **Secure** (§10), **Maintainable**, and **AI-friendly** — a
system whose structure an AI session can navigate from documentation alone, without needing
tribal knowledge.

---

## 3. High-Level System Overview

```
   Customer            Hotel Manager
      │                      │
      ▼                      ▼
 Customer Mobile        Manager Mobile        Platform Admin
   (Flutter)               (Flutter)          (React + Vite, BDR-007)
      │                      │                      │
      └──────────────────────┼──────────────────────┘
                              ▼
                     REST API (api-standards.md)
                              │
                              ▼
                     Express Backend
                  (feature-based modules, §6)
                              │
                              ▼
                       Prisma ORM
                              │
                              ▼
                        PostgreSQL
                              │
              ┌───────────────┴───────────────┐
              ▼                                ▼
         Cloudinary                    Firebase Cloud Messaging
        (storage, §8)                    (notifications, §8)
```

Every client talks to one API; the API is the only path to the database; external services
sit beside the backend, never inside a client (§8).

---

## 4. Client Applications

Full detail on the two Flutter apps is `mobile-application-architecture.md` — not repeated.
Summary:

| App | Purpose | Detail |
|---|---|---|
| Customer Mobile App | Search, reserve, pay for Halls | `mobile-application-architecture.md` §3 |
| Hotel Manager Mobile App | Manage a Hotel's operations | `mobile-application-architecture.md` §3 |
| **Platform Admin Dashboard** | Hotel approval (`BDR-003`) and cross-tenant Platform oversight | `folder-structure.md` §3 |

**Platform Admin Dashboard** — purpose: give a Platform Administrator the tools to review
and approve Hotels, and oversee the Platform as a whole. Primary users: Platform
Administrators only. Responsibilities: Hotel approval workflow, cross-tenant visibility,
platform-wide reporting access. Major features: Hotel approval queue, platform analytics,
administrative user management — each defined in full once Administration & Platform
Management's Business Specification is authored (Wave 7, `Development-Roadmap.md` §4).

---

## 5. Backend Architecture

Layer responsibilities (routes/controllers/services/repositories/middleware) are
`coding-standards.md` §5; the module folder structure is `folder-structure.md` §4. Not
repeated here. What this section adds:

- **Express.js** is the single API process serving every client (§3).
- **Feature-based modules** — one module per approved business module (§6), each
  self-contained per `Architecture-Principles.md` §3.
- **Shared components** — cross-cutting middleware and genuinely shared utilities
  (`folder-structure.md` §5), never business logic.
- **Configuration** — environment-driven, secrets never committed
  (`naming-conventions.md` §10, `Project-Constitution.md` §8).
- **Middleware** — authentication, authorization, error handling, logging, all applied
  centrally (`coding-standards.md` §5, §9, §10).
- **Background processing** *(future)* — not required for MVP; the current architecture is
  entirely request/response (§9). Introduced (e.g. a job queue for scheduled Notification
  delivery or Hold expiry) once a real need is identified, tracked as a future ADR.

---

## 6. Core Business Modules

The fourteen approved modules (`Project-Overview.md` §6), each responsible for its own
domain (`data-architecture.md` §3, §9) — no implementation detail, purpose only:

| Module | Responsibility |
|---|---|
| Authentication | Identity, login, account lifecycle. |
| Customer | Customer profiles and history. |
| Hotel | Hotel (tenant) profile and management. |
| Hall | Bookable hall inventory. |
| Booking | The core reservation transaction. |
| Calendar | Shared availability underlying Bookings. |
| Payment | Payments, deposits, refunds. |
| Event | Event detail attached to a Booking. |
| Staff | Hotel employee accounts and assignment. |
| Notification | Messages to Customers, Hotel Managers, Staff. |
| Review | Customer feedback on completed Bookings. |
| Reporting | Derived, read-only operational and business insight. |
| Administration | Platform-wide oversight and Hotel approval. |
| Security | Cross-cutting access control, threading through every module above (`Architecture-Principles.md` §6) rather than owning a domain of its own. |

There is no Branch module — per `BDR-008` (`Approved`), one Hotel represents exactly one
physical location.

---

## 7. Data Architecture Overview

```
Business Data (data-architecture.md)
        ↓
Prisma (database-standards.md §3)
        ↓
PostgreSQL (database-standards.md)
```

Full detail is `data-architecture.md` (business domains, entities, relationships,
governance) and `database-standards.md` (physical schema) — not duplicated here.

---

## 8. External Integrations

| Integration | Role |
|---|---|
| **Cloudinary** | Default storage provider, behind a provider-agnostic abstraction (`Architecture-Principles.md` §10, `technology-stack.md`). |
| **Firebase Cloud Messaging** | Push notification delivery (`mobile-application-architecture.md` §11). |
| **Payment Gateway** | **Not yet selected** — `Project-Overview.md` §13 lists this as `TBD`; `BDR-004` approved the payment *policy*, not the provider. Introduced via a future ADR once chosen. |
| **Maps, Email, SMS** | **Not currently approved integrations.** No Business Specification or ADR has introduced them; they are not assumed into this architecture. If a future module requires one, it follows the same approval path as any other integration (`Decision-Making-Principles.md` §7). |

Every integration, approved or future, sits behind an abstraction the backend depends on —
never called directly from business logic (`Architecture-Principles.md` §11).

---

## 9. Communication Architecture

```
Flutter apps  →  REST API  →  Express  →  Database
Platform Admin  →  REST API  →  Backend  →  External Services
```

- **Synchronous** — the current and only communication mode. Every client request is a
  REST call (`api-standards.md`) that completes with a response; there is no message queue
  or event bus yet.
- **Asynchronous** *(future)* — not required for MVP. A future need (e.g. scheduled
  Notification delivery, §5's background processing) would introduce asynchronous
  communication via a defined mechanism, decided through an ADR — never informally bolted
  onto the synchronous request/response flow.

---

## 10. Security Architecture Overview

Full detail is `docs/02-architecture/security-architecture.md` (once authored) and
`Architecture-Principles.md` §7 — this is a summary, not a substitute:

- **JWT + Refresh Tokens** for authentication (`api-standards.md` §12).
- **RBAC** for authorization, enforced on every request (`api-standards.md` §13).
- **HTTPS** everywhere (`api-standards.md` §19).
- **Tenant isolation** — a Hotel's data is never visible to another Hotel
  (`data-architecture.md` §11).
- **Input validation** at the API boundary (`coding-standards.md` §11).
- **Audit logging** for business-significant actions (`database-standards.md` §8,
  `Project-Constitution.md` §8).
- **Secure storage** — secrets and tokens never in plain text
  (`mobile-application-architecture.md` §10, `Project-Constitution.md` §8).

---

## 11. Multi-Tenant Overview

```
Platform
    ↓
Hotels
    ↓
Halls
    ↓
Bookings
```

Full principles are `data-architecture.md` §11 and `Architecture-Principles.md` §6 — a
Hotel is the tenant boundary; there is no intermediate "Branch" layer between Platform and
Hotels, per `BDR-008`.

---

## 12. Deployment Overview

```
Flutter Apps, React Admin
        ↓
      Nginx (ADR-0002, reverse proxy)
        ↓
   Express API (Docker)
        ↓
    PostgreSQL
        ↓
Cloudinary, Firebase (external)
```

Nginx and Docker are approved (`technology-stack.md`, ADR-0001, ADR-0002). **Hosting/cloud
provider remains `TBD`** (`Project-Overview.md` §13) — this diagram shows the logical
deployment shape; the physical environment (which cloud, how scaled) is a future decision,
tracked there, not invented here.

---

## 13. Scalability Strategy

Full detail is `data-architecture.md` §17 and `Development-Roadmap.md` §2. This
architecture supports additional Hotels, Halls, features, and integrations without
restructuring — each addition follows the same feature-based pattern
(`Architecture-Principles.md` §3) already in place. A future web Customer portal,
international expansion (currency/language as Reference Data, `data-architecture.md` §8),
and — if genuinely ever required — a migration toward services split out of the current
single Express process, are all possible without changing this document's fundamental
shape, because module boundaries (§6) are already drawn as if they were separate services,
even while deployed as one.

---

## 14. Reliability & Availability

- **Error handling** — centralized, consistent (`coding-standards.md` §9).
- **Logging** — Winston (ADR-0002), per the levels defined in `coding-standards.md` §10.
- **Health checks** — a lightweight, unauthenticated endpoint reporting the API's basic
  availability; specific monitoring integration is a future infrastructure decision.
- **Recovery** — `database-standards.md` §17 (backups), pending the hosting decision.
- **Monitoring** — not yet selected; tracked as a future decision alongside hosting
  (`Project-Overview.md` §13).
- **Graceful failure** — every external integration (§8) fails predictably, never silently
  corrupting data (`Architecture-Principles.md` §11).

---

## 15. Architecture Decision Dependencies

This document assumes and depends on, without repeating: `Architecture-Principles.md`,
`technology-stack.md` (ADR-0001, ADR-0002), `business-decision-register.md`,
`coding-standards.md`, `api-standards.md`, `database-standards.md`,
`documentation-standards.md`, `folder-structure.md`, `naming-conventions.md`.

---

## 16. Architecture Diagrams

**System Context** — §3.
**Container-level** — §3 (client apps, API, database, external services as containers).
**Component-level** (backend) — §6's module list, each an internal component of the
Express container.
**Communication** — §9.
**Deployment** — §12.

Every diagram in this document uses the same component names as
`naming-conventions.md` and `technology-stack.md` — no diagram introduces a component name
not traceable to an approved document.

---

## 17. Future Evolution

Full detail is `data-architecture.md` §17 and `mobile-application-architecture.md` §18.
Platform-wide: additional client applications, additional integrations (§8), new business
modules (`Development-Roadmap.md` §9), additional countries (`data-architecture.md` §8),
additional payment providers (§8), and additional notification providers all extend this
architecture without requiring it to be redrawn — each is a new instance of a pattern
already established, not a new pattern.

---

## 18. AI Development Rules

This restates and is governed by `Project-Constitution.md` §4 and
`Architecture-Principles.md` §14 — see those for the canonical AI rules. Additions specific
to this document's scope:

- **AI must follow the approved System Architecture** — this document, as written.
- **AI must respect module boundaries** (§6) and never bypass architectural layers (§5).
- **AI must never introduce an undocumented component** — every box in §3/§16 traces to an
  approved document.
- **AI must reference existing architecture documents** rather than re-deriving them.

---

## 19. Architecture Review Checklist

- [ ] Alignment with `Architecture-Principles.md`.
- [ ] Feature-based compliance (`folder-structure.md`).
- [ ] Security compliance (§10).
- [ ] Multi-tenant compliance (§11).
- [ ] Scalability considered (§13).
- [ ] Maintainability considered.
- [ ] Documentation consistency — no component introduced here without a home elsewhere.
- [ ] Technology consistency — matches `technology-stack.md` exactly.
- [ ] Integration readiness (§8).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-03 | Ahmed | Initial approved System Architecture Overview |
