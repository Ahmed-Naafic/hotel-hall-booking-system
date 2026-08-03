---
title: "Git Workflow & Branching Strategy"
document_type: Standard
status: Approved
version: 1.0
owner: Ahmed (Lead DevOps Engineer / Software Development Process Architect)
last_updated: 2026-08-03
---

# Git Workflow & Branching Strategy
## Hotel Hall Booking Management System

This document defines the official Git and GitLab workflow for this project. **Every
developer and every AI assistant must follow this workflow.**

> **Relationship to other documents:** branch and commit *naming format* is fully governed
> by `naming-conventions.md` §11 — not repeated here. This document governs *process*: when
> a branch is created, what a Merge Request requires, who reviews it, and how work reaches
> `main`. The review *rule* (no self-review; Ahmed reviews unless he implemented) is
> `Team-Management.md` §5 and `Development-Lifecycle.md` Phase 9 — this document is that
> rule expressed in GitLab mechanics, not a restatement of the rule itself.

---

## 1. Purpose

Three engineers plus AI assistance commit to one repository, building fourteen (and
eventually more) feature modules. A standardized Git workflow exists so that:

- **Collaboration is predictable** — anyone can find a module's work in progress by its
  branch name alone.
- **Code review has somewhere to happen** — a Merge Request is the enforcement point for
  the no-self-review rule (`Team-Management.md` §5), not a formality after the fact.
- **Feature isolation holds** — one feature's in-progress work never destabilizes another's,
  matching the feature-based architecture itself (`Architecture-Principles.md` §3).
- **Releases are safe and traceable** — what's in `main` at any point is always known,
  tested, and traceable back to approved documentation.

---

## 2. Repository Strategy

- **Single GitLab monorepo.** The backend, both Flutter apps, the Admin Web app, and
  `shared/` all live in one repository, matching `folder-structure.md` §1.
- **Why a monorepo:** the project is feature-based across every layer
  (`folder-structure.md`) — a single feature (e.g. Booking Management) touches the backend,
  possibly both mobile apps, and its own tests together. A monorepo lets one Merge Request
  represent one feature's complete, reviewable change, instead of coordinating matching
  changes across separate repositories with separate review cycles. For a three-person
  team, that coordination overhead is a cost with no offsetting benefit.
- **Repository ownership:** Ahmed owns repository-level settings (branch protection,
  CI/CD configuration, access control) as Project Lead (`Team-Management.md` §1).
- **Branch protection:** `main` and `develop` (§3) are protected — no direct push from
  anyone, including Ahmed; every change reaches them through a reviewed Merge Request (§5).
- **Default branch:** `develop` — this is what a fresh clone checks out and what feature
  branches are created from (§3), keeping `main` reserved for released, production-ready
  code only.

---

## 3. Branching Strategy

| Branch | Purpose |
|---|---|
| `main` | Always reflects what's actually released. Protected; only updated via a release (§10) or hotfix (§11). |
| `develop` | Integration branch — where completed, reviewed features accumulate between releases. Protected; only updated via Merge Request. |
| `feature/<module>-<short-description>` | One feature's implementation, per `naming-conventions.md` §11. Branched from `develop`; merged back into `develop`. |
| `bugfix/<issue>` | A non-urgent fix to something already in `develop` (not yet released). Branched from and merged back into `develop`. |
| `hotfix/<issue>` | An urgent fix to something already in `main` (already released). Branched from `main`; merged into both `main` and `develop` (§11). |
| `release/<version>` | Stabilizes a set of completed features from `develop` before they reach `main` (§10). |

This is deliberately a simplified structure, not full GitFlow — there is no
`support/`, no long-lived per-environment branch beyond `main`/`develop`, and no branch
type without a stated purpose above. It stays this small specifically because it needs to
remain workable for three people.

---

## 4. Feature Development Workflow

Git mechanics layered onto `Development-Lifecycle.md`'s 13 phases — this is the same
lifecycle, shown at the branch/MR level:

```
Business Approved (Phase 3)
        ↓
Technical Approved (Phase 5)
        ↓
Implementation Plan Approved (Phase 6) → Ready for Development (Phase 7)
        ↓
Create feature branch from develop
        ↓
Development (Phase 8) — commits per §6
        ↓
Open Merge Request (§5)
        ↓
Review (Phase 9, §7)
        ↓
Approval
        ↓
Merge into develop
        ↓
Release (§10)
        ↓
main
```

**A feature branch is never created before Phase 7 (`Ready for Development`)** — creating
one earlier would mean writing code against documentation that isn't approved yet, which
`Project-Constitution.md` §5 does not permit.

---

## 5. Merge Request Standards

Every Merge Request includes:

- **Purpose** — one or two sentences, what this MR does.
- **Related feature** — the module and, if applicable, the specific Feature ID
  (`Team-Management.md` §7).
- **Related documentation** — links to the approved Business Specification, Technical
  Design, and Implementation Plan this MR implements.
- **Related issue** — the GitLab issue tracking this work (§13).
- **Testing summary** — what was tested and how (`testing-standards.md`).
- **Checklist** — the relevant items from `coding-standards.md` §16 / `api-standards.md`
  §20 / `database-standards.md` §19, whichever apply.

**Required approvals before merging:** at least one approval from the reviewer assigned per
`Team-Management.md` §5 (Ahmed, unless Ahmed implemented — then Mohamed or Abukar). Branch
protection (§2) makes this a hard gate, not a courtesy — a Merge Request cannot merge into
`develop` or `main` without it.

---

## 6. Commit Standards

Format is fully governed by `naming-conventions.md` §11 — restated here only as a
reference:

```
feat:      a new feature
fix:       a bug fix
docs:      documentation only
refactor:  code change that neither fixes a bug nor adds a feature
test:      adding or correcting tests
chore:     tooling, dependencies, non-product changes
perf:      a performance improvement
style:     formatting only, no logic change
```

```
feat: add hold expiry to booking service
fix: correct off-by-one error in pagination totalPages calculation
docs: update booking-management technical design with hold-expiry decision
```

---

## 7. Review Workflow

The rule itself is `Team-Management.md` §5 and `Development-Lifecycle.md` Phase 9 — not
restated here. What this document adds is how it's enforced in GitLab:

- **No self-review** is enforced by GitLab's "prevent approval by author" setting on
  protected branches — not left to individual discipline alone.
- **Ahmed reviews Mohamed's and Abukar's work; Mohamed or Abukar reviews Ahmed's** — the
  correct reviewer is assigned on the Merge Request at the time it's opened, per the
  Feature Assignment Register (`Team-Management.md` §7).
- **Documentation updates are reviewed as part of the same Merge Request** as the code
  change they accompany — a code change that should have updated a document, per
  `Project-Constitution.md` §5, is not approved until that update is included.
- **Architecture and security compliance** are checked as part of review using
  `coding-standards.md` §16, `api-standards.md` §20, and `database-standards.md` §19's
  checklists, whichever apply to the change.

---

## 8. Documentation Workflow

Documentation changes follow the **same** Git workflow as code — a branch, a Merge Request,
a review — never a direct edit to a file in `docs/` on `develop` or `main`.

**Documentation is updated before implementation**, per `Project-Constitution.md` §5:

```
Business Specification
        ↓
Technical Design
        ↓
Implementation Planning
        ↓
Development
        ↓
Validation
```

Each of the first three stages is its own reviewed change (Business Specification and
Technical Design reviewed by Mohamed or Abukar, per `Development-Lifecycle.md` Phases 3 and
5) before the feature branch for *implementation* is even created (§4).

---

## 9. Conflict Resolution

- **Merge conflicts** are resolved by the developer who opened the Merge Request, by
  rebasing their feature branch onto the current `develop` — not by the reviewer, and not
  by force-pushing over `develop`'s history.
- **Simultaneous feature work** is expected and safe by design — feature-based architecture
  (`Architecture-Principles.md` §3) means two features touching different modules rarely
  conflict at the code level; when they do, it's often a signal the module boundary needs
  revisiting (`coding-standards.md` §3).
- **Branch synchronization** — a feature branch merges the latest `develop` into itself
  periodically during long-running work (§14), rather than diverging for the whole
  implementation phase and reconciling everything at the end.
- **Rebase vs. merge policy:** a feature branch is rebased onto `develop` to stay current
  (keeps history linear and readable); the Merge Request itself merges into `develop` via a
  merge commit (preserves the record of what was reviewed and approved as one unit). History
  on `develop` and `main` is never rewritten once merged.

---

## 10. Release Workflow

```
feature branches
        ↓
develop
        ↓
release/<version>
        ↓
main
```

- A `release/<version>` branch is cut from `develop` once the set of features targeted for
  that release have all reached `Feature Accepted` (`Team-Management.md` §6).
- Only release-blocking fixes are committed to a `release/` branch — no new features.
- Once stable, the `release/` branch merges into `main` (tagged, below) **and** back into
  `develop`, so `develop` never loses a fix made during release stabilization.
- **Tagging:** every merge to `main` is tagged `vMAJOR.MINOR.PATCH` (semantic versioning) —
  the tag is what a deployment actually references, never a branch name or commit SHA alone.
- **Version numbering** follows semantic versioning: `MAJOR` for breaking API changes
  (`api-standards.md` §3), `MINOR` for new backward-compatible functionality, `PATCH` for
  fixes.
- **Release notes** summarize what shipped, referencing the Feature IDs
  (`Team-Management.md` §7) included — this is the release-facing counterpart to the
  Validation Reports already produced per feature.

---

## 11. Emergency Hotfix Workflow

For an urgent fix to something already live in `main`:

```
main
  → hotfix/<issue>
  → Merge Request (expedited review, still no self-review)
  → merge into main (tagged as a PATCH release)
  → merge into develop
```

- A `hotfix/` branch is cut directly from `main`, not from `develop` — `develop` may
  already contain unreleased work that shouldn't ship with the hotfix.
- **Review requirements are not relaxed for urgency** — the same no-self-review rule
  applies (§7); "urgent" changes the speed of review, never whether it happens.
- **Testing** — a hotfix still requires verification appropriate to its risk
  (`testing-standards.md`); "urgent" is not a reason to skip validation of the fix itself.
- The hotfix is merged into **both** `main` and `develop` — never only one, or `develop`
  silently regresses the bug on the next regular release.

---

## 12. AI Development Workflow

This restates and is governed by `Project-Constitution.md` §4, `Architecture-Principles.md`
§14, and `coding-standards.md` §15 — see those for the canonical AI rules. Git-specific
additions only:

- **AI works only within the assigned feature branch** — never commits to `develop`,
  `main`, or another feature's branch.
- **AI never commits directly to a protected branch** — every change goes through a Merge
  Request (§5), same as any human contributor.
- **AI never bypasses review** — an AI-authored Merge Request is reviewed under the same
  rule as a human-authored one (§7).
- **AI follows approved documentation and never invents requirements** — restated because
  it's the precondition for §4's branch-creation timing (a branch exists only once
  documentation is approved).

---

## 13. GitLab Standards

- **Issues** — every feature, bug, and hotfix has a corresponding GitLab issue, linked from
  its Merge Request (§5); an issue references the relevant Feature ID
  (`Team-Management.md` §7) where applicable.
- **Labels** — used to indicate module (matching `naming-conventions.md` §4's module names)
  and type (`feature`, `bug`, `hotfix`, `docs`), so work is filterable by either axis.
- **Milestones** — correspond to the Milestones defined in `Development-Roadmap.md` §6, not
  invented independently in GitLab.
- **Merge Requests** — per §5; never merged without the required approval (§7).
- **Protected branches** — `main` and `develop`, per §2 — configured to require approval
  and to prevent self-approval, force-push, and direct commits.
- **CI/CD pipelines** — run automated tests (`testing-standards.md`) on every Merge Request
  before it becomes mergeable; a failing pipeline blocks merge the same way a missing
  approval does. Specific pipeline configuration is an infrastructure decision tracked
  alongside the still-open hosting/CI/CD choices in `Project-Overview.md` §13, not invented
  here.

---

## 14. Best Practices

- **Small, focused commits** — one logical change per commit, matching
  `coding-standards.md` §2's "small, focused functions" principle at the commit level.
- **One feature per branch** — a feature branch never accumulates unrelated work "while
  I'm in there."
- **Frequent synchronization with `develop`** — a long-running feature branch rebases
  regularly (§9), not just before opening its Merge Request.
- **Meaningful commit messages** — the type prefix (§6) plus a description specific enough
  that `git log` is useful without opening each commit.
- **Keep branches short-lived** — a feature branch's life matches its Implementation phase
  (`Development-Lifecycle.md` Phase 8); it doesn't outlive the feature it implements.
- **Delete merged branches** — a feature branch is deleted once merged into `develop`; it
  is not kept "just in case" — the history is preserved in `develop`'s log regardless.

---

## 15. Git Workflow Checklist

What a developer confirms before and during a Merge Request — the formal Implementation
Review approval itself is `review-checklists.md` and `Development-Lifecycle.md` Phase 9;
this is a reading aid, the same relationship `coding-standards.md` §16 has to that review.

- [ ] Documentation (Business Spec, Technical Design, Implementation Plan) approved before
      the branch was created (§4).
- [ ] Feature branch created from `develop`, named per `naming-conventions.md` §11.
- [ ] Coding standards followed (`coding-standards.md`).
- [ ] Tests passed (`testing-standards.md`).
- [ ] Documentation updated as part of this change, if applicable (§8).
- [ ] Review completed by the correct reviewer, no self-review (§7).
- [ ] Merge approved via GitLab (§5).
- [ ] Branch deleted after merge (§14).

---

## Version History

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-08-03 | Ahmed | Initial approved Git Workflow & Branching Strategy |
