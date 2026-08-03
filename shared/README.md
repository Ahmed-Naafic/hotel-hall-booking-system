# Shared

Code genuinely reusable across two or more applications and/or the backend — never a
catch-all. Governed by `docs/02-architecture/folder-structure.md` §5: middleware,
generic utilities, cross-module constants, shared error types, cross-module validators, and
shared services, each admitted only once it has two or more real, current consumers.

**Status:** Placeholder. No shared code exists here yet.

This folder is reserved by the approved repository layout
(`docs/02-architecture/folder-structure.md` §1, §5), created at repository initialization
per `docs/02-architecture/adr/0003-repository-initialization-scaffolding.md`. Its contents
are added only when a genuine, two-or-more-consumer need is identified during implementation
of an approved module, per `Development-Lifecycle.md` Phase 8 — not created speculatively.
