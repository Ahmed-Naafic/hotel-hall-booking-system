# Docker

Containerization assets: one Dockerfile per app/service, plus compose files for local
development. Stays at the repository root (not nested under `backend/`) since it builds more
than one app. Governed by `docs/02-architecture/folder-structure.md` §1, §6.

**Status:** Development configuration only, per
`docs/02-architecture/adr/0004-workspace-initialization.md` — not optimized for production.

- `backend.Dockerfile` — dev image for the backend workspace (bind-mounted source, runs
  `npm run dev`).
- The root `docker-compose.yml` runs `backend` and `postgres` for local development.
- `admin-web.Dockerfile` and `nginx.conf` are added once those workspaces need
  containerized deployment.

Usage: `cp .env.example .env` at the repository root, fill in local values, then
`docker compose up`.
