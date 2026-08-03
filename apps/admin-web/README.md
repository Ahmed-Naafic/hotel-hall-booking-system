# Admin Web — React + Vite

React + Vite web dashboard for **Platform Administrators**: onboard hotels, oversee platform
health, handle escalations (`Administration & Platform Management`, confirmed in-scope by
`BDR-007`, `docs/04-business/business-decision-register.md`). Not available to Customers or
Hotel Managers — both remain mobile-only.

**Status:** Workspace initialized (`docs/02-architecture/adr/0004-workspace-initialization.md`).
React + Vite are installed with a minimal placeholder entry component. No feature, page, or
component beyond the bootstrap `App.jsx` exists yet.

## Local Development

```bash
npm install
npm run dev        # Vite dev server
npm run build
npm run lint
npm run format
```

## Structure

```
apps/admin-web/
├── src/
│   ├── main.jsx      Entry point
│   ├── App.jsx        Placeholder root component
│   └── assets/
├── public/
├── eslint.config.js
└── .prettierrc.json
```

`src/features/`, `src/core/`, `src/shared/` are created only once the Administration &
Platform Management module's Business Specification, Technical Design, and Implementation
Plan are `Approved` and it reaches `Development-Lifecycle.md` Phase 8 — see
`docs/Team-Management.md` for current feature status. Full structure:
`docs/02-architecture/folder-structure.md` §3.
