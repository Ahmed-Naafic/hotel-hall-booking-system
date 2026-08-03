# Backend — Node.js + Express.js

The single Express.js API serving every application, organized as feature-based modules
(one per approved module: authentication, customers, hotels, halls, calendar, bookings,
payments, events, staff, notifications, reviews, reports, administration, security).

**Status:** Workspace initialized (`docs/02-architecture/adr/0004-workspace-initialization.md`).
Express, Prisma, and dev tooling are installed; the server boots with no routes registered.
No feature module, controller, service, repository, Prisma model, or business logic exists
yet.

## Local Development

```bash
cp .env.example .env   # fill in local values
npm install
npm run dev             # nodemon, auto-restart
npm start                # plain node
npm run lint
npm run format
npm test
```

## Prisma

```bash
npm run prisma:generate
npm run prisma:migrate   # not used until the first model is approved
```

`prisma/schema.prisma` is connected to PostgreSQL via `DATABASE_URL` — no models, no
migrations yet.

## Structure

```
backend/
├── src/
│   ├── index.js          Entry point — starts Express, no routes registered
│   └── config/
│       ├── env.js         Environment loading (dotenv)
│       └── logger.js      Logging placeholder (winston)
├── prisma/
│   └── schema.prisma      Datasource + generator only, no models
├── eslint.config.js
└── .prettierrc.json
```

`src/modules/` (one per approved module) is created only once that module's Business
Specification, Technical Design, and Implementation Plan are `Approved` and it reaches
`Development-Lifecycle.md` Phase 8 — see `docs/Team-Management.md` for current feature
status. Full structure: `docs/02-architecture/folder-structure.md` §4, §6.
