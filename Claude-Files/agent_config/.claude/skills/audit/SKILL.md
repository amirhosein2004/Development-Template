---
name: audit
description: |
  audit — read-only audits over the current-version documentation corpus and its implementation. First positional argument selects the sub-op: `corpus` | `code` | `tests`.

  - `corpus` — full documentation reconciliation: deep-read every engineering PRD-TDD + the platform architecture + the product feature catalog + every UI/UX spec, draft answers to every blocking open question from what the corpus itself provides, and report all inconsistencies — organized, severity-ranked, readable.
  - `code <repo|backend|frontend|infra|all>` — doc ↔ code and code ↔ code reconciliation: does each repo's implementation match its own PRD-TDD (topics, schema, endpoints, configuration, errors — section numbers resolved from the PRD-TDD template), the grep-able standards rules, the feature catalog scope, and the actual code on the other side of every cross-repo contract (library symbols, broker topic scripts, bucket/DB bootstrap, ingress upstreams, generated API clients).
  - `tests <repo|all>` — test-coverage reconciliation for the discovered backend + frontend repos: unfilled scaffolds vs real tests, every error-catalog code tested, every acceptance-criterion mapped, every consumed topic integration-tested (when the workspace uses a broker), banned test patterns, marker/coverage gates.

  All three write nothing, stage nothing, open no MR, show no diffs — chat report only.

  Use when the user asks to "audit the whole corpus", "find inconsistencies across the PRD-TDDs", "check the docs against each other", "answer the blocking questions from the docs", "check the code against the PRD-TDDs", "verify the implementation matches the docs", "find doc-code drift", "audit test coverage", "which error codes have no test", or invokes `/audit`.

  If the first arg is missing or not a known sub-op, stop and ask — never default. Every sub-op is strictly read-only: no Write/Edit, no stage/commit/push/MR/merge, no diff generation. Future audit-shaped operations land here as new sub-ops, not as new top-levels.
---

# audit — docs, code, tests

```
/audit corpus
/audit code   <repo|backend|frontend|infra|all>
/audit tests  <repo|all>
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `corpus` | [`## corpus`](#corpus) | Full read-only reconciliation audit of the current-version documentation corpus. |
| `code` | [`## code`](#code) | Doc ↔ code + code ↔ code reconciliation per repo class. |
| `tests` | [`## tests`](#tests) | Test-coverage reconciliation: scaffolds, error codes, acceptance criteria, banned patterns. |

If the first arg is missing or not one of the sub-ops above, stop and ask — never default. New audit-shaped behavior lands as a new `## <sub-op>` section in this file, not as a new top-level command.

## Hard rules — apply to every sub-op

- **Read-only, absolutely.** No `Write`, no `Edit`, no file creation of any kind — the report is chat output only. No stage, no commit, no push, no MR, no merge, no worktree, no diff generation. If the operator wants fixes applied, that is a separate, explicitly-requested follow-up pass.
- No derived onboarding-file references inside any report.
- **Section numbers are not hardcoded.** Every reference to a PRD-TDD section (ownership, topics, schema, endpoints, configuration, error catalog, acceptance criteria) is resolved by re-reading `[[docs]]/TEMPLATE-PRD-TDD.md` (and sibling `TEMPLATE-*.md` files) at audit time; the skill follows the templates, this file does not encode the numbers.
- **Project-specific invariants** (data-model rules like which content field is forbidden, locale/digit conventions, third-party providers for SMS/email/CDN, reserved-but-empty service slots, monetization deferrals) are read from the workspace's own architecture doc and hook policy; this audit **reports drift** against them without prescribing values.
- Stop after the report.

## Discovery (used by every sub-op)

Nothing about the read set is a constant — everything comes from disk each invocation.

- **Workspace root** is the directory the operator invoked from; it must contain `tech/`, `product/`, and at least one docs container that carries a `.claude/`. If it does not, refuse.
- **Engineering repos** are discovered with `ls -1d tech/*/` and filtered to those whose `<repo>/.git` exists. This is the sole enumeration source — there is no hardcoded repo list.
- **Repo classes** are inferred from directory-name prefix:
  - `tech/backend-*` → **backend service**. A repo named with a `-shared-*`, `-shared_*`, or `-lib` fragment is treated as a **library** for the purposes of `code`.
  - `tech/frontend-*` → **frontend**.
  - `tech/infra-*` OR `tech/devops-*` → **infra**. A workspace uses one prefix or the other; detect which and use it consistently. Never assume both.
- **Current version `<N>`** is the highest existing `v<N>` folder in the target's `docs/` tree. When resolving a workspace-wide artifact (feature catalog at `product/docs/features/v<N>/`, architecture, UI/UX pack), pick the highest `v<N>` present at that artifact's home. Both layouts for the architecture doc are accepted — `tech/docs/v<N>/project-architecture.md` and `tech/docs/project-architecture/v<N>.md`; probe both, use whichever exists.

## corpus

Full-corpus reconciliation audit. One invocation = one complete pass over the current-version documentation surface, ending in a single structured chat report. Takes no further arguments — the read set is fixed by discovery; scoping it would defeat the purpose (cross-document contradictions live between the files a narrower scope would drop).

`corpus` does contract-level reconciliation: does what service A promises match what service B consumes, does the catalog match what the docs ship, does the UI/UX pack cite real endpoints — and it drafts answers to every blocking open question from evidence already in the corpus.

### Read set (discovered from disk — never hardcoded)

1. Every engineering PRD-TDD, end to end: `tech/<repo>/docs/v<N>/PRD-TDD.md` for every discovered engineering repo (stubs noted as stubs, not skipped silently).
2. Platform architecture: `tech/docs/v<N>/project-architecture.md` (or `tech/docs/project-architecture/v<N>.md`) in full — the reconciliation baseline, including any locked-decisions / cross-cutting-decisions section the template defines.
3. Product feature catalog: `product/docs/features/v<N>/all-features.md` in full — both `[x]` and `[ ]` rows.
4. Every UI/UX area spec: `product/docs/uiux/v<N>/*/*.md` + the design-system doc under `product/docs/uiux/design-system/` (or the workspace's equivalent). HTML mockups are grep-scanned for concrete identifiers (endpoints, topic names, index names, copy claims), not read in full.
5. Engineering standards under `tech/docs/standards/` are consulted on demand when a finding needs a ruling, not bulk-read.

Corpus size typically exceeds one context — delegate extraction to parallel read-only subagents (one per repo group), each returning verbatim contract data: REST endpoints (method + path), broker topics produced/consumed (exact names + partition keys + DLQs when the workspace uses an async broker), DB tables, cache-key patterns, object-storage buckets, role registries, image/version pins, SLO numbers, cross-service claims quoted with section numbers, and the full open-questions table with blocking flags. Synthesis and cross-checking happen centrally — subagents extract, they never judge.

### What gets cross-checked

- **PRD-TDD ↔ PRD-TDD:** every cross-service claim against the owning document — topic names both sides of every producer/consumer pair, internal endpoints callers cite vs callees ship, mirror/audit/role-sync contracts, shared enums vs per-service registries, partition keys, reciprocal service-API-key seeds with no call path.
- **PRD-TDD ↔ architecture:** service scope, content-type set, consumer-flow counts, stack pins, feature→service map rows.
- **Catalog ↔ everything:** `[x]` rows with no owning surface; `[ ]` rows with shipped surfaces or in-scope prose anywhere (automatic 🔴 per workspace rule); totals arithmetic.
- **UI/UX ↔ backend:** every endpoint, topic, index, table, algorithm, or policy an area spec or mockup cites, against the owning PRD-TDD.
- **Internal per-document:** numbers that disagree between sections, key-shape drift, casing drift, stale open-question cross-references, claims that a sibling document "is a stub" when it is not.

### Blocking open questions

Collect every open-questions row across the corpus (whatever section number the doc uses). For each row flagged blocking: check whether the blocker still holds (the referenced document may have landed since), and draft an answer or a concrete recommendation **grounded in quoted corpus evidence** — never invented. Answering here means drafting the answer inside the report — never editing the question's home document. Non-blocking rows are listed in one summary line each, untouched.

### Report shape

Header `## /audit corpus — <YYYY-MM-DD>`, then:

1. **Blocking questions** — table per question: home doc + ID, status (already-resolved-by-landed-docs | needs-decision), drafted answer with evidence pointers.
2. **Inconsistencies** — grouped by severity: 🔴 cross-repo contract conflicts, 🟠 catalog ↔ docs, 🟡 UI/UX ↔ backend, 🔵 internal-per-doc (compressed bullets). Every finding names both documents + sections and quotes the shortest decisive fragment.
3. **Recommended actions** — ordered list the operator can hand to a follow-up pass (e.g. `[[docs]]`, `/uiux audit`, `[[mr]]`). Recommendations only — nothing is executed.

If the operator's session language is non-English, produce the prose in that language; identifiers, paths, and code stay verbatim. Stop after the report.

## code

Doc ↔ code and code ↔ code reconciliation. Answers one question per repo: **is the implementation exactly what the documents promise — no more, no less, no different?** Three finding kinds are kept apart: **GAP** (promised, not yet implemented — expected while a version is under construction, reported without alarm), **DRIFT** (implemented differently than promised — the dangerous kind), **CREEP** (implemented with no `[x]` catalog backing — automatic 🔴 per the workspace rule).

### Argument

`<scope>` — required, one of:

- `<repo-path>` — one discovered engineering repo (e.g. `tech/backend-auth`); validated by `<repo>/.git` existing.
- `backend` — every discovered `tech/backend-*` repo (including any `-shared-*` library).
- `frontend` — every discovered `tech/frontend-*` repo.
- `infra` — every discovered `tech/infra-*` (or `tech/devops-*`) repo, whichever prefix the workspace uses.
- `all` — every discovered engineering repo.

Refuse and stop if: `<scope>` missing or not one of the above; a single-repo scope names a repo whose `docs/v<N>/PRD-TDD.md` is missing or a stub (nothing to reconcile against — author it first). A repo with a PRD-TDD but no code yet is NOT a refusal — it reports as all-GAP.

### Read set

**Common rulers (every target repo):**

1. The repo's `docs/v<N>/PRD-TDD.md` — full, including its ownership, topics, schema, endpoints, configuration, and error-catalog sections (numbers per `[[docs]]/TEMPLATE-PRD-TDD.md`).
2. The canonical broker topic catalog when the workspace uses an async broker (e.g. `tech/infra-<broker>/docs/v<N>/PRD-TDD.md`), section per that repo's template — sole authority on topic names, partition keys, DLQs. Skipped when the workspace has no such broker.
3. Grep-able standards slices under `tech/docs/standards/`, on demand: naming (`infrastructure.md`), service layout (`microservice-layout.md`), coding vocabulary + calendar/locale rules (`coding.md`), exception + observability contract (`errors-and-observability.md`), single-auth-entry rule (`security-and-auth.md`), dependency version-lock (`ci-cd.md`). File names are workspace conventions; probe under `tech/docs/standards/` for whatever exists. Consulted per finding, never bulk-read.
4. `product/docs/features/v<N>/all-features.md` — full, both `[x]` and `[ ]` rows: `[x]` drives GAP detection, `[ ]` drives CREEP detection.

**Per repo class:**

- **Backend service:** the repo's full `src/` + `migrations/` (real route/table/topic/error-code inventory extracted from constants modules, DDL bands, routers) + any consumed shared-library trees (every `from <shared_lib>.X import Y` resolved against a real `(module, symbol, signature)` in the library repo) + the project manifest (`pyproject.toml` / `package.json` / equivalent — dependency pin shape + version-lock per the workspace's CI standard).
- **Shared library:** its own `src/` ↔ its PRD-TDD symbol table, plus every import the consuming services actually make (reverse check: exported-but-unimported symbols surfaced as informational).
- **Infra:** `docker/` + `scripts/` + config trees ↔ the consuming services' constants and platform-config modules — broker topic-creation scripts vs producer code topic names, object-storage bucket bootstrap vs adapter call sites, DB init roles/DBs vs service DSNs, ingress upstreams vs service URL prefixes (e.g. `/<service>/v<N>`), `.env.example` names vs consumer env schemas.
- **Frontend:** application source (`src/`) + build configs ↔ the bootstrap hard rules the workspace declares (fonts committed locally when the asset policy requires it, tokens bound to the design system's CSS custom properties, no browser-storage tokens if the workspace forbids it, logical CSS properties, copy-module discipline) + generated OpenAPI/typed clients ↔ the consumed backends' endpoints section (endpoint families present, no hand-typed response shapes).

**Not read:** UI/UX mockups and area specs (that is `corpus` + `/uiux audit` territory), the testing standard, the `tests/` trees (that is `tests`).

Delegate per-repo extraction to parallel read-only subagents (inventory only — routes, tables, topics, imports, env names, error codes as found in code); cross-checking happens centrally. Anti-hallucination: every finding must quote the file+line on the code side and the section on the doc side; a claim that cannot be grepped is dropped, not reported.

### Report shape

Header `## /audit code <scope> — <YYYY-MM-DD>`, then per repo: a three-part table — **DRIFT** (🔴 when cross-repo, 🟠 when own-doc), **CREEP** (🔴), **GAP** (ℹ️ — counts per PRD-TDD section, itemized only when asked or when a section is >50% missing) — followed by **standards violations** (🟡, file+line + rule). Totals line per repo and a workspace totals line in `all`/class scopes. Recommended follow-ups close the report (`/implement backend-service <repo>::gap`, `[[docs]] prd-tdd-* <repo>::merge`, `[[mr]]` — recommendations only). Stop after the report.

## tests

Test-coverage reconciliation. Answers one question per repo: **does the test suite actually cover what the code ships and what the PRD-TDD requires?** Complements `/implement backend-tests` / `frontend-tests` (which write tests) — this sub-op only measures and reports.

### Argument

`<scope>` — required, one of:

- `<repo-path>` — one discovered `tech/backend-*` or `tech/frontend-*` repo.
- `all` — every discovered test-bearing repo (backend + frontend), enumerated from disk.

Refuse and stop if: `<scope>` missing or invalid; the named repo is a `tech/infra-*` (or `tech/devops-*`) repo (no test surface — config layers are exercised by their consumers); the repo's `src/` is empty (nothing to cover — implement first); the repo's `docs/v<N>/PRD-TDD.md` is missing (the error-catalog and acceptance-criteria sections are the coverage rulers).

### Read set

1. `tech/docs/standards/testing.md` — full; the primary ruler (markers, tiers, banned patterns, coverage floors, anti-hallucination workflow).
2. The repo's PRD-TDD — **only** the topics section (every consumed topic → an integration test, when the workspace uses a broker), the error-catalog section (every `error_code` → at least one test asserting `status_code` AND `error_code`), and the acceptance-criteria section (every acceptance criterion → at least one happy-path test). Section numbers resolved from `[[docs]]/TEMPLATE-PRD-TDD.md`.
3. The repo's full `tests/` tree — real assertions vs unfilled scaffolds (`NotImplementedError` / `it.todo`), markers, fixtures, banned patterns (`time.sleep`, conditional logic in tests, snapshot-of-opaque-blob, message-equality assertions, vague names).
4. The repo's full `src/` — **symbol inventory only**: every handler / route / consumer handler / exported component listed, then matched both directions (untested symbol ✗, test targeting a nonexistent symbol ✗). The exact handler-naming convention is the workspace's — the audit follows what the coding standard declares, not a fixed prefix.
5. Test configuration: `pyproject.toml` `[tool.pytest.ini_options]` (asyncio_mode, strict-markers, coverage floor) / vitest + playwright configs (globals, environment, mock-service setup).

**Not read:** the feature catalog, UI/UX specs, sibling PRD-TDDs, non-testing standards — coverage is measured against the repo's own code and its own PRD-TDD, nothing else.

### Report shape

Header `## /audit tests <scope> — <YYYY-MM-DD>`, then per repo: **coverage matrix** (per entity: handler rows × happy/not-found/invalid/conflict/ownership/dependency columns — ✅ real test, ⬜ scaffold, ✗ absent), **error-code coverage** (error-catalog entries with no test, listed), **acceptance coverage** (acceptance-criteria bullets with no happy-path, listed), **consumer coverage** (topics-section entries with no integration test, when the workspace uses a broker), **violations** (banned patterns + config gaps, file+line). Totals per repo + workspace totals in `all`. Recommended follow-ups (`/implement backend-tests <repo>::gap`, `frontend-tests <repo>::gap`). Stop after the report.
