# Documentation — Hotel Hall Booking Management System

This is the documentation root for an enterprise-grade, AI-assisted, documentation-first
build of the Hotel Hall Booking Management System.

**Governing document:** [`Project-Constitution.md`](Project-Constitution.md) is the
project's highest authority — the non-negotiable, long-lived rules of how the project is
built. It takes precedence over every other document here.

**Start here day to day:** [`Project-Overview.md`](Project-Overview.md) is the first
document every developer and AI assistant must read — vision, mission, scope, team,
philosophy, and current status.

**Then use** [`Documentation-Map.md`](Documentation-Map.md) — the navigation guide. It tells
you exactly which documents to read for whatever task you're about to do (implementing a
feature, reviewing code, fixing a bug, etc.), for both humans and AI assistants.

**Team, workflow, and feature tracking:** [`Team-Management.md`](Team-Management.md) — team
roles, Round-Robin assignment, review rules, and the live Feature Assignment Register (who's
building what, and its status).

**The process itself:** [`Development-Lifecycle.md`](Development-Lifecycle.md) — the
mandatory 13-phase sequence (Feature Request → ... → Maintenance) every feature must follow,
with entry/exit criteria, reviewers, and what happens when a phase fails.

**The plan:** [`Development-Roadmap.md`](Development-Roadmap.md) — what gets built, in what
order, why, what depends on what, and how the plan progresses.

**How decisions get made:** [`Decision-Making-Principles.md`](Decision-Making-Principles.md)
— categories, authority, the standard decision process, evaluation criteria, and conflict
resolution.

**The official dictionary:** [`Project-Glossary.md`](Project-Glossary.md) — one official
meaning per business, technical, and project term. If a document uses a term, this is what
it means.

For the detailed design of the documentation system itself — what every folder and document
type is for, who owns it, and what depends on it — see
[`00-governance/documentation-architecture.md`](00-governance/documentation-architecture.md).

## Layout

| Folder | Contents |
|---|---|
| [`00-governance/`](00-governance/) | Ready/done gates, change management, ADR decision log |
| [`01-ai-governance/`](01-ai-governance/) | Rules and checklists governing AI-assisted work on this project |
| [`02-architecture/`](02-architecture/) | System-wide architecture, incl. `adr/` for Architecture Decision Records |
| [`03-standards/`](03-standards/) | Coding, naming, API, testing, git, documentation, UI/UX & accessibility, security-coding standards |
| [`04-business/`](04-business/) | Stakeholders/personas, business decision register, per-module Business Specifications |
| [`05-technical-design/`](05-technical-design/) | Per-module Technical Design documents |
| [`06-implementation-planning/`](06-implementation-planning/) | Per-module Implementation Plans |
| [`07-validation-and-qa/`](07-validation-and-qa/) | Test strategy, review checklists, per-module Validation Reports |
| [`08-templates/`](08-templates/) | Blank templates for the four per-module document types |

There is no `09-releases/` folder yet — it's added when the project nears its first release,
not before. See `docs/00-governance/documentation-architecture.md` §16 for the full list of
documents that were merged or removed from the original draft, and why.

## The 14 major features

Each has an identically-named slug folder under `04-business/modules/`,
`05-technical-design/modules/`, `06-implementation-planning/modules/`, and
`07-validation-and-qa/modules/`:

1. Authentication & Account Management
2. Customer Management
3. Hotel Management
4. Hall Management
5. Booking Management
6. Calendar & Scheduling Management
7. Payment Management
8. Event Management
9. Staff Management
10. Communication & Notification Management
11. Reviews & Ratings Management
12. Reports & Analytics
13. Administration & Platform Management
14. Security & Access Control

## Status

All per-module documents are currently `Not Started` placeholders. See
[`Team-Management.md`](Team-Management.md) §7 for live per-feature status.

## Non-negotiable rules

- No feature is implemented without an **Approved** Business Specification, Technical
  Design, and Implementation Plan (in that order).
- AI never invents business rules, changes architecture without approval, or skips a
  documentation step.
- No developer reviews their own implementation.
