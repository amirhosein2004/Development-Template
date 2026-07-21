# Documentation Standards & Standards Index (tech)

> **Documentation placement.** Cross-repo standard — written once and referenced by every repo (see §5 of this file).

## Scope

Defines **how documentation is organized, written, and kept truthful** across the {{PROJECT_NAME}} repositories, and serves as the **index for the technical standards set** under `tech/docs/standards/`.

{{PROJECT_NAME}} is **multi-repo**: each top-level area is its own git repository — {{#IF DOC_LAYERS=4}}`docs`, `business/docs`, `product/docs`, `tech/docs`{{#ELSE}}`business/docs`, `product/docs`, `tech/docs`{{/IF}}, every {{OWNER_TERM}} under `tech/`, every frontend, {{#IF ARCH_SHAPE=microservices}}and every infra repo{{#ELSE}}and every infra repo{{/IF}}. No monorepo root. This document governs the **docs layer** (prose, repo-overview docs, docstrings, API docs, the standards set) — not the lint / CI machinery, catalogued in [`ci-cd.md`](./ci-cd.md).

> **Reading convention:**
> - **CURRENT** — how things are today (verified against the repos).
> - **STANDARD GOING FORWARD** — a recommended best practice not yet (fully) in place; explicitly labelled.

## Source of truth & precedence

Coding, commit, and branch conventions are **cross-repo and live in this set** (`tech/docs/standards/`). Engineering code repos do **not** carry their own per-{{OWNER_TERM}} coding-convention documents; per-{{OWNER_TERM}} `docs/` is reserved for **schema reference** and **local-setup / run** instructions — not for re-stating the cross-repo standards.

| Source | Role |
|---|---|
| `tech/docs/standards/*` | The **technical standards set** — the canonical "how we build" reference. **Wins on conflict.** |
{{#UNLESS DOC_LAYERS=3}}
| `tech/docs/v1/project-architecture.md` (or `tech/docs/project-architecture/v1.md`) | The v1 macro architecture: services / modules, feature-to-{{OWNER_TERM}} map, deployment topology, cross-cutting decisions. |
{{/UNLESS}}
| `tech/{{OWNER_TERM}}-<name>/docs/product/` | Per-{{OWNER_TERM}} schema reference. |
| Per-{{OWNER_TERM}} repo-overview doc at the repo root | {{OWNER_TERM}} purpose, how-to-run, required env. |
| {{#IF DOC_LAYERS=4}}`docs/`, {{/IF}}`business/docs/`, `product/docs/`, `tech/docs/` | Discipline-scoped prose conventions. |

---

## 1. Where standards & docs live (the {{#IF DOC_LAYERS=4}}four{{#ELSE}}three{{/IF}} layers)

| Layer | Repo | Owns |
|---|---|---|
{{#IF DOC_LAYERS=4}}
| **Umbrella** | `docs/` | Cross-repo standards that apply to every repo. Currently: git conventions. Grows to include docs style, ADR template. |
{{/IF}}
| **Business** | `business/docs/` | Brand assets + tokens, competitor research, legal / founding documents. |
| **Product** | `product/docs/` | The versioned feature catalog (`features/v1/all-features.md`), the versioned UI/UX (`uiux/v1/design-system/` + per-frontend page sets). |
| **Tech** | `tech/docs/` (this repo) | Platform architecture, engineering-layer standards, ADRs, runbooks (when introduced). Per-{{OWNER_TERM}} PRD-TDD docs live in each engineering repo's `docs/v1/PRD-TDD.md`. |

The workspace-level onboarding orchestrates conditional reads across all layers. Read that file before any workspace-crossing task.

---

## 2. Repository & doc-tree map

| Repo / folder | Owns | Notes |
|---|---|---|
| `business/docs/` | Business docs: competitor analysis, strategy, market research. | {{#IF LOCALE_MODE=farsi-only}}May be Persian{{/IF}}{{#IF LOCALE_MODE=bilingual}}Persian and English by parity{{/IF}}{{#IF LOCALE_MODE=latin-only}}Latin-only{{/IF}}. |
| `product/docs/` | Product / UX: `features/` (v1 catalog), `uiux/` (design system, wireframes, mockups). | Versioned folders. The **design system** is the UI source of truth. |
| `tech/docs/standards/` | The technical standards set (this document and its siblings). | Canonical technical "how we build" reference. Coding / commit / branch conventions live here, **not** in any {{OWNER_TERM}} repo. |
| `tech/docs/v1/` (or `tech/docs/project-architecture/v1.md`) | v1 macro architecture. | Version-scoped. |
| `tech/{{OWNER_TERM}}-<name>/docs/product/` | Schema reference. | Per-{{OWNER_TERM}}. |
| `tech/{{OWNER_TERM}}-<name>/docs/v1/PRD-TDD.md` | Per-{{OWNER_TERM}} PRD + TDD for v1. | Version-scoped. |
| `tech/{{OWNER_TERM}}-<name>/` (root) | Generated repo-overview doc + its `.prompt` source. | Overviews start as stubs and fill in per §7. |
| `tech/frontend-<app>/` | Frontend apps. | Each carries `docs/v1/PRD-TDD.md` + repo-overview. |
| `tech/infra-<component>/` / `tech/devops-<component>/` | Infra components. | Each carries `docs/v1/PRD-TDD.md` for cluster ops, topic / bucket / role catalog. |

---

## 3. Single-source-of-truth map

Each cross-cutting concern has **exactly one** authoritative file. Everything else **links** to it — never forks / copies it.

| Concern | Source of truth | Consumed by |
|---|---|---|
| Macro architecture & {{OWNER_TERM}} map | `../v1/project-architecture.md` (or `../project-architecture/v1.md`) | all teams |
| Per-{{OWNER_TERM}} layout & module rules | [`{{#IF ARCH_SHAPE=microservices}}microservice-layout{{#ELSE}}monolith-layout{{/IF}}.md`](./{{#IF ARCH_SHAPE=microservices}}microservice-layout{{#ELSE}}monolith-layout{{/IF}}.md) | all backend {{OWNER_TERM}}s |
| Shared infrastructure | [`infrastructure.md`](./infrastructure.md) | all backend {{OWNER_TERM}}s |
| Per-{{OWNER_TERM}} schema (tables / columns) | `tech/{{OWNER_TERM}}-<name>/docs/product/DATABASE_TABLES_REFERENCE.md` | that {{OWNER_TERM}} |
| API surface / contracts | [`api-and-data-contracts.md`](./api-and-data-contracts.md) + the {{OWNER_TERM}}'s OpenAPI | frontends, other {{OWNER_TERM}}s |
| UI / design system | `product/docs/uiux/.../design-system/` | frontends |
| Product features & specs | `product/docs/features/v1/all-features.md` + `product/docs/uiux/` | product / eng |
| Business strategy / KPIs | `business/docs/strategy/` | business |

> **Rule:** if you need the same fact in two places, **link** the canonical file. Do not duplicate.

---

## 4. Technical standards-set index (`tech/docs/standards/`)

Every file uses the **same skeleton**: `# H1`, **Scope**, **Source of truth & precedence**, body, **How this is enforced**, **Related standards files** — plus the **CURRENT / STANDARD GOING FORWARD** labelling convention.

| File | Covers |
|---|---|
| [`{{#IF ARCH_SHAPE=microservices}}microservice-layout{{#ELSE}}monolith-layout{{/IF}}.md`](./{{#IF ARCH_SHAPE=microservices}}microservice-layout{{#ELSE}}monolith-layout{{/IF}}.md) | Canonical backend layout, per-entrypoint Dockerfile pattern, per-{{OWNER_TERM}} stack |
| [`infrastructure.md`](./infrastructure.md) | Shared infrastructure: PostgreSQL (schema, `DbAction`, raw-SQL Alembic){{#IF HAS_REDIS}}, Redis (cache only){{/IF}}{{#IF HAS_KAFKA}}, Kafka (the only broker){{/IF}}{{#IF HAS_MINIO}}, MinIO (object storage){{/IF}}{{#IF HAS_MEILISEARCH}}, Meilisearch{{/IF}} |
| [`documentation.md`](./documentation.md) | Documentation standards & this index — **this file** |
| [`coding.md`](./coding.md) | Code & style (naming, imports, file-size limits, type annotations) |
| [`api-and-data-contracts.md`](./api-and-data-contracts.md) | Response envelope, URL / versioning, error shapes, pagination |
| [`testing.md`](./testing.md) | Testing pyramid, pytest layout, coverage target |
| [`errors-and-observability.md`](./errors-and-observability.md) | `ProjectBaseException`, global handler, status codes; structured logging, OTel tracing, health / readiness |
| [`security-and-auth.md`](./security-and-auth.md) | JWT (RS256), OTP, sessions, RBAC, secret management |
| [`ci-cd.md`](./ci-cd.md) | ruff / mypy / pre-commit / CI gates, **uv** dependency management, per-entrypoint Docker images, CI pipeline, deployment, versioning{{#IF ARCH_SHAPE=microservices}}, **shared-logic version-lock gate**{{/IF}} |
| [`git.md`](./git.md) | Branch naming, commit convention, MR review, deployment branch model |
| [`frontend.md`](./frontend.md) | Frontend repos, stack, {{#IF LOCALE_MODE=farsi-only}}RTL rules{{/IF}}{{#IF LOCALE_MODE=bilingual}}bilingual + RTL rules{{/IF}}{{#IF LOCALE_MODE=latin-only}}i18n rules{{/IF}} |
| [`frontend-layout.md`](./frontend-layout.md) | Canonical directory layout per frontend repo (vertical-slice feature folders, two rings, aliases, decision tree) |

There is **no per-{{OWNER_TERM}} `docs/development/`** layer. Cross-cutting engineering rules live here and **only** here.

---

## 5. Doc taxonomy & placement

### 5.1 Cross-repo vs repo-specific

- **Cross-repo / general subjects → `tech/docs/`.** Anything that applies to *all* repositories (git workflow, branch naming, commit convention, MR review, code standards, CI/CD policy, architecture principles) lives under `tech/docs/`. Written once and referenced by every repo.
- **Repo-specific subjects → that repo only.** Each repo carries only documents specific to its own scope — schema of a {{OWNER_TERM}}-local table, endpoints unique to that {{OWNER_TERM}}, how to run the {{OWNER_TERM}} locally.
- If the same document would be valid (word-for-word) in two or more repos, it belongs in `tech/docs/`. If it would be wrong or meaningless outside one repo, it stays in that repo.

### 5.2 Where to add a doc

| Type of doc | Goes in |
|---|---|
| Cross-{{OWNER_TERM}} technical standard | `tech/docs/standards/<topic>.md` |
| Macro architecture (services, deployment, cross-cutting decisions) | `tech/docs/v1/project-architecture.md` |
| {{OWNER_TERM}} schema reference | `tech/{{OWNER_TERM}}-<name>/docs/product/` |
| {{OWNER_TERM}} PRD-TDD (v1) | `tech/{{OWNER_TERM}}-<name>/docs/v1/PRD-TDD.md` |
| {{OWNER_TERM}} overview / run instructions | that {{OWNER_TERM}}'s generated overview doc at the repo root |
| Architecture **decision** (the *why*) | `tech/docs/adr/` (ADRs — see §8) |
| Operational fix re-run on incidents | `tech/docs/runbooks/` (see §9) |
| Product feature / spec | `product/docs/features/` or `product/docs/uiux/` |
| UI / design-system | `product/docs/uiux/.../` |
| Business strategy / competitor / KPI | `business/docs/{strategy,competitor-analysis,features}/` |

**Versioned doc folders (CURRENT).** Business, product, and tech-architecture docs snapshot a release under `v<major>/` (e.g. `v1/`). Never embed dates in version folder names.

**No `archive/` folder.** Superseded docs stay in their topic folder until the work referencing them ships, then are **deleted** in that same PR. Versioned snapshots above are the deliberate exception.

**Don't create a folder for one file.** Keep a single doc at its parent level until it has siblings.

---

## 6. Docstring standards

Docstrings are the **only machine-gated doc rule** — enforced by `ruff` pydocstyle (`D`) over `src/`.

| Rule | Standard |
|---|---|
| Required | Public **classes, methods, and functions** carry a docstring (`D101` / `D102` / `D103`). |
| Optional | Module (`D100`) and package (`D104`) docstrings — encouraged for non-obvious modules, not required. |
| Style | Summary on the **first** line (via the `D212` ignore); **no blank line before the class docstring** (via the `D203` ignore). |
| Content | Explain **why / contract**, not a restatement of the signature. Document args, returns, and raised `ProjectBaseException`s for non-trivial functions. |
| Types | Type information lives in **annotations** (mandatory per code standards), not duplicated in prose. |
| Excluded | `scripts/`, `migrations/`, `tests/` are exempt from docstring enforcement. |

---

## 7. Repo-overview standards

- **Every repo / {{OWNER_TERM}} ships a generated overview doc** at its root as its entry point.
- The overview must cover: **purpose**, **how to run** (docker-compose command), **required env** (point to `.env.example`), and **links** to the relevant standards.
- **AI-generation convention (CURRENT):** a sibling `.prompt` file holds the prompt used to (re)generate the overview with AI. Regenerate from the prompt, then **a human reviews and edits** before commit.

> **STANDARD GOING FORWARD:** flesh each overview out to the contract above.

---

## 8. API documentation

- **OpenAPI is auto-generated** by FastAPI from route definitions, `response_model`s, and the `summary` / `description` on each route — keep those accurate and meaningful.
- **`/docs`, `/redoc`, `/openapi.json` stay mounted** at FastAPI's defaults. {{#UNLESS DEV_BRANCH_CHAIN=main only}}On `develop` / `staging` the whole site is behind nginx HTTP Basic at the edge, so those routes inherit that gate. On `product` (production, served from the `main` branch) the app gates them with HTTP Basic using `SERVICE_DOCS_USERNAME` / `SERVICE_DOCS_PASSWORD` from `ENVS`.{{/UNLESS}}{{#IF DEV_BRANCH_CHAIN=main only}}Production gates them with HTTP Basic using `SERVICE_DOCS_USERNAME` / `SERVICE_DOCS_PASSWORD` from `ENVS`.{{/IF}}
- URL / versioning, the response envelope, and error shapes are governed by [`api-and-data-contracts.md`](./api-and-data-contracts.md); the OpenAPI spec is the per-{{OWNER_TERM}} realization of that contract.

> **STANDARD GOING FORWARD:** export the generated OpenAPI JSON in CI as a versioned artifact so frontends and other {{OWNER_TERM}}s can codegen typed clients and diff contract changes across releases.

---

## 9. Architecture Decision Records (ADRs) — STANDARD GOING FORWARD

Capture **significant, hard-to-reverse decisions and their rationale** as lightweight ADRs under `tech/docs/adr/`, named `NNNN-<slug>.md` (e.g. `0001-raw-sql-over-orm.md`, `0002-ulid-primary-keys.md`). Each ADR is short: **Context · Decision · Status · Consequences**. ADRs are immutable once accepted; a later decision **supersedes** an earlier one (link both ways) rather than editing history.

## 10. Runbooks & incident docs — STANDARD GOING FORWARD

Operational procedures that get re-run when something breaks live under `tech/docs/runbooks/` (e.g. DB drift recovery, stuck-migration unblock, pool exhaustion{{#IF CDN_PROVIDER}}, CDN purge-storm{{/IF}}{{#IF OTP_PROVIDER}}, OTP-SMS provider outage fallback{{/IF}}). Keep them **action-first**: symptom → check → fix → verify. Post-incident write-ups (timeline, root cause, follow-ups) live alongside as `runbooks/postmortems/`.

---

## 11. The Diátaxis lens

| Mode | Purpose | Where in {{PROJECT_NAME}} |
|---|---|---|
| **Reference** | Information-oriented ("how things are") | `tech/docs/standards/*`, `DATABASE_TABLES_REFERENCE.md`, OpenAPI |
| **How-to** | Task-oriented ("do X") | `docs/development/Development Initial Setup.md`, runbooks, the §7 / §8 playbooks |
| **Explanation** | Understanding-oriented ("why") | ADRs, rationale sections of the standards docs |
| **Tutorial** | Learning-oriented (guided first run) | onboarding guide (add when needed) |

---

## 12. Authoring conventions

- **Markdown**, one `#` H1 per file, sentence-case headings, tables for enumerable rules.
- **Relative links** between docs; a moved / renamed doc must update its inbound links in the same change.
- **Terse, bulleted, tabular, visual** — prefer a table or diagram over a paragraph.
- **Absolute dates** (`2026-05-31`), never "last week".
{{#IF CALENDAR=dual}}
- **Jalali dates in Persian-facing prose (product / business docs, UI copy) — ISO-8601 Gregorian in engineering / API / machine feeds.**
{{/IF}}
{{#IF CALENDAR=jalali}}
- **Jalali dates in human-facing prose — ISO-8601 Gregorian in engineering / API / machine feeds.**
{{/IF}}
- **Changelog:** for docs / specs that evolve, keep a *Keep a Changelog*-style top section or rely on git history + ADRs for the "why".
- **Language:** the technical standards set and code docstrings are **English**. Business / product docs may match their audience's language.
- **Comments & docs explain *why*, not *what*** — the code says what.

---

## 13. AI-assisted documentation

1. The `.prompt` file is the **reproducible input**, committed next to the artifact it generates.
2. Generated output is **always human-reviewed and edited** before commit — the human, not the model, owns the result.
3. Generated docs follow every convention here (skeleton, single-source-of-truth, link integrity). Never paste a model's cross-reference without verifying the target exists.

---

## How this is enforced

| Standard | Enforcement |
|---|---|
| Docstrings on public classes / functions / methods | **Machine-gated:** `ruff` `D` (pydocstyle) in pre-commit + (going forward) CI |
| Doc placement (the "where to add a doc" table) | Reviewer rule — this file is the spec |
| Single-source-of-truth (link, never fork) | Reviewer rule — duplicated facts are rejected in review |
| "No `archive/`; delete superseded docs once work ships" | Reviewer rule |
| "No folder for one file" / versioned-folder convention | Reviewer rule |
| Link integrity (no dead relative links) | Reviewer rule today; **STANDARD GOING FORWARD:** a markdown link-checker in CI |
| No references to `CLAUDE.md` / `README.md` from inside content docs | Reviewer rule + workspace hook (blocks the edit) |
| Standards files open with the placement callout | Reviewer rule |
| Every standards file lives in `tech/docs/standards/` | Placement rule; PRs adding `standards/` files to other repos are automatic red |
| Machine-enforcement details for code rules | Catalogued in [`ci-cd.md`](./ci-cd.md) — this file governs only the docs layer + index |
