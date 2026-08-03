---
title: "ADR-0003: Repository Initialization Scaffolding"
document_type: Architecture Decision Record
status: Approved
last_updated: 2026-08-03
---

# ADR-0003: Repository Initialization Scaffolding

**Status:** Approved
**Date:** 2026-08-03
**Owner:** Ahmed (per `Decision-Making-Principles.md` §4, every ADR is approved by Ahmed)

## Context

`folder-structure.md` and `Project-Overview.md` §14/§21 originally stated that **no code
directories exist yet**, and that every folder in the approved repository layout (`apps/*`,
`backend/`, `shared/`, `docker/`, `scripts/`) is created only when the corresponding module
reaches `Development-Lifecycle.md` Phase 8 (Implementation) for the first time.

Repository initialization (establishing the GitLab monorepo's professional foundation —
root configuration, GitLab standards, and the top-level directory skeleton so the approved
`folder-structure.md` layout is visible and navigable) is itself a task the project needs to
do now, in Phase 0, before any module's Business Specification is even authored. Under the
original wording, that task would have nothing to create beyond `docs/` and root files —
`apps/`, `backend/`, `shared/`, `docker/`, and `scripts/` would not exist, leaving the
repository without the structure `folder-structure.md` describes as "official."

This meets the `Decision-Making-Principles.md` §7 ADR test: every future Technical Design
and Implementation Plan would otherwise have to independently decide whether it is
responsible for first creating its app's or module's top-level directory, or whether that is
a repository-initialization concern — the same question every module would hit identically.

## Options Considered

1. **Status quo — no top-level folders until each module's Phase 8.** Keeps the letter of
   the original rule, but leaves repository initialization with nothing to scaffold, and
   means the first module to reach Phase 8 is also implicitly responsible for creating
   sibling apps' folders it doesn't own (e.g. Authentication's Implementation Plan would be
   the first to touch `apps/customer-mobile/`, `apps/manager-mobile/`, and `apps/admin-web/`
   simultaneously, despite touching only the backend and mobile auth flows).
2. **Create the full approved layout, empty, at repository initialization; module and
   feature *subfolders* still wait for Phase 8.** The top-level skeleton
   (`apps/customer-mobile/`, `apps/manager-mobile/`, `apps/admin-web/`, `backend/`,
   `shared/`, `docker/`, `scripts/`) is created once, now, each containing only a short
   placeholder `README.md` stating the folder's purpose and that implementation begins at
   Phase 8 — no `lib/features/`, no `backend/src/modules/`, no dependency manifests, no
   application code. Every module's actual feature/module folder is still created only when
   that module reaches Phase 8, exactly as before.

## Decision

**Option 2.** The top-level repository skeleton defined in `folder-structure.md` §1 is
created now, as part of repository initialization, containing only placeholder `README.md`
files. This does not create any feature module, any application code, any dependency
manifest (`package.json`, `pubspec.yaml`), or any business logic — those still strictly
require the corresponding module's Business Specification, Technical Design, and
Implementation Plan to reach `Approved`, and still wait for that module's Phase 8, per
`Project-Constitution.md` §5.

## Consequences

- `folder-structure.md` and `Project-Overview.md` §14/§21 are updated to distinguish the
  **top-level skeleton** (created once, at repository initialization) from **module/feature
  subfolders** (still created only at each module's Phase 8) — the "no code yet" rule now
  means no *implementation* code, not no *directories*.
- Repository initialization has a concrete, bounded scope: root configuration, GitLab
  standards, and this empty top-level skeleton — never a feature module folder, a
  dependency manifest, or a line of application code.
- No future Implementation Plan is responsible for creating a sibling app's or the backend's
  top-level folder — only its own module/feature subfolder inside a skeleton that already
  exists.
- This does not change `folder-structure.md`'s actual layout, naming, or ownership rules —
  only *when* the top-level directories are created relative to the rest of the phased
  process.

## Related

- Amends: `docs/02-architecture/folder-structure.md`, `docs/Project-Overview.md` §14, §21
- Indexed in: `docs/00-governance/decision-log.md`
- Related BDR: none — a process/sequencing decision, not a business-scope question.
