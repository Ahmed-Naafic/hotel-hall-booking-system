---
title: "Technology Stack"
document_type: Architecture
status: Approved
version: 1.2
owner: Ahmed
last_updated: 2026-08-02
---

# Technology Stack
## Hotel Hall Booking Management System

This document records the approved languages, frameworks, and services this project builds
on. It is the authoritative answer to "what do we build with" — a Technical Design does not
introduce a new technology choice; it works within what's approved here, or triggers an ADR
if a genuine change is needed (`Decision-Making-Principles.md` §7).

This initial stack is recorded in **ADR-0001** (`docs/02-architecture/adr/0001-initial-technology-stack.md`)
and indexed in `docs/00-governance/decision-log.md`.

---

## Approved Stack

| Layer | Choice |
|---|---|
| Mobile frontend | Flutter — both the Customer and Hotel Manager mobile applications |
| Web frontend | React + Vite — Platform Administration dashboard only (`BDR-007`) |
| Backend / API framework | Node.js + Express.js |
| Database | PostgreSQL |
| ORM | Prisma |
| Authentication | JWT + Refresh Tokens, with Role-Based Access Control (RBAC) |
| File / media storage | Provider-agnostic, behind an abstraction layer — Cloudinary is the default provider (see `Architecture-Principles.md` §10) |
| API style | REST, documented with OpenAPI (Swagger) |
| Containerization | Docker |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Version control | GitLab |
| Reverse proxy | Nginx (ADR-0002) |
| Logging | Winston (ADR-0002) |

---

## Web Frontend Scope — Resolved

`BDR-007` (`docs/04-business/business-decision-register.md`) is **`Approved`**: React + Vite
serves the **Platform Administration** web dashboard only (`Administration & Platform
Management`). Customers and Hotel Managers remain mobile-only (Flutter) — this is the one
approved exception to `Project-Overview.md` §7's mobile-application-first scope, and that
document has been updated to state it explicitly.

---

## Storage Provider Abstraction

Cloudinary is the **default** storage provider, not a fixed dependency. Per
`Architecture-Principles.md` §10, no business logic may depend on Cloudinary (or any
specific provider) directly — all storage access goes through a provider-agnostic
abstraction, so the provider can be replaced without touching business logic.

---

## Changing This Stack

Any addition, removal, or replacement in the table above is a **significant architectural
decision** per `Decision-Making-Principles.md` §7 and requires a new ADR, approved by Ahmed,
before a Technical Design may rely on the change.

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-02 | Ahmed | Initial approved technology stack, per ADR-0001 |
| 1.1 | 2026-08-02 | Ahmed | Web frontend scope resolved — `BDR-007` approved (Platform Administration dashboard only) |
| 1.2 | 2026-08-03 | Ahmed | Added Nginx (reverse proxy) and Winston (logging), per ADR-0002 |
