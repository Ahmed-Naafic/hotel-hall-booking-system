# Hotel Hall Booking Management System

An enterprise, commercial, multi-tenant platform for booking hotel halls (banquet, event,
and conference spaces): customers search, reserve, and pay for halls through a mobile app;
hotel managers manage halls, bookings, payments, staff, and events through a companion
mobile app; platform administrators onboard and oversee hotels through a web dashboard.

Built **documentation-first** and **AI-assisted**: no feature is implemented until it has
been specified, designed, planned, reviewed, and approved in writing.

**Start here:** [`docs/Project-Overview.md`](docs/Project-Overview.md) — every contributor,
human or AI, reads this before touching anything else. Then
[`docs/README.md`](docs/README.md) for the full documentation index.

---

## Architecture Summary

- **Feature-based modular architecture**, not layer-based — the backend, both Flutter apps,
  and the web app are each organized by feature/module, not by technical layer. See
  [`docs/02-architecture/folder-structure.md`](docs/02-architecture/folder-structure.md).
- **Multi-tenant at the hotel level** — many independent hotels share the platform with
  strictly isolated data. See
  [`docs/02-architecture/data-architecture.md`](docs/02-architecture/data-architecture.md)
  and
  [`docs/02-architecture/security-architecture.md`](docs/02-architecture/security-architecture.md).
- **Single GitLab monorepo** — the backend, both mobile apps, the admin web app, and shared
  code all live in one repository. See
  [`docs/03-standards/git-workflow-and-branching.md`](docs/03-standards/git-workflow-and-branching.md).
- Full architectural reasoning and principles:
  [`docs/02-architecture/architecture-principles.md`](docs/02-architecture/architecture-principles.md).

## Technology Stack

| Layer | Choice |
|---|---|
| Customer & Hotel Manager mobile apps | Flutter |
| Admin web (Platform Administrators only) | React + Vite |
| Backend / API | Node.js + Express.js |
| Database | PostgreSQL, via Prisma ORM |
| Authentication | JWT + Refresh Tokens, RBAC |
| File / media storage | Provider-agnostic abstraction; Cloudinary (default) |
| API style | REST, documented with OpenAPI (Swagger) |
| Push notifications | Firebase Cloud Messaging |
| Containerization | Docker |
| Reverse proxy | Nginx |
| Version control | GitLab |

Authoritative source: [`docs/02-architecture/technology-stack.md`](docs/02-architecture/technology-stack.md)
(ADR-0001, ADR-0002). Any change to this stack requires a new ADR before it may be relied
upon — see [`docs/02-architecture/adr/`](docs/02-architecture/adr/).

## Repository Structure

```
/
├── apps/
│   ├── customer-mobile/     Flutter — Customer app
│   ├── manager-mobile/      Flutter — Hotel Manager app
│   └── admin-web/           React + Vite — Platform Administration dashboard
├── backend/                 Node.js + Express.js API — feature-based modules
├── shared/                  Code genuinely reusable across apps and/or backend
├── docker/                  Containerization: Dockerfiles, compose files
├── scripts/                 Repo- and environment-level scripts
├── docs/                    Full project documentation (see below)
└── README.md
```

Full definition, module list, naming, and ownership rules:
[`docs/02-architecture/folder-structure.md`](docs/02-architecture/folder-structure.md).
Per [`ADR-0003`](docs/02-architecture/adr/0003-repository-initialization-scaffolding.md),
this top-level skeleton exists now; each application's and the backend's actual code is
created only once its module reaches Phase 8 of the development lifecycle (below).

## Development Methodology

```
Business First → Architecture → Quality → Implementation
```

Every one of the 14 approved modules follows the same sequence, and no stage begins before
the previous one is `Approved`:

```
Business Specification → Technical Design → Implementation Plan →
Approval → Implementation → Validation
```

Full detail: [`docs/Development-Lifecycle.md`](docs/Development-Lifecycle.md) (the 13-phase
process), [`docs/Team-Management.md`](docs/Team-Management.md) (roles, Round-Robin
assignment, review rules), and
[`docs/Development-Roadmap.md`](docs/Development-Roadmap.md) (sequencing and milestones).

## Documentation-First Workflow

No feature is implemented without approved documentation. For any module:

1. **Business Specification** (`docs/04-business/modules/<module>/`) — business rules, user
   scenarios, acceptance criteria. Authored by Ahmed; reviewed by Mohamed or Abukar.
2. **Technical Design** (`docs/05-technical-design/modules/<module>/`) — data model, API
   contracts, module boundaries, conforming to `docs/02-architecture/` and
   `docs/03-standards/`.
3. **Implementation Plan** (`docs/06-implementation-planning/modules/<module>/`) — sequenced
   build plan, cross-module dependencies.
4. **Implementation** — assigned via Round Robin (Ahmed → Mohamed → Abukar → ...) only after
   all three documents above are `Approved`.
5. **Validation Report** (`docs/07-validation-and-qa/modules/<module>/`) — tested and
   reviewed against the module's own acceptance criteria before it's marked
   `Feature Accepted`.

Full documentation architecture, ownership, and dependency chain:
[`docs/00-governance/documentation-architecture.md`](docs/00-governance/documentation-architecture.md).
Full navigation index: [`docs/README.md`](docs/README.md) and
[`docs/Documentation-Map.md`](docs/Documentation-Map.md).

## Getting Started

The project is currently in the documentation phase (`docs/Project-Overview.md` §21–§22) —
no application code exists yet. This section will be populated with real setup instructions
(prerequisites, environment configuration, running the backend and each app locally) once the
first module (`01-authentication-and-account-management`) reaches
`Development-Lifecycle.md` Phase 8.

In the meantime:

```bash
git clone <repository-url>
cd hotel-hall-booking-system
cp .env.example .env   # fill in local values; never commit .env
```

## Contribution Workflow

- **Branching:** `main` (released) and `develop` (integration) are protected; all work
  happens on `feature/<module>-<description>`, `bugfix/<issue>`, or `hotfix/<issue>`
  branches per
  [`docs/03-standards/git-workflow-and-branching.md`](docs/03-standards/git-workflow-and-branching.md)
  and
  [`docs/03-standards/naming-conventions.md`](docs/03-standards/naming-conventions.md) §11.
- **No self-review, ever** — every Merge Request is reviewed by someone other than its
  author, per [`docs/Team-Management.md`](docs/Team-Management.md) §5.
- **Commits** follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`, `style:`).
- Full contributor guide: [`CONTRIBUTING.md`](CONTRIBUTING.md).
- Code and review ownership: [`CODEOWNERS`](CODEOWNERS).

## License

Proprietary — All Rights Reserved. See [`LICENSE`](LICENSE).
