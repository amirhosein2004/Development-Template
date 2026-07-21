# Workspace commands reference

Every routed slash command exposed by the shared workspace config, its sub-operations, argument shape, and which repos it touches. Bodies live in `commands/<name>.md` (thin) and `skills/<name>/SKILL.md` (fat).

Naming standard for authoring new entries: see [claude-code-guide.md](claude-code-guide.md) §"Naming standard for bundled commands and skills".

---

## Workspace shape (discovered at call time)

Every skill resolves the repo list from disk — never hard-coded. Discovery pattern:

```sh
ls -1d <workspace-root>/docs \
        <workspace-root>/business/docs \
        <workspace-root>/product/docs \
        <workspace-root>/tech/docs \
        <workspace-root>/tech/*/ 2>/dev/null
```

Expected shape (per project — sizes vary):

| Class | Path | Default branch |
|---|---|---|
| Umbrella docs | `docs` (or `agent-config`) | `main` |
| Discipline docs | `business/docs`, `product/docs`, `tech/docs` | `main` |
| Engineering — backend | `tech/backend-*` | `develop` |
| Engineering — shared library | `tech/backend-shared-logic` (or per-project name) | `develop` (release tags cut on `main`) |
| Engineering — frontend | `tech/frontend-*` | `develop` |
| Engineering — infra / devops | `tech/infra-*` (or `tech/devops-*`) | `develop` |

Per-repo default branch resolved via `git symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/` prefix). Any repo added later surfaces automatically.

---

## Nine bundled commands (lifecycle order)

The bundle ships nine routed commands. Grouped by when in a project's life you use them:

| Phase | Command | Purpose |
|---|---|---|
| **Birth (once)** | `/init` | Project-birth pipeline — product → business → design-system → features → tech-architecture → tech-standards |
| **Install (per-machine)** | `/setup` | Wire the shared `.claude/` config into a workspace root; refresh onboarding + memory |
| **Author** | `/docs`, `/uiux`, `/implement` | Write PRD-TDDs, UI/UX packs, code / migrations / tests |
| **Ongoing** | `/workspace`, `/mr`, `/audit` | Housekeeping, MR flow, read-only reconciliation |
| **Meta** | `/author` | Scaffold new bundled commands and skills |

Each section below documents the routing, argument shape, and safety profile.

---

## `/init <product|business|design-system|features|tech-architecture|tech-standards> [<sub-op args>]`

Project-birth pipeline. Six sub-ops run in order (`product` → `business` → `design-system` → `features` → `tech-architecture` → `tech-standards`) when seeding a fresh workspace; each sub-op consumes what the previous ones wrote.

| Sub-op | Argument shape | Behaviour |
|---|---|---|
| `product` | *(interactive)* | Interactively collect product identity, positioning, features / non-features, market context. Write `product/docs/product.md` from `_templates/product.md`. First step in the pipeline. |
| `business` | `<discover|audit|synthesize>` (each with its own sub-args) | Four-stage competitor-analysis pipeline (init → discover → audit → synthesize). Reads `product/docs/product.md` as source of truth. Writes under `business/docs/competitor-analysis/`. |
| `design-system` | *(none)* | Synthesize the canonical design system from `product/docs/uiux/_templates/`, `product/docs/product.md`, and the newest competitor snapshot. Writes `product/docs/uiux/design-system/`. |
| `features` | `<version>` | Auto-classify every feature from the newest competitor feature-catalog into `[x]` (in scope) or `[ ]` (deferred) for the given product version. Writes `product/docs/features/v<N>/all-features.md`. |
| `tech-architecture` | *(none)* | Pick the platform architecture shape (monolith vs microservices) from the version's `[x]` feature set + `product.md` positioning + design system. Report backend / frontend / infra repo list to chat only — no file written. |
| `tech-standards` | *(none)* | Populate `tech/docs/standards/` (twelve files) + `tech/docs/project-architecture/v<N>.md` from `_templates/`. |

Skill: [skills/init/SKILL.md](skills/init/SKILL.md).

---

## `/workspace <status|sync|clean|mrs> <touched|all>`

Meta-level housekeeping across the discovered workspace. First arg = sub-op, second = scope; both required.

| Sub-op | Scope | Behaviour |
|---|---|---|
| `status` | Read-only | Per-repo table: branch, default, clean / dirty, ahead / behind, open-MR count, stash count, single-word verdict. No fetch, no pull, no push. |
| `sync` | Remote-read-only | Checkout each repo's default branch and `git pull --ff-only`. Never pushes, force-deletes, drops stashes, or rewrites history. |
| `clean` | Local-only | Prune worktree registry, remove merged worktrees under `tmp/worktrees/`, delete local branches merged into default via `git branch -d` (never `-D`), prune stale remote-tracking refs, list (never drop) stashes. |
| `mrs` | Read-only | List every open MR via `glab mr list --state opened`, grouped by repo. |

Scope arg — `touched` = repos this session edited; `all` = every discovered workspace repo.

Skill: [skills/workspace/SKILL.md](skills/workspace/SKILL.md).

---

## `/mr <open|ship|format> [<touched|all|current|<repo-path>>]`

Single entry point for everything MR-shaped in the workspace.

| Sub-op | Scope arg | Behaviour |
|---|---|---|
| `open` | required | Stage explicit paths, conventional-commit, push, open MR via `glab mr create --description` (never `--fill`), stop after the report. |
| `ship` | required | Same as `open`, plus wait-for-mergeable + squash-merge + ff-pull the repo's default branch + clean up worktree / branch. |
| `format` | none | Standalone reference for branch name, commit subject, MR title, MR body shape (four sections: TLDR / Summary / Test Plan / Validation), mirror variants, hard rules. Loaded by other skills via `[[mr]]`. |

Scope: `touched` (session-touched) | `all` (every workspace repo) | `current` (repo containing CWD) | `<repo-path>`.

Enforces: no `Co-Authored-By:` footers; no direct push to protected branches; no bulk staging (`git add -A` / `--all` / `.` / `*`); no `--no-verify`, no `--no-gpg-sign`; `--description` never `--fill`. Promotion flow (`develop → staging → main`) and `fix/*` multi-MR fan-out enforced when `tech/docs/standards/git.md` declares them.

Skill: [skills/mr/SKILL.md](skills/mr/SKILL.md).

---

## `/docs <prd-tdd-backend|prd-tdd-library|prd-tdd-infra|prd-tdd-frontend> …`

Author the v<N> PRD-TDD documentation.

| Sub-op | Argument shape | Target |
|---|---|---|
| `prd-tdd-backend` | `<repo>::<mode>` (`mode` = `merge` \| `overwrite`) | One backend under `tech/backend-*` (excluding the shared library). |
| `prd-tdd-library` | `::<mode>` | The shared library repo (resolved from architecture — `SHARED_LIBRARY_NAME`). No transport surface; distributes as a git-tag pinned package. |
| `prd-tdd-infra` | `<repo>::<mode>` | One infra repo (`tech/infra-*` or `tech/devops-*`). |
| `prd-tdd-frontend` | `<repo>::<mode>` | One frontend repo (`tech/frontend-*`). Section map varies by build mode (SSG vs SPA), resolved from architecture §4. |

Section maps come from the templates under `skills/docs/` — never hard-coded in the skill body. Templates instantiate `{{VARIABLE}}` / `{{#IF}}` / `{{#EACH}}` blocks from the workspace's `tech/docs/project-architecture/v<N>.md`.

Skill: [skills/docs/SKILL.md](skills/docs/SKILL.md).

---

## `/implement <backend-service|backend-library|backend-tests|frontend-bootstrap|frontend-page|frontend-tests|infra-scaffold> …`

Implementation skill. Reads every stack / locale / calendar / provider knob from `tech/docs/project-architecture/v<N>.md`; nothing about the target stack lives in the skill body.

| Sub-op | Argument shape | Behaviour |
|---|---|---|
| `backend-service` | `<repo>[::full\|gap\|section=<n>\|library-refactor]` | Generate one backend microservice OR one module inside a monolith (chosen by `ARCH_SHAPE`). Writes `src/`, migrations, ops scaffolds, bare test scaffolds. |
| `backend-library` | `[::full\|gap\|patch=<module>]` | Generate the shared library repo (name from `SHARED_LIBRARY_NAME`). Modules generated conditionally on `HAS_KAFKA` / `HAS_REDIS` / `HAS_MINIO` / `CALENDAR` / `OTP_PROVIDER`. |
| `backend-tests` | `<repo>[::full\|gap\|unit\|integration\|e2e\|entity=<entity>[.<verb>]\|path=<rel-path>]` | Fill the test scaffolds per `tech/docs/standards/testing.md`. |
| `frontend-bootstrap` | `<repo>` | Scaffold one frontend — package.json, tsconfig, build config, path aliases, hooks, ESLint boundaries, self-hosted fonts (list from architecture §4), locale-aware formatters (Jalali / Gregorian per `CALENDAR`). |
| `frontend-page` | `<repo>::<area>::<page>` | Generate one feature folder from a UI/UX HTML mockup. `<area>` resolved dynamically against `product/docs/uiux/<version>/`. |
| `frontend-tests` | `<repo>[::full\|gap\|feature=<area>[/<page-slug>]\|path=<rel-path>]` | Fill Vitest + RTL + MSW + Playwright specs. |
| `infra-scaffold` | `<repo>` | Scaffold one infra repo — config file(s), Docker Compose, init scripts, operational assets. Component list resolved from the repo path (`postgresql`, `redis`, `minio`, `meilisearch`, `kafka`, `nginx`, `observability`, or any other component the project ships). |

Skill: [skills/implement/SKILL.md](skills/implement/SKILL.md).

---

## `/setup <link|unlink|refresh>`

Wire the shared `.claude/` config into the workspace root, or refresh the workspace-root `CLAUDE.md` from disk.

| Sub-op | Behaviour |
|---|---|
| `link` | Register / re-register the shared config (five relative symlinks `../<docs-container>/.claude/<entry>` — `commands`, `hooks`, `skills`, `sounds`, `settings.json`). Idempotent. Works on Ubuntu / WSL2 / macOS / Git Bash (`ln -s`) and native Windows (`New-Item -ItemType SymbolicLink` / `mklink`). Docs-container is discovered (usually `docs/`; sometimes `agent-config/`). |
| `unlink` | Remove the five symlinks and remove `<workspace-root>/.claude/` only if empty. |
| `refresh` | Discover repos from disk, read each repo's onboarding + standards + PRD-TDDs, rewrite the root `CLAUDE.md` in conditional `@`-path table format, then wipe and refill the memory directory. |

Skill: [skills/setup/SKILL.md](skills/setup/SKILL.md).

---

## `/uiux <scaffold|design|audit> <area>::<mode-or-scope>[::companions=<spec>]`

Author + reconcile UI/UX packs under `product/docs/uiux/<version>/<area>/`. Reads locale / direction / calendar / brand-mark path / spec-filename prefix from `product/docs/uiux/<version>/design-system/*.md` §1 Brand essentials — never hard-coded.

| Sub-op | Argument shape | Behaviour |
|---|---|---|
| `scaffold` | `<area>::<mode>[::companions=<spec>]` (`mode` = `bootstrap` \| `merge`) | Scaffold one multi-page area — empty HTML files at every sitemap route, empty `assets/pages.css`, empty `assets/pages.js`, brand SVGs copied verbatim, minimal companion spec skeleton. **Empty skeleton only** — every design decision belongs to `design`. |
| `design` | `<area>::<scope>[::companions=<spec>]` (`scope` = `page:<route>` \| `pages:<route1>,<route2>[,…]` \| `all`) | Write / rewrite the concrete design code (HTML, CSS, JS) inside an existing area. Mobile-first responsive across three tiers (breakpoint tokens from design-system), every color / spacing / class bound to the design system, every change reflected in the area's spec + appended to §6 Design changelog. |
| `audit` | `<area>::<mode>` (`mode` = `report` \| `prune`) | Reconcile an existing area against the `[x]` catalog. Enumerates every route, section, block, widget, form field, table column, filter chip, action, dashboard tile, admin surface, and role-scoped visibility rule. Anything not backed by an `[x]` row is an offender. `report` = enumerate only; `prune` = delete files / surgically remove elements / sweep orphan CSS+JS / rewrite the spec / verify responsive integrity. |

Skill: [skills/uiux/SKILL.md](skills/uiux/SKILL.md).

---

## `/author <command|skill> <name>[::<sub-op-1>,<sub-op-2>,…]`

Scaffold new slash commands and skills for the bundle.

| Sub-op | Argument shape | Behaviour |
|---|---|---|
| `command` | `<name>` | Unpaired single-file slash command at `<config>/commands/<name>.md` + reference-doc entries in `claude-code-guide.md` and `commands-reference.md`. |
| `skill` | `<name>[::<sub-op-1>,<sub-op-2>,…]` | Canonical paired artifact (`<config>/skills/<name>/SKILL.md` + `commands/<name>.md`) + reference-doc entries. Trailing sub-op list flips the body to routed layout; absent → single-purpose. |

Refuses on precondition violations: `<name>` missing / non-kebab / equal to `command` | `skill` / reserved by an already-existing file; existing files at any target path.

Skill: [skills/author/SKILL.md](skills/author/SKILL.md).

---

## `/audit <corpus|code|tests> [<scope>]`

Read-only audits over the project corpus and its implementation. First arg = sub-op. Every sub-op is strictly read-only.

| Sub-op | Argument shape | Behaviour |
|---|---|---|
| `corpus` | *(none)* | Full contract-level reconciliation audit of the documentation layer. Fixed read set: every engineering repo's `docs/v<N>/PRD-TDD.md`, `tech/docs/project-architecture/v<N>.md`, `product/docs/features/v<N>/all-features.md`, every `product/docs/uiux/<version>/*/*.md`. Extraction delegated to parallel read-only subagents; synthesis central. Cross-checks: PRD-TDD ↔ PRD-TDD (producer/consumer pairs, internal endpoints, mirrors, enums), PRD-TDD ↔ architecture, catalog ↔ everything, UI/UX ↔ backend, internal per-doc drift. Blocking open questions get drafted answers grounded in quoted corpus evidence — in the report only. |
| `code` | `<repo\|backend\|frontend\|infra\|all>` | Doc ↔ code + code ↔ code reconciliation. **GAP** = promised, not implemented. **DRIFT** = implemented differently. **CREEP** = implemented with no `[x]` backing. Rulers per repo: its PRD-TDD, standards, feature catalog. Anti-hallucination: every finding quotes code file+line and doc section. |
| `tests` | `<repo\|all>` | Test-coverage reconciliation. Rulers: `testing.md` in full; the repo's PRD-TDD §7/§11/§14. Measures: coverage matrix per entity × verb, error codes with no test, acceptance criteria with no happy-path, consumed topics with no integration test, banned patterns. |

Skill: [skills/audit/SKILL.md](skills/audit/SKILL.md).
