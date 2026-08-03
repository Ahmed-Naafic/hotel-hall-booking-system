# Contributing

## Read This First

This project is **documentation-first**. Before touching any code, read
[`docs/Project-Overview.md`](docs/Project-Overview.md), then
[`docs/Project-Constitution.md`](docs/Project-Constitution.md). If you are an AI assistant,
also read [`docs/01-ai-governance/ai-governance.md`](docs/01-ai-governance/ai-governance.md).

**No feature is implemented without an `Approved` Business Specification, Technical Design,
and Implementation Plan** for its module — no exceptions, per `Project-Constitution.md` §5.

## Before You Start

1. Find your assigned feature in the Feature Assignment Register
   ([`docs/Team-Management.md`](docs/Team-Management.md) §7) — implementation is assigned by
   Round Robin (Ahmed → Mohamed → Abukar → ...) only after a feature reaches
   `Ready for Development`.
2. Read that module's approved Business Specification, Technical Design, and Implementation
   Plan in full.
3. Read the relevant standards in [`docs/03-standards/`](docs/03-standards/) — at minimum
   `coding-standards.md`, `naming-conventions.md`, and `testing-standards.md`.

## Branching & Commits

Full workflow: [`docs/03-standards/git-workflow-and-branching.md`](docs/03-standards/git-workflow-and-branching.md).
Naming format: [`docs/03-standards/naming-conventions.md`](docs/03-standards/naming-conventions.md) §11.

- Branch from `develop`: `feature/<module>-<short-description>`, `bugfix/<issue>`, or
  `hotfix/<issue>` (from `main`).
- Commits use [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`, `style:`.
- Never commit directly to `main` or `develop` — both are protected; every change goes
  through a reviewed Merge Request.

## Opening a Merge Request

Use the default MR template (`.gitlab/merge_request_templates/Default.md`). Every MR states
its purpose, the related feature and documentation, the related issue, a testing summary,
and the relevant standards checklist.

**No self-review, ever.** Ahmed reviews Mohamed's and Abukar's work; Mohamed or Abukar
reviews Ahmed's (`docs/Team-Management.md` §5). A Merge Request cannot merge without the
required approval.

## Documentation Changes

Documentation changes follow the same workflow as code — a branch, a Merge Request, a
review. Never edit a file in `docs/` directly on `develop` or `main`. Ownership rules:
[`docs/Team-Management.md`](docs/Team-Management.md) §9.

## Questions

Escalation path for anything unresolved at the working level:
[`docs/Team-Management.md`](docs/Team-Management.md) §11.
