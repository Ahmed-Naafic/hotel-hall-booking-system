# Docker

Containerization assets: one Dockerfile per app/service, plus compose files for local
development. Stays at the repository root (not nested under `backend/`) since it builds more
than one app. Governed by `docs/02-architecture/folder-structure.md` §1, §6.

**Status:** Placeholder. No Dockerfiles exist here yet; the root `docker-compose.yml` is a
commented placeholder (see repository root).

This folder is reserved by the approved repository layout, created at repository
initialization per `docs/02-architecture/adr/0003-repository-initialization-scaffolding.md`.
Individual Dockerfiles (e.g. `backend.Dockerfile`) are added once the corresponding
application exists, per `Development-Lifecycle.md` Phase 8.
