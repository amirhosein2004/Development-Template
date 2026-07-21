---
description: docs — prd-tdd-backend|prd-tdd-library|prd-tdd-infra|prd-tdd-frontend. Authors the v<N> PRD-TDD docs across the workspace; writes files only (no stage/commit/MR).
argument-hint: <prd-tdd-backend|prd-tdd-library|prd-tdd-infra|prd-tdd-frontend> <args per sub-op>
---

# docs — author PRD-TDDs

Routed command covering documentation authoring across every engineering repo discovered under `tech/`. The first positional argument selects the sub-op; the target set (backends, shared library, infra/devops, frontends) is discovered from disk plus the platform architecture doc — never hard-coded. Writes files only. Full step-by-step procedure lives in the SKILL twin at [`skills/docs/SKILL.md`](../skills/docs/SKILL.md).

## Synopsis

```
/docs prd-tdd-backend   <repo>::<mode>
/docs prd-tdd-library   ::<mode>                      # target is always the shared library repo discovered from architecture
/docs prd-tdd-infra     <repo>::<mode>
/docs prd-tdd-frontend  <repo>::<mode>
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `prd-tdd-backend` | [`## prd-tdd-backend`](#prd-tdd-backend) | Author v`<N>` PRD & TDD for one discovered backend microservice against [`TEMPLATE-backend.md`](../skills/docs/TEMPLATE-backend.md). |
| `prd-tdd-library` | [`## prd-tdd-library`](#prd-tdd-library) | Author v`<N>` PRD & TDD for the discovered shared library (name from architecture's `SHARED_LIBRARY_NAME`) against [`TEMPLATE-backend.md`](../skills/docs/TEMPLATE-backend.md) with the library delta. |
| `prd-tdd-infra` | [`## prd-tdd-infra`](#prd-tdd-infra) | Author lean v`<N>` PRD & TDD for one discovered `tech/infra-*` / `tech/devops-*` repo against [`TEMPLATE-infra.md`](../skills/docs/TEMPLATE-infra.md), using consumer-side reads. |
| `prd-tdd-frontend` | [`## prd-tdd-frontend`](#prd-tdd-frontend) | Author v`<N>` PRD & TDD for one discovered `tech/frontend-*` repo (landing SSG or admin/dashboard SPA) against [`TEMPLATE-frontend.md`](../skills/docs/TEMPLATE-frontend.md). |

## Router hard rules

- If the first arg is missing or invalid, **stop and ask** — never default.
- Every sub-op requires an explicit `<mode>` — no defaults; refuse and ask when missing.
- Workspace root, version `<N>`, target repo lists, and architecture flags are all discovered at call time (see SKILL.md § Workspace discovery). Never hard-coded.
- Writes one file only per invocation. Does NOT stage, commit, push, or open an MR — ship with [`/mr open <repo>`](mr.md) afterwards.

---

## prd-tdd-backend

Author the v`<N>` `docs/v<N>/PRD-TDD.md` for a single discovered backend microservice end-to-end — TL;DR through Changelog — following the canonical [`TEMPLATE-backend.md`](../skills/docs/TEMPLATE-backend.md). Read-heavy: ingests the full product feature catalog, the relevant UI/UX pack, every engineering standard (with primary focus on the architecture-layout file), the platform architecture, the existing PRD-TDD, and — when `HAS_KAFKA` — the Kafka topic catalog. Never reads sibling backend PRD-TDDs (would create a coupling loop). Writes one file only.

### Argument

`/docs prd-tdd-backend <repo>::<mode>`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `<repo>` | yes | workspace-root-relative `tech/backend-*` | Must be one of the discovered backend repos. Not hard-coded — refuses anything outside the on-disk set. |
| `<mode>` | yes | `merge` \| `overwrite` | `merge` keeps §8 Database schema verbatim, regenerates every other section. `overwrite` replaces the entire file. |

**Full procedure:** [`skills/docs/SKILL.md#prd-tdd-backend`](../skills/docs/SKILL.md#prd-tdd-backend).

### Refusal conditions

Refuse and stop if:

- argument missing or `<repo>` not among the discovered backend repos,
- `<repo>` matches the discovered `SHARED_LIBRARY_NAME` (use `prd-tdd-library`) or any `tech/infra-*` / `tech/devops-*` / `tech/frontend-*` path,
- `<mode>` is missing — stop and ask `merge` | `overwrite`,
- `<mode>` is given but is not `merge` | `overwrite`.

---

## prd-tdd-library

Author the v`<N>` `docs/v<N>/PRD-TDD.md` for the discovered shared-library repo — its name comes from architecture's `SHARED_LIBRARY_NAME`, never hard-coded — end-to-end, following [`TEMPLATE-backend.md`](../skills/docs/TEMPLATE-backend.md) with the **library delta** (no transport surface, no routes, no entrypoint dispatcher; distributes as a git-tag pinned package with the version-lock CI gate). Same read-heavy / write-once shape as `prd-tdd-backend`, but the target is a library, not a service. This is the one sub-op where sibling backend PRD-TDDs *are* read — the library's public API must fit its actual consumers.

### Argument

`/docs prd-tdd-library ::<mode>`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| _(none)_ | — | — | Target is **always** the discovered `SHARED_LIBRARY_NAME`. No repo positional. |
| `<mode>` | yes | `merge` \| `overwrite` | `merge` keeps §8 Public API surface verbatim (the library's binding contract), regenerates every other section. `overwrite` replaces the entire file. |

**Full procedure:** [`skills/docs/SKILL.md#prd-tdd-library`](../skills/docs/SKILL.md#prd-tdd-library) — includes the library delta table (§4 Personas → consuming services; §6 Data ownership → no tables/buckets/topics; §7 Distribution contract replaces Kafka + mirrors; §8 Public API surface replaces Database schema; §9 → one row per public function/class; etc.).

### Refusal conditions

Refuse and stop if:

- `HAS_SHARED_LIBRARY = false` in architecture,
- `<mode>` is missing — stop and ask `merge` | `overwrite`,
- `<mode>` is given but is not `merge` | `overwrite`,
- the operator supplies a `<repo>` other than the discovered `SHARED_LIBRARY_NAME` (a `backend-*` service belongs to `prd-tdd-backend`).

---

## prd-tdd-infra

Author a lean v`<N>` `docs/v<N>/PRD-TDD.md` for one discovered `tech/infra-*` (or `tech/devops-*`) repo — nine sections, ≤ ~250 lines target — following [`TEMPLATE-infra.md`](../skills/docs/TEMPLATE-infra.md). Input set: standards + architecture + the **consumer-side slices** of the discovered backend PRD-TDDs that touch this infra layer. Extract aggregate signal (count, growth rate, retention class, criticality), never enumerate individual tables/buckets/topics/keys. Deliberately skips most of the product feature catalog and the UI/UX pack — infra repos have no feature surface and no UI (narrow slices are still read for routing/capacity signal).

**Terminology note.** The sub-op is named `prd-tdd-infra` regardless of the on-disk prefix. Infra repos may live under `tech/infra-*` or `tech/devops-*` — the skill discovers whichever exists. If both prefixes are present, the operator picks the target explicitly.

### Argument

`/docs prd-tdd-infra <repo>::<mode>`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `<repo>` | yes | workspace-root-relative `tech/infra-*` \| `tech/devops-*` | Must be one of the discovered infra/devops repos. Role derived from suffix (`-postgresql`, `-redis`, `-minio`, `-meilisearch`, `-kafka`, `-nginx`, `-observability`). |
| `<mode>` | yes | `merge` \| `overwrite` | `merge` preserves §9 Alternatives & open questions verbatim (institutional memory). `overwrite` regenerates every section, including §9. |

**Full procedure:** [`skills/docs/SKILL.md#prd-tdd-infra`](../skills/docs/SKILL.md#prd-tdd-infra) — includes the per-role consumer-read table (postgresql / redis / minio / meilisearch / kafka / nginx / observability).

### Refusal conditions

Refuse and stop if:

- argument missing or `<repo>` not among the discovered infra/devops repos,
- `<repo>` is a `tech/backend-*` (use `prd-tdd-backend`, or `prd-tdd-library` for the shared library) or `tech/frontend-*` (use `prd-tdd-frontend`) or any other path,
- `<mode>` missing — stop and ask `merge` | `overwrite`,
- `<mode>` given but not `merge` | `overwrite`.

---

## prd-tdd-frontend

Author the v`<N>` `docs/v<N>/PRD-TDD.md` for one discovered `tech/frontend-*` repo — 26 sections — following [`TEMPLATE-frontend.md`](../skills/docs/TEMPLATE-frontend.md). Two canonical shapes: `landing` (SSG at `PUBLIC_DOMAIN` — public reader, rebuild-on-publish) and `dashboard` (SPA at `APP_DOMAIN` — every editorial + admin surface). Shape derived from repo-name suffix and confirmed against architecture §1.2 / §4. Cross-shape UI/UX reads are forbidden: dashboards never touch `landing/` mockups; landing repos never touch `system/` mockups.

### Argument

`/docs prd-tdd-frontend <repo>::<mode>`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `<repo>` | yes | workspace-root-relative `tech/frontend-*` | Must be one of the discovered frontend repos. Not hard-coded. |
| `<mode>` | yes | `merge` \| `overwrite` | `merge` preserves §22 Decision log verbatim; §26 Changelog prepends today's row. `overwrite` regenerates every section including §22. |

**Full procedure:** [`skills/docs/SKILL.md#prd-tdd-frontend`](../skills/docs/SKILL.md#prd-tdd-frontend) — includes the shape-specific consumer table, the surgical sibling-frontend read, and the §11 / §13 / §16 / §18 composition notes.

### Refusal conditions

Refuse and stop if:

- argument missing or `<repo>` not among the discovered frontend repos,
- `<repo>` is a `tech/backend-*` or a `tech/infra-*` / `tech/devops-*` or any other path,
- `<mode>` missing — stop and ask,
- `<mode>` given but not `merge` | `overwrite`.

---

Writes files only. Ship afterwards with [`/mr open <repo>`](mr.md) (or `/mr open current` from inside the target worktree).
