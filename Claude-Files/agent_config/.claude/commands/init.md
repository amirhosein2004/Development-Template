---
description: init — product | business | design-system | features | tech-architecture | tech-standards. Six-step project-birth pipeline; each sub-op is one previously-standalone init skill.
argument-hint: <product|business|design-system|features|tech-architecture|tech-standards> [<sub-op args>]
---

# init — project-birth pipeline

Single entry point for scaffolding a new workspace end-to-end. Routes by the first positional argument. Full step-by-step procedure lives in the SKILL twin at [`skills/init/SKILL.md`](../skills/init/SKILL.md).

## Pipeline order and inter-op dependencies

The six sub-ops run in this exact sequence for a new workspace. Each later sub-op reads what an earlier one wrote:

1. **`product`** — writes `product/docs/product.md`. Depends on: nothing (only requires `product/docs/_templates/product.md`).
2. **`business`** — depends on `product/docs/product.md` (for identity, positioning, segments, local-market dimension). Stages: `init` (scaffold) → `discover` → `audit` (loop) → `synthesize` (3 fan-out).
3. **`design-system`** — depends on `product/docs/product.md` **and** at least one dated `YYYY-MM-DD-feature-catalog.md` under `business/docs/competitor-analysis/` (produced by `/init business synthesize`).
4. **`features`** — depends on `product/docs/product.md` **and** at least one dated `YYYY-MM-DD-feature-catalog.md` under `business/docs/competitor-analysis/`.
5. **`tech-architecture`** — depends on `product/docs/product.md`, `product/docs/features/v<N>/all-features.md`, and `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md`. Report-only, no file.
6. **`tech-standards`** — depends on `product/docs/product.md` **and** an on-disk `tech/` directory populated by the user (guided by the `tech-architecture` report or by hand). No plan file bridges the two.

**Never merge stages.** Reviewing intermediate output is the whole point. Every sub-op is a discrete checkpoint the user reviews before running the next.

## Synopsis

```
/init product                                 [::merge|overwrite]
/init business [<init|discover|audit|synthesize|status>] [<target-slug>]
/init design-system                           [::merge|overwrite]
/init features [v<N>]                         [::merge|overwrite]
/init tech-architecture [v<N>]                # chat-only, no mode
/init tech-standards [v<N>]                   [::merge|overwrite]
```

**Optional `::mode`** on `product`, `design-system`, `features`, `tech-standards`. Absent → **safe default: refuse if any target file has real content (> 5 non-blank lines)**. Present:

- **`::merge`** — keep every user-authored line verbatim; fill only genuinely missing rows / sections / files. Never overwrites a value the user already set. Reports every skipped file plus every added-to file.
- **`::overwrite`** — wipe every target file and re-render from templates. Destructive; the user asked for it explicitly. Reports every replaced file.

`business` (multi-stage) and `tech-architecture` (chat-only, no writes) do not accept the mode arg.

| Sub-op | Anchor | One-liner |
|---|---|---|
| `product` | [`## product`](#product) | Interactive Q&A → writes `product/docs/product.md`. |
| `business` | [`## business`](#business) | `init | discover | audit | synthesize | status` — four-stage competitor-analysis pipeline. |
| `design-system` | [`## design-system`](#design-system) | Writes `product/docs/uiux/design-system/<PROJECT_ID>-design-system.{md,html}`. |
| `features` | [`## features`](#features) | Auto-classifies every catalog feature into `[x]` / `[ ]` for v<N>. |
| `tech-architecture` | [`## tech-architecture`](#tech-architecture) | Chat-only report picking monolith vs microservices + repo list (no file). |
| `tech-standards` | [`## tech-standards`](#tech-standards) | Renders `tech/docs/` from templates by walking on-disk `tech/`. |

## Router hard rules

- If the first arg is missing or not one of `product` | `business` | `design-system` | `features` | `tech-architecture` | `tech-standards`, **stop and ask** — never default.
- Each sub-op has its own argument contract (see per-sub-op sections below).
- Every sub-op writes files only — never stages, commits, pushes, or opens an MR. Exception: `tech-architecture` writes nothing (chat report is the deliverable).
- Load the **`init`** skill (`.claude/skills/init/SKILL.md`) verbatim before dispatching — it holds the operative details for every sub-op.

---

## product

Interactively scaffold `product/docs/product.md` — the **single source of truth** every downstream sub-op reads (`business`, `design-system`, `features`, `tech-architecture`, `tech-standards`). Only asks questions once per repo. Never overwrites an existing `product.md`.

### Argument

`/init product [::merge|overwrite]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `::<mode>` | no | `merge` \| `overwrite` | Absent = safe default (refuse on existing content). `merge` fills only missing sections; `overwrite` rewrites from template. |

**Full procedure:** [`skills/init/SKILL.md#product`](../skills/init/SKILL.md#product).

### Refusal conditions

Refuse and stop if:

- `product/docs/` does not exist → *"No `product/docs/` directory found. Create it first, then re-run."*
- `product/docs/_templates/product.md` is missing → *"Template missing: `product/docs/_templates/product.md`. Restore from the workspace scaffold."*
- `product/docs/product.md` already exists AND no `::mode` given → *"`product/docs/product.md` already exists. Re-run with `::merge` to fill only missing sections, `::overwrite` to rewrite from template, or edit the file directly."*
- `::mode` present but not `merge` | `overwrite` → refuse with the offending value named.

### Writes

- `product/docs/product.md` (from `product/docs/_templates/product.md`, placeholders filled per the Group A–H answers).

---

## business

Discover, audit, and synthesize competitors for a `business/docs` repo. Reads product identity + positioning from `product/docs/product.md` (the single source of truth). `AUDIT_PROMPT.md` is project-agnostic and never modified. Four discrete stages — do not merge them. Each stage produces a durable artifact reviewers can approve before the next runs.

### Argument

`/init business [<subcommand>] [<target-slug>]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `<subcommand>` | no | `init` \| `discover` \| `audit` \| `synthesize` \| `status` | Defaults to `status` when empty. |
| `<target-slug>` | no | competitor slug | Only meaningful for `audit <slug>` (re-audit / retry a single row). |

**Full procedure:** [`skills/init/SKILL.md#business`](../skills/init/SKILL.md#business) — includes the four-stage pipeline (`init` scaffold, `discover` sweep, `audit` per-competitor loop, `synthesize` 3-fan-out), verdict values, per-competitor loop, concurrency, and failure handling.

### Refusal conditions

Refuse and stop if:

- `product/docs/product.md` not found (required for every subcommand except `status`) → *"`product/docs/product.md` not found. Run `/init product` first."*
- For subcommands other than `init` / `status`: `business/docs/competitor-analysis/AUDIT_PROMPT.md` or any `_templates/{per-competitor-analysis,feature-catalog,comparison-and-ranking,roles,discovery}.md` missing → *"Template missing. Run `/init business init` first."*
- For `init`, every scaffold path already exists → *"Already scaffolded"*.
- For `synthesize`, fewer than 3 `analysis.md` files exist under the newest snapshot date.
- For `audit`, the newest discovery file has zero `verdict: audit` rows → halt and ask the user to review discovery.

### Writes

- `init` — `business/docs/competitor-analysis/AUDIT_PROMPT.md` + `_templates/*.md` (idempotent scaffold; never touches `business/docs/CLAUDE.md` or `README.md`).
- `discover` — `business/docs/competitor-analysis/<today-UTC>-discovery.md`.
- `audit` — `business/docs/competitor-analysis/<segment>/<slug>/<today-UTC>/analysis.md` (+ `raw/`, `screenshots/`) per competitor.
- `synthesize` — three dated files under `business/docs/competitor-analysis/`: `<date>-feature-catalog.md`, `<date>-comparison-and-ranking.md`, `<date>-roles.md`.
- `status` — no file; chat report only.

---

## design-system

Synthesize the project's canonical design system by grounding every decision in three sources — the templates (shape), `product.md` (positioning + locale), and the newest competitor snapshot (visual + behavioral evidence). Writes to `product/docs/uiux/design-system/`. Never overwrites an existing design system.

### Argument

`/init design-system [::merge|overwrite]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `::<mode>` | no | `merge` \| `overwrite` | Absent = refuse on existing content. `merge` fills only missing sections; `overwrite` rewrites both companion files from template. |

**Full procedure:** [`skills/init/SKILL.md#design-system`](../skills/init/SKILL.md#design-system) — includes the five-stage pipeline (ingest templates, ingest positioning+locale, ingest competitor evidence, synthesize decisions, write outputs), placeholder-fill rules, and traceability rules (`P` / `F` / `G` / `L`).

### Refusal conditions

Refuse and stop if:

- `product/docs/product.md` not found → *"`product/docs/product.md` not found. Run `/init product` first."*
- `product/docs/uiux/_templates/design-system-template.md` or `design-system-template.html` is missing.
- No file matching `business/docs/competitor-analysis/YYYY-MM-DD-feature-catalog.md` exists → *"No competitor snapshot found. Run `/init business discover` + `audit` + `synthesize` first."*
- `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md` already exists AND no `::mode` given → *"Design system already exists at `<path>`. Re-run with `::merge` to fill only missing sections, `::overwrite` to rewrite from template, or edit in place."*
- `::mode` present but not `merge` | `overwrite` → refuse with the offending value named.
- `product.md` positioning is missing critical anchors (no wedge, no locale) OR the newest snapshot has fewer than 3 scored `analysis.md` files → *"Insufficient input to synthesize a design system. Missing: <list>. Fix, then re-run."*

### Writes

- `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md`
- `product/docs/uiux/design-system/<PROJECT_ID>-design-system.html`

---

## features

Cut the feature scope for a single product version by grounding every `[x]` / `[ ]` decision in `product.md` (intent) + the newest competitor feature-catalog (candidate universe + priority). Never overwrites an existing `features/v<N>/all-features.md`.

### Argument

`/init features [v<N>] [::merge|overwrite]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `v<N>` | no | `v` + integer | Auto-detects when omitted: `v1` if no `features/v*` folder exists; otherwise `v<max+1>`. |
| `::<mode>` | no | `merge` \| `overwrite` | Absent = refuse on existing content. `merge` adds only rows for features not yet present; `overwrite` rewrites `all-features.md` from scratch. |

**Full procedure:** [`skills/init/SKILL.md#features`](../skills/init/SKILL.md#features) — includes the four-stage pipeline (ingest catalog, classify with rules R1–R11, cross-checks, write output), fuzzy-match rules, and placeholder-fill table.

### Refusal conditions

Refuse and stop if:

- `product/docs/product.md` not found → *"`product/docs/product.md` not found. Run `/init product` first."*
- `product/docs/features/_templates/all-features.md` missing → *"Template missing. Restore `product/docs/features/_templates/all-features.md`."*
- No file matching `business/docs/competitor-analysis/YYYY-MM-DD-feature-catalog.md` exists → *"No competitor feature catalog found. Run `/init business synthesize` first."*
- `product/docs/features/v<N>/all-features.md` already exists AND no `::mode` given → *"`v<N>` already selected at `<path>`. Re-run with `::merge` to add only new rows, `::overwrite` to rewrite from scratch, or bump the version."*
- `::mode` present but not `merge` | `overwrite` → refuse with the offending value named.
- `KEY_FEATURES` or `NON_FEATURES` in `product.md` are empty → *"`product.md` § 4 or § 5 is empty — auto-classification cannot run. Fill both, then re-run."*

### Writes

- `product/docs/features/v<N>/all-features.md` (from `_templates/all-features.md`, `[x]` / `[ ]` decisions applied, warnings tail appended).

---

## tech-architecture

Decide the platform architecture shape — binary monolith or microservices — and **REPORT** the concrete repo list (backend, frontend, infra) with a short scope line per repo. Reads `product.md` + `features/v<N>/all-features.md` + `design-system` + `business/users` (when present). **PRINTS TO CHAT ONLY — no file is ever written.** The report is the deliverable. Microservices is the default; monolith is the exception (pivot at 4 / 18; borderline totals of 3 or 4 lean microservices).

### Argument

`/init tech-architecture [v<N>]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `v<N>` | no | `v` + integer | Auto-detects the highest existing `product/docs/features/v<N>/` when omitted; must correspond to an existing `all-features.md`. |

**Full procedure:** [`skills/init/SKILL.md#tech-architecture`](../skills/init/SKILL.md#tech-architecture) — includes the five-stage pipeline (bucket by domain, score 9 signals, derive frontend split, derive infra footprint, print chat report), the twelve-bucket vocabulary, the binary-shape scoring table, and the chat-report format.

### Refusal conditions

Refuse and stop if:

- `product/docs/product.md` not found → *"`product/docs/product.md` not found. Run `/init product` first."*
- `product/docs/features/v<N>/all-features.md` not found for the resolved `<N>` → *"`product/docs/features/v<N>/all-features.md` not found. Run `/init features v<N>` first."*
- `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md` not found → *"Design system not found. Run `/init design-system` first."*
- No `v<N>` argument and no `product/docs/features/v*/` folder exists → *"No feature catalog found — run `/init features v1` first."*

### Writes

- **Nothing.** Report-only sub-op. Chat report is the entire deliverable — no file under `product/docs/tech-plan/` or anywhere else. The next sub-op (`/init tech-standards`) walks `tech/` directly and detects what the user created.

---

## tech-standards

Scaffold the whole `tech/docs/` tree (`project-architecture/v<N>.md` + 11 shared standards + one arch-shape layout doc + `CLAUDE.md` + `README.md`) for a new project by walking the existing `tech/` directory, auto-detecting `ARCH_SHAPE` (monolith vs microservices, binary) + repo list + infra flags, then rendering the templates at `Claude-Files/tech/docs/_templates/`. Reads `product/docs/product.md` for locale/calendar/digit rules. The on-disk `tech/` folder is the source of truth for shape and repo list — never reads `product/docs/tech-plan/`. Never overwrites a real file.

### Argument

`/init tech-standards [v<N>] [::merge|overwrite]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `v<N>` | no | `v` + integer | Auto-detects the highest existing `product/docs/features/v<N>/` when omitted. Version drives only the output filename `tech/docs/project-architecture/v<N>.md`; standards files are versionless. |
| `::<mode>` | no | `merge` \| `overwrite` | Absent = refuse on existing content > 5 non-blank lines. `merge` skips every populated file and renders only stubs / missing files; `overwrite` wipes every target and re-renders from templates. |

**Full procedure:** [`skills/init/SKILL.md#tech-standards`](../skills/init/SKILL.md#tech-standards) — includes ARCH_SHAPE detection rules, runtime-context / provider-resolution table, the six-stage pipeline (load templates, assemble context, render, write outputs, post-write sanity, chat summary), and the render order.

### Refusal conditions

Refuse and stop if:

- `product/docs/product.md` not found → *"`product/docs/product.md` not found. Run `/init product` first."*
- `tech/` directory does not exist.
- `tech/` matches neither shape pattern (exactly one `backend-monolithic/`, OR ≥ 2 `backend-<name>/` with at least one non-monolithic) → *"Cannot detect ARCH_SHAPE from `tech/`. Expected either a single `tech/backend-monolithic/` (monolith) or multiple `tech/backend-<name>/` folders (microservices). Create the repo folders first, then re-run."*
- Both `backend-monolithic/` AND another `backend-<name>/` are present → *"`tech/backend-monolithic/` co-exists with other `backend-*` folders. This workspace supports monolith OR microservices, not both. Remove one shape and re-run."*
- `Claude-Files/tech/docs/_templates/` missing or incomplete (< 12 `standards/*.md` + `project-architecture.md` + `CLAUDE.md` + `README.md`) → halt with the specific path.
- Any target file already exists under `tech/docs/` with real content (> 5 non-blank lines) AND no `::mode` given → refuse and list every blocking file path, with the hint *"Re-run with `::merge` to skip populated files and fill only stubs / missing paths, or `::overwrite` to rewrite every target from templates."*
- `::mode` present but not `merge` | `overwrite` → refuse with the offending value named.
- No `v<N>` argument and no `product/docs/features/v*/` folder exists → *"No feature catalog found — run `/init features v1` first."*
- Post-render: any rendered file still contains a `{{...}}` marker → refuse: *"Rendered `<path>` still has template markers. Aborting; delete and re-run."*

### Writes

- `tech/docs/CLAUDE.md`
- `tech/docs/README.md`
- `tech/docs/project-architecture/v<N>.md`
- `tech/docs/standards/{git,documentation,api-and-data-contracts,security-and-auth,frontend-layout,frontend,coding,errors-and-observability,testing,ci-cd,infrastructure}.md`
- Exactly one of `tech/docs/standards/microservice-layout.md` OR `tech/docs/standards/monolith-layout.md` (chosen by detected `ARCH_SHAPE`). **Never both.**

---

Every sub-op writes files only (except `tech-architecture`, which is chat-report only). Ship afterwards with [`/mr open <touched|current|...>`](mr.md).

---

## `::mode` behavior — merge vs overwrite

Applies to `product`, `design-system`, `features`, `tech-standards` (any sub-op that writes a target file this skill also owns the template for). `business` and `tech-architecture` do not accept `::mode`.

**No mode given (safe default):**
- If every target path is absent OR only holds a stub (≤ 5 non-blank lines) → render normally.
- If any target has real content → refuse and list the blocking paths. Never overwrite silently.

**`::merge`:**
- For each target path: probe its current content.
  - Absent OR stub (≤ 5 non-blank lines) → render the template into it.
  - Populated (> 5 non-blank lines) → parse the section / row / bullet structure; **for every heading / row / bullet the template declares that is NOT present in the current file, insert it in the template-declared order**; for everything already present, keep the user's version verbatim (no reformatting, no wording change, no reordering).
  - The one exception is `features`: `merge` adds only new `[x]` / `[ ]` rows for features not already listed; existing rows keep their state.
- Never deletes a line the user wrote. Never rewrites a value the user already set.
- Report each target: `merged (<N> additions) <path>` OR `skipped (already complete) <path>` OR `created <path>`.

**`::overwrite`:**
- For each target path: render from template as if the file did not exist. Every prior line is lost.
- The user asked explicitly; skill does not second-guess. Only refusal that still applies is the post-render `{{marker}}` check.
- Report each target: `overwrote <path>` OR `created <path>`.

Every mode preserves post-render sanity checks (no template markers left, minimum-line-count warnings). Every mode still writes files only — no stage, no commit, no MR.
