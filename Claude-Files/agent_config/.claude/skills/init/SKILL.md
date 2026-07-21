---
name: init
description: |
  Single entry point for the six-step project-birth pipeline. First positional argument is `<product|business|design-system|features|tech-architecture|tech-standards>`; each sub-op corresponds to a previously-standalone init skill. The six sub-ops run in a fixed order — `product → business → design-system → features → tech-architecture → tech-standards` — and each later sub-op reads what an earlier one wrote.

  - `product` — interactively scaffold `product/docs/product.md` (identity, positioning, features, non-features, market). Runs FIRST — the single source of truth every downstream sub-op reads.
  - `business` — four-stage competitor-analysis pipeline (`init | discover | audit | synthesize`) plus a read-only `status` (default). Reads product identity, positioning, segments, and local-market dimension from `product/docs/product.md`; `AUDIT_PROMPT.md` is project-agnostic and never modified. Never touches `business/docs/CLAUDE.md` or `README.md`.
  - `design-system` — synthesize the product's canonical design system from three inputs — the design-system templates at `product/docs/uiux/_templates/`, `product/docs/product.md`, and the newest competitor snapshot under `business/docs/competitor-analysis/`. Writes `<PROJECT_ID>-design-system.{md,html}` under `product/docs/uiux/design-system/`.
  - `features` — auto-classify every feature from the newest competitor `YYYY-MM-DD-feature-catalog.md` into `[x]` (in scope) / `[ ]` (deferred) for a given product version, using `product.md` as the intent oracle. Writes `product/docs/features/v<N>/all-features.md` with rationale-traced selections.
  - `tech-architecture` — pick the binary architecture shape (monolith OR microservices, **microservices default**) from the version's `[x]` feature set + `product.md` + design-system, and REPORT the concrete repo list (backend, frontend, infra) with a short scope line per repo. PRINTS TO CHAT ONLY — no file is ever written; the report is the deliverable.
  - `tech-standards` — walk the on-disk `tech/` directory to auto-detect `ARCH_SHAPE` (binary: monolith vs microservices) + repo list + `HAS_*` infra flags, read `product/docs/product.md` for locale/calendar/digit rules, then render every template under `Claude-Files/tech/docs/_templates/` into `tech/docs/` (`project-architecture/v<N>.md` + 11 shared standards + one arch-shape layout doc + `CLAUDE.md` + `README.md`). Does NOT read `product/docs/tech-plan/` — that path is intentionally absent from this workflow; the on-disk `tech/` folder is the source of truth.

  Use when the user asks to "scaffold product.md", "write the product identity file", "collect product identity + positioning", "run product-init", or invokes `/init product`.
  Use when the user asks to "run competitor analysis", "discover competitors", "audit a competitor", "synthesize the competitor snapshot", "check business-audit status", or invokes `/init business`.
  Use when the user asks to "generate the design system", "synthesize design tokens from the competitor snapshot", "produce the canonical design system", or invokes `/init design-system`.
  Use when the user asks to "cut the v<N> feature scope", "select which features ship in this version", "auto-classify the feature catalog", or invokes `/init features`.
  Use when the user asks to "pick monolith or microservices", "decide the architecture shape", "list the engineering repos", or invokes `/init tech-architecture`.
  Use when the user asks to "scaffold tech/docs", "render the standards templates", "bootstrap the tech-docs tree", or invokes `/init tech-standards`.

  If the first arg is missing or not one of the six, stop and ask — never default. Every sub-op writes files only (no stage/commit/push/MR) except `tech-architecture` which writes nothing (chat report only).
---

# init — project-birth pipeline

Single entry point for scaffolding a new workspace end-to-end. Routes by the first positional argument.

```
/init product
/init business [<init|discover|audit|synthesize|status>] [<target-slug>]
/init design-system
/init features [v<N>]
/init tech-architecture [v<N>]
/init tech-standards [v<N>]
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `product` | [`## product`](#product) | Interactive Q&A → writes `product/docs/product.md`. |
| `business` | [`## business`](#business) | `init | discover | audit | synthesize | status` — four-stage competitor-analysis pipeline. |
| `design-system` | [`## design-system`](#design-system) | Writes `product/docs/uiux/design-system/<PROJECT_ID>-design-system.{md,html}`. |
| `features` | [`## features`](#features) | Auto-classifies every catalog feature into `[x]` / `[ ]` for v<N>. |
| `tech-architecture` | [`## tech-architecture`](#tech-architecture) | Chat-only report picking monolith vs microservices + repo list (no file). |
| `tech-standards` | [`## tech-standards`](#tech-standards) | Renders `tech/docs/` from templates by walking on-disk `tech/`. |

If the first arg is missing or not one of `product` | `business` | `design-system` | `features` | `tech-architecture` | `tech-standards`, stop and ask — never default.

## Pipeline order and inter-op dependencies

The six sub-ops run in this exact sequence for a new workspace. Each later sub-op reads what an earlier one wrote:

1. **`product`** — writes `product/docs/product.md`. Depends on: nothing (only requires `product/docs/_templates/product.md`).
2. **`business`** — depends on `product/docs/product.md` (for identity, positioning, segments, local-market dimension). Stages: `init` (scaffold) → `discover` → `audit` (loop) → `synthesize` (3 fan-out).
3. **`design-system`** — depends on `product/docs/product.md` **and** at least one dated `YYYY-MM-DD-feature-catalog.md` under `business/docs/competitor-analysis/` (produced by `/init business synthesize`).
4. **`features`** — depends on `product/docs/product.md` **and** at least one dated `YYYY-MM-DD-feature-catalog.md` under `business/docs/competitor-analysis/`.
5. **`tech-architecture`** — depends on `product/docs/product.md`, `product/docs/features/v<N>/all-features.md`, and `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md`.
6. **`tech-standards`** — depends on `product/docs/product.md` **and** an on-disk `tech/` directory populated by the user (guided by the `tech-architecture` report or by hand). No plan file bridges the two.

**Never merge stages.** Reviewing intermediate output is the whole point. Every sub-op is a discrete checkpoint the user reviews before running the next.

## Workspace expectations

- `<workspace-root>/product/docs/` — identity, feature scope, UI/UX pack, design system.
- `<workspace-root>/business/docs/` — competitor-analysis snapshots, brand assets (opt-in), legal documents (opt-in).
- `<workspace-root>/tech/` — engineering repos (created by the user after `tech-architecture`). `tech/docs/` — cross-repo standards + platform architecture (populated by `tech-standards`).
- `<workspace-root>/Claude-Files/tech/docs/_templates/` — templates that `tech-standards` renders.

**Never commit, push, stage, or merge.** Every sub-op writes files only (or, in the case of `tech-architecture`, writes nothing). The user reviews the working tree and commits themselves.

---

## product

This sub-op drives what was previously `/product-init`. It produces `product/docs/product.md` — the **single source of truth** every downstream sub-op reads (`business`, `design-system`, `features`, `tech-architecture`, `tech-standards`).

Only asks questions once per repo. Never overwrites an existing `product.md` unless the user passes `::overwrite` explicitly.

**Optional `::mode`** on the invocation — see [`## Mode behavior`](#mode-behavior-merge-vs-overwrite) at the bottom of this skill for the shared semantics. Applies to `product`, `design-system`, `features`, `tech-standards`.

### Preconditions

- `product/docs/` exists. If not found — halt: *"No `product/docs/` directory found. Create it first, then re-run."*
- `product/docs/_templates/product.md` exists. If missing — halt: *"Template missing: `product/docs/_templates/product.md`. Restore from the workspace scaffold."*
- `product/docs/product.md` does NOT exist OR `::mode` is set. If the file exists AND no `::mode` given — halt: *"`product/docs/product.md` already exists. Re-run with `::merge` to fill only missing sections, `::overwrite` to rewrite from template, or edit directly."*
- `::mode` present but not `merge` | `overwrite` — refuse with the offending value named.

If any precondition fails, print the exact message and exit.

### Questions (ask in this exact order, one AskUserQuestion turn per group)

**Group A — Identity**

1. **Product name?** (short, human-readable — e.g. "GotoRole", "Soradis")
2. **Short slug?** (kebab-case used in paths — e.g. "gotorole")
3. **One-line pitch?** (≤ 15 words. What the product is, in one sentence.)

**Group B — Problem & buyer**

4. **Target user / buyer?** (who pays, who uses — one line each if different)
5. **Problem statement?** (2–3 sentences. What pain, why it matters, what today's alternative fails at.)

**Group C — Value proposition**

6. **Wedge?** (the single differentiator that wins deals — one sentence)
7. **Value proposition?** (2–3 sentences. Why buyer picks {{PROJECT_NAME}} over alternatives.)

**Group D — Features**

8. **Key features (concrete, shipped)?** (3–8 bullets. What the product *does*. No roadmap items.)
9. **Non-features (explicit anti-scope)?** (2–5 bullets. What the product *does not* do — deliberately.)

**Group E — Market**

10. **Market geography?** — options: `Iran` / `MENA` / `global` / `Iran + global reference`.
11. **Product language(s)?** — options: `Farsi only (RTL)` / `bilingual Farsi+English` / `English only` / `other`.
12. **Segment slugs for competitor analysis?** — comma-separated. Default
    `iranian-<domain>, global-<domain>, regional-mena, adjacent-<space>`
    (replace `<domain>` / `<space>` with the actual category).
13. **Local-market dimension name (audit dimension 18)?** — Default
    `Iran-specific` for Iran-market products; suggest `MENA-specific` /
    `LATAM-specific` / `N/A` otherwise.

**Group F — Business model (optional; user may skip any)**

14. **Pricing model?** (e.g. per-seat, usage-based, freemium, one-time)
15. **Revenue streams?**
16. **Willingness-to-pay signal?** (which features sit behind which plan)

**Group G — Metrics (optional; user may skip any)**

17. **North-star metric?**
18. **Key KPIs?**

**Group H — Positioning (the final anchor; ask LAST, after A–G)**

19. **Positioning paragraph** — one paragraph (2–4 sentences) combining:
    - domain nouns (what class of product)
    - buyer
    - geography / language
    - wedge
    - anti-scope
    Do NOT accept a one-liner. If vague ("a great CRM"), reprompt with an
    example and ask again. This paragraph is copied **verbatim** (no paraphrase)
    into every downstream file that references positioning; a bad paragraph
    poisons every downstream score.

### Confirmation

Before writing anything, echo back:

- The filled positioning paragraph.
- The feature list + non-feature list.
- The segment slugs.

Ask: *"Write these values to `product/docs/product.md`? (yes/edit)"*. Only proceed on `yes`.

### Fill

Copy `product/docs/_templates/product.md` to `product/docs/product.md`, then
replace every placeholder:

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | Q1 |
| `{{PROJECT_ID}}` | Q2 |
| `{{ONE_LINE_PITCH}}` | Q3 |
| `{{OVERVIEW_PARAGRAPH}}` | derived: Q3 + Q7 first sentence |
| `{{TARGET_USER}}` | Q4 |
| `{{PROBLEM_STATEMENT}}` | Q5 |
| `{{WEDGE}}` | Q6 |
| `{{VALUE_PROP}}` | Q7 |
| `{{FEATURE_1..N}}` | Q8 (one bullet per feature; remove unused bullet lines) |
| `{{NON_FEATURE_1..N}}` | Q9 |
| `{{MARKET_GEOGRAPHY}}` | Q10 |
| `{{PRODUCT_LANGUAGES}}` | Q11 |
| `{{SEGMENT_SLUGS}}` | Q12 |
| `{{LOCAL_MARKET_DIMENSION}}` | Q13 |
| `{{LOCALE_RULES}}` | derived from Q11 (Farsi-only → RTL + Persian numerals + self-hosted fonts rule; English-only → strip the block; bilingual → both) |
| `{{PRICING_MODEL}}` | Q14 (or `N/A — not yet defined`) |
| `{{REVENUE_STREAMS}}` | Q15 (or `N/A — not yet defined`) |
| `{{WTP_SIGNAL}}` | Q16 (or `N/A — not yet defined`) |
| `{{NORTH_STAR_METRIC}}` | Q17 (or `N/A — not yet defined`) |
| `{{KEY_KPIS}}` | Q18 (or `N/A — not yet defined`) |
| `{{POSITIONING}}` | Q19 (verbatim paragraph) |
| `{{YYYY-MM-DD}}` | today's UTC date |

Delete unused `{{FEATURE_N}}` / `{{NON_FEATURE_N}}` placeholder lines.

### Do NOT touch companion files

**Never** read, write, refresh, or scaffold `product/docs/CLAUDE.md` or
`product/docs/README.md`. Those files are hand-authored per project and
carry project-specific context (repo map, hard rules, workflow) that this
sub-op cannot infer. The user maintains them manually.

### Do NOT commit

Write files only. Do not `git add`, `git commit`, `git push`, or open an MR.
The user reviews the diff and commits themselves.

### Hard rules

- **Never overwrite** an existing `product.md`. Halt instead.
- **Never touch `product/docs/CLAUDE.md` or `product/docs/README.md`.** Those are hand-authored per project.
- **Never paraphrase** the positioning paragraph. Copy verbatim from Q19.
- **Never merge stages** — do not offer to also run `/init business init` in
  the same turn. Product identity is reviewed before downstream files derive
  from it.
- **Never commit** on behalf of the user.
- **If the user says "skip"** on any optional question (Groups F, G), write
  `N/A — not yet defined` into the corresponding placeholder. Do NOT invent
  values.

---

## business

This sub-op drives what was previously `/business-audit`. It assumes:

- **`product/docs/product.md` exists** — the single source of truth for product identity, positioning, features, non-features, and market context. Produced by `/init product`.
- **`business/docs/` scaffold present** — `CLAUDE.md`, `README.md`, `competitor-analysis/AUDIT_PROMPT.md`, and `competitor-analysis/_templates/{per-competitor-analysis,feature-catalog,comparison-and-ranking,roles,discovery}.md`.

The pipeline is deliberately **four discrete stages** — do not merge them. Each stage produces a durable artifact reviewers can approve before the next stage runs.

```
init  →  discover  →  audit (loop)  →  synthesize (3 fan-out)
```

### Subcommands

| Subcommand | What it does |
|---|---|
| `init` | Silent scaffold. Copy `AUDIT_PROMPT.md` + `_templates/*.md` into `business/docs/competitor-analysis/` if missing. **Never touches `business/docs/CLAUDE.md` or `README.md`** (hand-authored per project). |
| `discover` | Run **Discovery mode** of `AUDIT_PROMPT.md`. Sweep the four channels. Write `business/docs/competitor-analysis/YYYY-MM-DD-discovery.md`. Stop. |
| `audit` | Run **Per-competitor audit** for every row with `verdict: audit` in the newest discovery file. If a slug is passed (`/init business audit <slug>`), audit only that one. |
| `synthesize` | Run all three synthesizers (`feature-catalog`, `comparison-and-ranking`, `roles`) against the newest snapshot date, in that order. Refuses if fewer than 3 `analysis.md` files exist under that date. |
| `status` | Read-only. Report: `product.md` present, scaffold state (AUDIT_PROMPT + `_templates/`), current snapshot date, count of audits done vs. scheduled, syntheses present. |

Default subcommand when the second arg is empty: `status`.

### Dispatch validation

1. Validate `product/docs/product.md`:
   - Required for every subcommand except `status`.
   - If missing, stop and print: *"`product/docs/product.md` not found. Run `/init product` first."*
2. Validate the business/docs repo:
   - For `init` — this sub-op scaffolds `AUDIT_PROMPT.md` and `_templates/*.md` from the workspace scaffold when missing. **Never touches `business/docs/CLAUDE.md` or `README.md`** — those are hand-authored per project.
   - For every other subcommand — `business/docs/competitor-analysis/AUDIT_PROMPT.md` and `business/docs/competitor-analysis/_templates/{per-competitor-analysis,feature-catalog,comparison-and-ranking,roles,discovery}.md` must exist. If any is missing, stop and print: *"Template missing. Run `/init business init` first."*
3. For `init`, if every scaffold path already exists, print *"Already scaffolded"* and exit.
4. **Never commit, push, stage, or merge.** Every subcommand only writes files. The user reviews the working tree and commits themselves.

### Runtime context (read once per invocation)

At the start of every subcommand except `status`, load these values from `product/docs/product.md`:

| Value | Source in `product.md` |
|---|---|
| `PROJECT_NAME` | § 1 Overview → `Name:` line |
| `PROJECT_ID` | § 1 Overview → `Slug:` line |
| `POSITIONING` | § 9 Positioning paragraph (verbatim, no paraphrase) |
| `SEGMENTS` | § 6 Market context → `Segment slugs` line |
| `LOCAL_MARKET_DIMENSION` | § 6 Market context → `Local-market dimension name` line |
| `LOCALE_RULES` | § 6 Market context → `Locale rules` line |

If `product/docs/product.md` is missing, halt and print: *"`product/docs/product.md` not found. Run `/init product` first."*

### Stage 1 — `init`

Scaffold the competitor-analysis spec + templates into the current repo if they are missing. **Never touch `business/docs/CLAUDE.md` or `business/docs/README.md`** — those are hand-authored per project.

#### Precondition

- `product/docs/product.md` exists (see runtime context above).

#### Scaffolding

Materialize these paths in the current repo if missing. **Never overwrite an existing file.** Report per file: `created <path>` or `skipped <path> (exists)`.

| Path (target) | Source (copy from workspace scaffold) |
|---|---|
| `business/docs/competitor-analysis/AUDIT_PROMPT.md` | scaffold `business/docs/competitor-analysis/AUDIT_PROMPT.md` (project-agnostic; lives inside `competitor-analysis/` since it drives that folder only; never modified after scaffold) |
| `business/docs/competitor-analysis/_templates/per-competitor-analysis.md` | same |
| `business/docs/competitor-analysis/_templates/feature-catalog.md` | same |
| `business/docs/competitor-analysis/_templates/comparison-and-ranking.md` | same |
| `business/docs/competitor-analysis/_templates/roles.md` | same |
| `business/docs/competitor-analysis/_templates/discovery.md` | same |

**Do NOT touch:**

- `business/docs/CLAUDE.md` — hand-authored. Do not create, fill, refresh, or delete.
- `business/docs/README.md` — hand-authored. Do not create, fill, refresh, or delete.
- `business/docs/competitor-analysis/AUDIT_PROMPT.md` after scaffold — project-agnostic. If a `{{...}}` placeholder somehow appears there, restore it from the scaffold; do not fill.
- Files under `business/docs/competitor-analysis/_templates/` — those keep placeholders forever, they are the copy-source for future artifacts.

#### Idempotence

If every scaffold path already exists, print *"Already scaffolded"* and exit. Do not rewrite.

#### Do NOT commit

Write files only. Do not `git add`, `git commit`, `git push`, or open an MR. The user reviews the diff and commits themselves.

### Stage 2 — `discover`

Run the **Discovery mode** section of `AUDIT_PROMPT.md`. Do NOT ask the user for competitors — the discovery is the audit's job.

#### Steps

1. Load runtime context from `product/docs/product.md` (see top of this sub-op).
2. Extract the five search anchors (domain nouns, buyer, geography/language, wedge, anti-scope) directly from `product.md § 9 POSITIONING` (plus `§ 5 Non-features` for anti-scope). If any anchor is unrecoverable, halt and tell the user the positioning paragraph needs sharpening in `product.md`.
3. Sweep the four channels — **all four, even if one seems empty**:
   - **Local direct** — same-geography search per `product.md § 6`.
   - **Global reference** — 3–5 category leaders worldwide via WebSearch.
   - **Regional peers** — MENA / Turkey / SE Asia / LATAM analogues if geography is regional.
   - **Adjacent substitutes** — non-obvious tools the buyer already uses (Notion for CMS, WhatsApp+sheet for CRM, Google Docs for editor).
4. Write `business/docs/competitor-analysis/<today-UTC>-discovery.md` by copying `_templates/discovery.md` and filling every row. Every candidate needs: `slug`, `segment`, `url`, one-line why-it-matters, `verdict`.
5. Cap at **10–30 competitors**. Under 10 → thin snapshot; over 30 → move overflow to `verdict: skip (deferred)`.

#### Verdict values

- `audit` — full analysis this snapshot.
- `stub` — origin unreachable / parked / DNS-suspended / geo-blocked. Listed in comparison-and-ranking exclusion table, no analysis.
- `skip` — out of scope; note the reason.

#### Do NOT commit

Write the discovery file only. No `git` calls. The user reviews and commits.

#### Stop after this stage

Do NOT proceed to audit. The user must eyeball the discovery output first — this is the single point where a wrong scope is cheap to fix. Print: *"Discovery written to `<path>`. Review the table, then run `/init business audit`."*

### Stage 3 — `audit`

Loop the **Per-competitor audit** section of `AUDIT_PROMPT.md` over every row with `verdict: audit` in the newest discovery file.

#### Modes

- `/init business audit` — every unaudited row in the newest discovery file.
- `/init business audit <slug>` — only that one competitor. Useful for re-audits and for retrying a failed row.

#### Per-competitor loop

For each competitor:

1. Compute `TARGET = business/docs/competitor-analysis/<segment>/<slug>/` and `URL` from the discovery row.
2. If `<TARGET>/<today-UTC>/analysis.md` already exists, skip (never overwrite; the correct action is a new dated folder on a future run).
3. Copy `_templates/per-competitor-analysis.md` to `<TARGET>/<today-UTC>/analysis.md`.
4. Follow the **Per-competitor audit** dimensions verbatim from `AUDIT_PROMPT.md`. Every `PRESENT` bullet needs `EVIDENCE`; unverified observations are marked 🔴 and excluded from synthesis. Dimension 18's name is `LOCAL_MARKET_DIMENSION` from `product.md § 6`.
5. Fetch the raw artifacts to `<TARGET>/<today-UTC>/raw/`: `headers.txt` (`curl -I`), `home.html` (first 200 KB), `robots.txt`, `sitemap.xml`, `lighthouse.json` if a headless browser is available.
6. Capture 6 screenshots to `<TARGET>/<today-UTC>/screenshots/` via Playwright: hero, nav-open, a services page, careers, contact, mobile-hero. If Playwright is unavailable, note *"screenshot tooling unavailable"* in the audit's summary section and continue.

#### Concurrency

Run per-competitor audits **in parallel** where possible (each is independent). Serial is acceptable but slow — for >5 competitors prefer batches of 3–5 concurrent Agent calls.

#### Failure handling

- Network-unreachable → downgrade the row to `verdict: stub` in the discovery file (edit in place) and write a stub `analysis.md` recording why. Never leave a row silently unaudited.
- Timeout / partial fetch → mark unchecked dimensions `SCORE: N/A` with reason.

#### Do NOT commit

Write audit files and stub downgrades only. No `git` calls. The user reviews the batch and commits.

### Stage 4 — `synthesize`

Run three synthesizers against the newest snapshot date, in this order (each depends on the last):

1. **`feature-catalog`** — read every `analysis.md` under `business/docs/competitor-analysis/*/*/YYYY-MM-DD/`, extract every `PRESENT` bullet, dedupe, categorize by the 18 dimensions, group by segment within each dimension, score 1–10 by strategic priority to `PROJECT_NAME`. Anchor every score against `POSITIONING` (loaded from `product.md § 9`). Copy `_templates/feature-catalog.md` → `<YYYY-MM-DD>-feature-catalog.md`.
2. **`comparison-and-ranking`** — read the same source set, roll up the 0–3 scores into the 18-column matrix, category averages, per-dimension top-3 (🥇🥈🥉), and (starting on the second snapshot) the delta vs the prior snapshot. Copy `_templates/comparison-and-ranking.md` → `<YYYY-MM-DD>-comparison-and-ranking.md`.
3. **`roles`** — extract every user role / persona / audience competitors **explicitly model** (dedicated portal, nav bucket, form intent, mega-menu tab). Cite the competitor + concrete artifact for each. Cross-reference feature-catalog sections. Copy `_templates/roles.md` → `<YYYY-MM-DD>-roles.md`.

#### Preconditions

- ≥3 `analysis.md` files under the snapshot date. Refuse otherwise.
- Every audit must be either complete or a stub — no half-audited rows.

#### Concurrency

Run all three synthesizers **in parallel** via Agent — they read the same source set and produce independent outputs.

#### Do NOT commit

Write the three synthesis files only. No `git` calls. After finishing, print a two-line takeaway per file (e.g. *"3 competitors score >40; feature catalog has 8 wedge picks; 12 roles surfaced"*) so the user knows what landed before reviewing the diff.

### Stage 0 — `status` (default when no subcommand given)

Read-only report, one screen. Do not touch any files.

- **`product.md` present:** ✅ / ❌ (if ❌, next action is `/init product`).
- **Scaffold state:** `scaffolded` / `pending` (checks `AUDIT_PROMPT.md` + `_templates/*.md` exist).
- **Newest snapshot date:** date-of-newest-file under `business/docs/competitor-analysis/YYYY-MM-DD-*.md`.
- **Discovery coverage:** total / audited / pending / stub / skipped.
- **Synthesis presence:** `feature-catalog`: ✅/❌ · `comparison-and-ranking`: ✅/❌ · `roles`: ✅/❌.
- **Next recommended action:** the earliest incomplete stage.

### Hard rules

- **Never skip a stage.** `product` → `init` → `discover` → `audit` → `synthesize`. Reviewing intermediate output is the whole point.
- **Never overwrite a past-dated file.** A re-audit is a new dated folder; a re-synthesis is a new dated file.
- **Never modify `AUDIT_PROMPT.md`.** It is project-agnostic and loads context from `product.md` at runtime.
- **Never edit `_templates/`.** Those are the copy-source; they always keep the placeholders.
- **Never invent an evidence URL.** If the source can't be fetched, mark 🔴 and continue.
- **Never headline multi-language** or any feature not named in `product.md § 9 POSITIONING` as the wedge. Scoring drift starts here.
- **Never commit, stage, push, or merge.** Every subcommand writes files only. `git add` / `git commit` / `git push` / `glab mr` are all forbidden — the user commits themselves.
- **No references to `CLAUDE.md` / `README.md`** from inside content files under `competitor-analysis/`.
- **Never touch `business/docs/CLAUDE.md` or `business/docs/README.md`.** Those are hand-authored per project. Positioning edits live in `product.md § 9`, which every downstream step reads at runtime.

### Ask-vs-fill policy

- **`init`** — silent scaffold only. No questions, no confirmation. If files exist, skip.
- **`discover` / `audit` / `synthesize`** — silent. The user already provided anchors during `/init product`; asking mid-pipeline creates friction and re-drift.
- **Exception** — if the newest discovery file has zero `verdict: audit` rows, halt `audit` and ask the user to review discovery rather than proceeding to a no-op audit.

---

## design-system

This sub-op drives what was previously `/design-system-init`. It produces the
project's canonical design system by grounding every decision in three
sources — the templates (shape), `product.md` (positioning + locale), and
the newest competitor snapshot (visual + behavioral evidence).

Never overwrites an existing design system. Never commits.

### Preconditions

Halt immediately if any is unmet:

- `product/docs/product.md` exists. If missing → stop: *"`product/docs/product.md` not found. Run `/init product` first."*
- `product/docs/uiux/_templates/design-system-template.md` exists.
- `product/docs/uiux/_templates/design-system-template.html` exists.
- ≥ 1 file matching `business/docs/competitor-analysis/YYYY-MM-DD-feature-catalog.md` exists. If missing → stop: *"No competitor snapshot found. Run `/init business discover` + `audit` + `synthesize` first."*
- Target files do NOT exist OR `::mode` is set:
  - `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md`
  - `product/docs/uiux/design-system/<PROJECT_ID>-design-system.html`

  If the `.md` target exists AND no `::mode` given → stop: *"Design system already exists at `<path>`. Re-run with `::merge` to fill only missing sections, `::overwrite` to rewrite from template, or edit in place."*
- `::mode` present but not `merge` | `overwrite` — refuse with the offending value named.

**Optional `::mode`** — see [`## Mode behavior`](#mode-behavior-merge-vs-overwrite) at the bottom of this skill for the shared semantics.

### Runtime context (load once)

From `product/docs/product.md`:

| Value | Source in `product.md` |
|---|---|
| `PROJECT_NAME` | § 1 Overview → `Name:` |
| `PROJECT_ID` | § 1 Overview → `Slug:` |
| `POSITIONING` | § 9 Positioning paragraph (verbatim) |
| `WEDGE` | § 3 Value proposition & wedge |
| `KEY_FEATURES` | § 4 Key features |
| `NON_FEATURES` | § 5 Non-features |
| `MARKET_GEOGRAPHY` | § 6 |
| `PRODUCT_LANGUAGES` | § 6 |
| `LOCAL_MARKET_DIMENSION` | § 6 |
| `LOCALE_RULES` | § 6 |

From the newest snapshot (resolve `SNAPSHOT_DATE` = latest date in
`business/docs/competitor-analysis/YYYY-MM-DD-*.md`):

| Value | Source |
|---|---|
| Feature catalog | `<SNAPSHOT_DATE>-feature-catalog.md` |
| Comparison ranking | `<SNAPSHOT_DATE>-comparison-and-ranking.md` |
| Roles | `<SNAPSHOT_DATE>-roles.md` |
| Per-competitor audits | every `business/docs/competitor-analysis/*/*/<SNAPSHOT_DATE>/analysis.md` |
| Screenshots | every `business/docs/competitor-analysis/*/*/<SNAPSHOT_DATE>/screenshots/*.png` |
| Raw HTML | every `business/docs/competitor-analysis/*/*/<SNAPSHOT_DATE>/raw/home.html` |
| Raw headers | every `business/docs/competitor-analysis/*/*/<SNAPSHOT_DATE>/raw/headers.txt` |
| Lighthouse | every `business/docs/competitor-analysis/*/*/<SNAPSHOT_DATE>/raw/lighthouse.json` (if present) |

### Pipeline (five stages, in order)

#### Stage 1 — Ingest templates

1. Read the two design-system templates in full. Do NOT ship them as
   output; they are the shape into which decisions are poured.
2. Identify every placeholder — anything matching `{{...}}` — and record
   it. Every one must be filled in the output.

#### Stage 2 — Ingest positioning + locale

1. Load runtime context (table above).
2. Extract five anchors from `POSITIONING`:
   - **Domain nouns** (what class of product).
   - **Buyer** (who pays).
   - **Geography / language boundary**.
   - **Wedge** (single differentiator).
   - **Anti-scope** (from § 5 Non-features).
3. Derive locale-mandated design invariants from `LOCALE_RULES`:
   - RTL-first (mirror everything at the logical-property layer, never patch physical).
   - Persian digits on human surfaces, ASCII on machine feeds.
   - Self-hosted Persian fonts (Vazirmatn / equivalent), sanctions-safe assets.
   - Jalali calendar as storage primitive if the product references dates.
   - Adjust when the product is bilingual / English-only per `PRODUCT_LANGUAGES`.

#### Stage 3 — Ingest competitor evidence

For every per-competitor audit in the newest snapshot:

1. Read `analysis.md` (18–28 dimension record).
2. Inspect the screenshots (hero, nav-open, service, careers, contact,
   mobile-hero). Record: dominant background, primary text color,
   accent color, button shape, elevation depth, typographic pairing,
   density (compact vs airy), imagery treatment.
3. Parse `raw/home.html` for signals:
   - `<link rel="stylesheet">` hosts (self-hosted vs Google Fonts vs CDN).
   - Font family declarations in inline `<style>` and linked CSS.
   - Meta viewport + language (`<html lang="fa" dir="rtl">`).
   - Presence of design-system attributes (`data-theme`, `data-density`,
     CSS variables), semantic tokens, or a design-token file.
4. Parse `raw/headers.txt` for tech stack signals: CDN vendor
   (ArvanCloud vs Cloudflare vs Akamai), server (nginx / apache /
   express), CSP hints.

Aggregate across competitors:

- **Palette clusters** — how many competitors share a similar hue family;
  what colors are conspicuously absent.
- **Type clusters** — most common serif / sans; whether Vazirmatn appears;
  Google Fonts dependency rate.
- **Density clusters** — compact ✅ / airy ✅ / mixed.
- **Iconography** — line vs solid, custom vs library (Feather, Heroicons,
  Font Awesome, Ionicons).
- **Elevation style** — flat ✅ / shadow-heavy ✅ / neumorphic.
- **RTL correctness** — how many local players actually get RTL right vs
  fake it with `direction: rtl` at root only.
- **Locale gaps** — Persian typography quirks, Jalali handling, ZWNJ
  normalization presence.

#### Stage 4 — Synthesize decisions

Every decision must trace back to one of:

- (P) a `POSITIONING` anchor
- (F) a `<SNAPSHOT_DATE>-feature-catalog.md` bullet
- (G) a competitor gap surfaced in Stage 3
- (L) a locale-mandated invariant from Stage 2

Produce the following ordered outputs:

1. **Principles from competitor analysis** — 5–8 rows, each `Principle | Competitor gap` referencing a source. This becomes §0 of the design-system output.
2. **Palette** — 3–5 brand swatches + full semantic token map (`--bg`, `--surface`, `--ink`, `--ink-muted`, `--accent`, `--danger`, `--focus-ring`, `--hover-bg`). Two themes (light + dark) unless positioning explicitly says single theme. Contrast ≥ 4.5 for body text, ≥ 3 for large text and non-text UI. Every swatch traces to a source.
3. **Typography** — display + body + mono tokens with family, weight, size, line-height. Self-hosting rule stated. Persian typographic quirks noted (ZWNJ handling, Persian digit shaping, ligatures).
4. **Spacing scale** — power-of-2 or 4-based tokens (`--space-1..8`).
5. **Elevation, radius, motion** — three tiers each. Motion tokens honor `prefers-reduced-motion`.
6. **Component catalog** — pick the 8–12 components most heavily exercised by the top-10 features in `<SNAPSHOT_DATE>-feature-catalog.md` (priority ≥ 8). Each: purpose, tokens used, states, a11y rule, RTL / LTR notes.
7. **Direction & RTL rules** — logical properties only, icon-flip rule, number-format rule, date-format rule.
8. **Accessibility floor** — WCAG 2.2 AA baseline calibrated to the audit dimension for accessibility.
9. **Out of scope for this design-system version** — mirrors `NON_FEATURES` where relevant to visual/interaction scope.

#### Stage 5 — Write outputs

Copy `product/docs/uiux/_templates/design-system-template.md` to
`product/docs/uiux/design-system/<PROJECT_ID>-design-system.md`. Replace
every placeholder with the values synthesized in Stage 4.

Copy `product/docs/uiux/_templates/design-system-template.html` to
`product/docs/uiux/design-system/<PROJECT_ID>-design-system.html`. Update
its CSS variables, sample components, and copy strings to match the
synthesized decisions. Preserve the template's structural HTML (theme
toggle, section anchors, sample specimens) — only fill in tokens and copy.

Report per file: `wrote <path>`.

### Placeholder-fill rules

- Every `{{...}}` placeholder in the template gets a real value. If a value
  cannot be sourced, emit `TBD: <what is missing>` inline, do not silently
  drop the placeholder.
- Persian copy in the HTML file is authored in Persian; the written `.md`
  file remains English-only prose (spec for implementers) with Persian
  strings quoted as data.
- Frontmatter fields (`derived_from`, `companion_of`, `scope_source`,
  `informed_by`) point to the actual files consulted:
  - `derived_from`: `<PROJECT_ID>-design-system.html` (companion HTML)
  - `companion_of`: `../../../business/docs/brand/brand.html` if present, else `TBD: no brand file`
  - `scope_source`: `../../../product/docs/features/v1/all-features.md` if present, else `../../product.md`
  - `informed_by`: `../../../business/docs/competitor-analysis/<SNAPSHOT_DATE>-feature-catalog.md`

### Traceability rules

Every color, token, or component decision in the written spec must carry a
one-line trace back to its source in a footnote-style parenthetical:

- Palette row: `(source: G — 6 of 8 competitors use warm accent, none use cool blue on hero)`.
- Component decision: `(source: F — feature §7 Editorial workflow priority 9)`.
- Locale rule: `(source: L — Farsi-only, self-hosted Vazirmatn per LOCALE_RULES)`.

Without these traces the output is unfalsifiable; reviewers must be able
to challenge any decision.

### Do NOT commit

Write files only. Do not `git add`, `git commit`, `git push`, or open an
MR. The user reviews the diff and commits themselves.

### Hard rules

- **Never overwrite** an existing `<PROJECT_ID>-design-system.md` or
  `.html`. Halt instead. Rev is a new file (e.g. `-v2-design-system.md`)
  only when the user explicitly asks for a rebrand.
- **Never invent competitor evidence**. If a screenshot is missing or a
  `raw/home.html` unreachable, note it in the "Principles from competitor
  analysis" section and reduce the sample.
- **Never touch `product/docs/uiux/_templates/`**. Those are the copy-source.
- **Never headline multi-language** or any feature not named in
  `POSITIONING` as the wedge.
- **Never commit** on behalf of the user.
- **Do not skip the traceability trace** on any decision. Every row must
  end with `(source: P | F | G | L …)`.

### Ask-vs-fill policy

- Silent by default — this sub-op reads `product.md` + competitor snapshot,
  makes design decisions, and writes. No mid-run questions.
- **Exception** — if `product.md` positioning is missing critical anchors
  (no wedge stated, no locale defined) OR the newest snapshot has fewer
  than 3 scored `analysis.md` files, halt and print:
  *"Insufficient input to synthesize a design system. Missing: <list>. Fix, then re-run."*

---

## features

This sub-op drives what was previously `/features-select`. It cuts the feature
scope for a single product version by grounding every `[x]` / `[ ]`
decision in `product.md` (intent) + the newest competitor feature-catalog
(candidate universe + priority).

Never overwrites an existing `features/v<N>/all-features.md` unless the user passes `::overwrite`. Never commits.

**Optional `::mode`** — see [`## Mode behavior`](#mode-behavior-merge-vs-overwrite). Applied to a `features` run, `merge` adds only newly-classified rows for features not yet listed and leaves existing `[x]` / `[ ]` decisions untouched.

### Preconditions

Halt immediately if any is unmet:

- `product/docs/product.md` exists. If missing → stop: *"`product/docs/product.md` not found. Run `/init product` first."*
- `product/docs/features/_templates/all-features.md` exists. If missing → stop: *"Template missing. Restore `product/docs/features/_templates/all-features.md`."*
- ≥ 1 file matching `business/docs/competitor-analysis/YYYY-MM-DD-feature-catalog.md` exists. If missing → stop: *"No competitor feature catalog found. Run `/init business synthesize` first."*
- Target file `product/docs/features/v<N>/all-features.md` does NOT exist OR `::mode` is set. If it exists AND no `::mode` given → stop: *"`v<N>` already selected at `<path>`. Re-run with `::merge` to add only new rows, `::overwrite` to rewrite from scratch, or bump the version."*
- `::mode` present but not `merge` | `overwrite` — refuse with the offending value named.

### Argument

- `/init features` → default version. If no `features/v*` folder exists → `v1`. If `v1` exists → `v2`. And so on.
- `/init features v1` → explicit version.

### Runtime context (load once)

From `product/docs/product.md`:

| Value | Source |
|---|---|
| `PROJECT_NAME` | § 1 Overview → `Name:` |
| `PROJECT_ID` | § 1 Overview → `Slug:` |
| `WEDGE` | § 3 Value proposition & wedge |
| `KEY_FEATURES` | § 4 Key features (bullet list) |
| `NON_FEATURES` | § 5 Non-features (bullet list — anti-scope) |
| `POSITIONING` | § 9 Positioning paragraph (verbatim) |
| `MARKET_GEOGRAPHY` | § 6 |
| `PRODUCT_LANGUAGES` | § 6 |
| `LOCALE_RULES` | § 6 |

From the newest snapshot (resolve `SNAPSHOT_DATE` = latest date in
`business/docs/competitor-analysis/YYYY-MM-DD-feature-catalog.md`):

| Value | Source |
|---|---|
| Feature catalog | `<SNAPSHOT_DATE>-feature-catalog.md` |
| Roles catalog (optional cross-check) | `<SNAPSHOT_DATE>-roles.md` if present |

### Version resolution

If the argument starts with `v` followed by digits → use that.
Otherwise auto-detect:

1. Scan `product/docs/features/` for subfolders matching `v<N>/`.
2. If none → target = `v1`.
3. If any → target = `v<max+1>` (increment the highest existing version).

### Pipeline (four stages)

#### Stage 1 — Ingest catalog

1. Parse the source `feature-catalog.md`. For each bullet, extract:
   - Description
   - Competitor slug list (`[slug, ...]`)
   - `priority`, `kano`, `effort`, `moat`, `paywall`, `personas` tags (each may be `...` or `?` if unknown)
   - Dimension section it belongs to (§ 1 through § 28)
2. Ignore the "Wedge picks" and "Anti-features" summary sections — they are derived, not source.
3. Record the union in memory grouped by dimension.

#### Stage 2 — Classify each feature

For each feature, apply the auto-classification rules **in this exact order**
(first rule that matches wins). The decision itself (`[x]` / `[ ]`) is
recorded on the bullet — **no per-bullet rationale is written to the
output**.

| Rule | Match condition | Decision |
|---|---|---|
| R1 | Feature description fuzzy-matches an entry in `NON_FEATURES` (§ 5 of product.md) | **[ ]** |
| R2 | Feature description fuzzy-matches an entry in `KEY_FEATURES` (§ 4) | **[x]** |
| R3 | Feature description references the `WEDGE` explicitly (contains ≥ 2 wedge nouns) | **[x]** |
| R4 | `priority` = 10 | **[x]** |
| R5 | `priority` ≤ 3 | **[ ]** |
| R6 | `priority` in {8, 9} AND `effort` ∈ {S, M} AND `kano` ∈ {basic, perf} | **[x]** |
| R7 | `priority` in {8, 9} AND `effort` = L | **[ ]** |
| R8 | `priority` in {6, 7} AND `kano` = basic | **[x]** |
| R9 | `priority` in {6, 7} AND `kano` = delighter | **[ ]** |
| R10 | `priority` in {4, 5} | **[ ]** |
| R11 | Unclassified (any tag = `?` or catalog signal missing) | **[ ]** |

**Fuzzy match** for R1 / R2 / R3:

- Case-insensitive.
- Persian ZWNJ + normalized (ی/ي, ک/ك).
- Substring hit on ≥ 60% of significant nouns from the catalog bullet
  against a KEY_FEATURES / NON_FEATURES line.
- Exact-string is a special case of fuzzy.
- If a feature matches BOTH R1 and R2 (contradiction), R1 wins and emit a
  `⚠️ conflict:` line to the Warnings tail block. Never silently drop the
  contradiction.

#### Stage 3 — Cross-checks

Before writing, verify:

- **Wedge coverage.** Every wedge noun from `WEDGE` (§ 3) is present in at
  least one `[x]` feature. If a wedge noun is missing from every `[x]`,
  emit `⚠️ wedge gap: no [x] feature covers "<noun>"` at the top of the
  output. Do not auto-flip anything to `[x]`; the user judges.
- **Non-feature respect.** No `[x]` fuzzy-matches an entry in
  `NON_FEATURES`. If one slips through, emit `⚠️ anti-scope violation`.
- **`[x]` count sanity.** If `[x]` count = 0 or > 70% of the total, emit
  `⚠️ selection skew: <count> of <total> selected` — likely the rules
  need review.

#### Stage 4 — Write output

Copy `product/docs/features/_templates/all-features.md` to
`product/docs/features/v<N>/all-features.md`. Fill:

| Placeholder | Value |
|---|---|
| `{{PROJECT_NAME}}` | from product.md |
| `{{VERSION}}` | resolved N (integer, without leading `v`) |
| `{{SCOPE_ONELINE}}` | one-sentence roll-up of the wedge |
| `{{SOURCE_FEATURE_CATALOG_PATH}}` | relative path to the source catalog |
| `{{YYYY-MM-DD}}` | today's UTC date |
| `{{VERSION_CUT_PHILOSOPHY}}` | one paragraph derived from POSITIONING + KEY_FEATURES + NON_FEATURES — states what this version prioritizes and what it defers |
| `{{N_IN_SCOPE}}`, `{{N_TOTAL}}` | actual counts from Stage 2 |
| `{{ROLES_IN_SCOPE}}` | roles named in KEY_FEATURES-driven personas |

Under each dimension section, replace the placeholder bullet with the
actual features from Stage 2, one bullet per feature, in this shape:

```
- [x] **<feature description>** — **<priority>** — <one-sentence description>.
```

or:

```
- [ ] **<feature description>** — **<priority>** — <one-sentence description>.
```

**No per-bullet rationale.** The auto-classification rules run internally;
only the resulting `[x]` / `[ ]` decision is written to disk.

Preserve:

- Feature order **within** a dimension — sort by priority desc, then
  original catalog order.
- Every tag from the source catalog carried inline as parenthetical after
  the description: `(kano: X | effort: Y | moat: Z | paywall: W | personas: [...])`.

Sections with zero features from the catalog get: `_(no features in this
dimension for v<N>)_` under the header — do not delete the header, the
28-dimension frame stays intact.

**Remove** the "Absorbed / superseded features" and "Deferred with reason"
tail-sections from the template — those carried rationale text and are no
longer part of the output.

Append at the very bottom of the file, in a `## Warnings` block, only the
`⚠️` lines emitted during Stages 2–3 (contradictions, wedge gaps,
selection skew). Warnings are system-level flags, not per-bullet reasons.
If zero warnings, print `_none — clean selection_`.

Report per file: `wrote <path>`.

### Do NOT commit

Write files only. Do not `git add`, `git commit`, `git push`, or open an
MR. The user reviews the diff and commits themselves.

### Hard rules

- **Never overwrite** an existing `v<N>/all-features.md`. Halt instead.
  Rev is a new folder `v<N+1>/`.
- **Never invent a feature** not in the source catalog. If `product.md`
  names a feature that no competitor ships, add it under the closest
  dimension with `priority: N/A | (source: product.md § 4 — not in
  competitor catalog)` and `[x]`.
- **Never touch `_templates/all-features.md`**. Copy-source, keeps
  placeholders.
- **Never touch `product.md`**. Read-only.
- **Never touch the source `feature-catalog.md`**. Read-only.
- **Never merge stages** — do not offer to also update the design system
  or roadmap in the same turn.
- **Never commit** on behalf of the user.

### Ask-vs-fill policy

Silent by default. Reads inputs, applies rules, writes. No mid-run
questions.

**Exception** — if `KEY_FEATURES` or `NON_FEATURES` in `product.md` are
empty (nothing between `- ` and end-of-line for every bullet), halt and
print: *"`product.md` § 4 or § 5 is empty — auto-classification cannot
run. Fill both, then re-run."*

---

## tech-architecture

This sub-op drives what was previously `/tech-architecture-init`. It decides
the platform architecture shape for one product version by grounding every
call in three sources — `product.md` (intent + locale), the version's
`all-features.md` (binding `[x]` scope), and `design-system/` (frontend
invariants). Business/users and the newest competitor snapshot are
optional cross-checks.

**Report-only.** This sub-op NEVER writes files. The chat report IS the
deliverable. The user reads the report and decides how to proceed —
create `tech/` repos manually, run `/init tech-standards` next (which
walks `tech/` directly), or iterate on the plan.

**Binary shape — microservices by default.** The architecture call is
monolith OR microservices — no hybrid. Every codebase referenced in
this workspace lands on one of those two.

**Microservices is the default.** Monolith is the exception, reserved
for genuinely simple projects (one backend domain, marketing site plus
maybe a tiny admin, no analytics workload, no PSP, no real-time, no
cross-service coordination). Anything with real SaaS shape goes
microservices. The pivot is a single low number (4 out of 18); anything
at-or-above sits on microservices, and borderline totals (3 or 4) lean
toward microservices — blast-radius isolation is worth the extra process,
and collapsing services into one repo later is cheaper than untangling a
monolith.

### Report-only, no file

At this stage the user has `product/docs/` + `business/docs/` + design system + finalized features, but **the `tech/` engineering repos have not been created yet**. This sub-op hands them the recommendation so they can create the repos manually (or with any scaffolder they prefer). The next sub-op in the chain (`/init tech-standards`) walks `tech/` directly and detects what the user built — no plan file needed to bridge them.

### Preconditions

Halt immediately if any is unmet:

- `product/docs/product.md` exists. If missing → stop: *"`product/docs/product.md` not found. Run `/init product` first."*
- `product/docs/features/v<N>/all-features.md` exists for the resolved `<N>`. If missing → stop: *"`product/docs/features/v<N>/all-features.md` not found. Run `/init features v<N>` first."*
- `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md` exists. If missing → stop: *"Design system not found. Run `/init design-system` first."*

### Argument

- `/init tech-architecture` → default version. Auto-detects the highest existing `product/docs/features/v<N>/`.
- `/init tech-architecture v1` → explicit version. Must correspond to an existing `product/docs/features/v1/all-features.md`.

### Runtime context (load once)

From `product/docs/product.md`:

| Value | Source in `product.md` |
|---|---|
| `PROJECT_NAME` | § 1 Overview → `Name:` |
| `PROJECT_ID` | § 1 Overview → `Slug:` |
| `ONE_LINE_PITCH` | § 1 Overview → `One-line pitch:` |
| `TARGET_USER` | § 2 Problem & target user |
| `WEDGE` | § 3 Value proposition & wedge |
| `KEY_FEATURES` | § 4 Key features |
| `NON_FEATURES` | § 5 Non-features |
| `MARKET_GEOGRAPHY` | § 6 |
| `PRODUCT_LANGUAGES` | § 6 |
| `LOCALE_RULES` | § 6 |
| `PRICING_MODEL` | § 7 (may be empty) |
| `POSITIONING` | § 9 Positioning paragraph (verbatim) |

From `product/docs/features/v<N>/all-features.md`:

| Value | Source |
|---|---|
| `IN_SCOPE_FEATURES` | every bullet starting with `- [x]`, keyed by dimension section header |
| `OUT_OF_SCOPE_FEATURES` | every bullet starting with `- [ ]` (reference only — do not assign to a repo) |

From `product/docs/uiux/design-system/<PROJECT_ID>-design-system.md`:

| Value | Source |
|---|---|
| `RTL` | direction rule (Farsi / Arabic → RTL) |
| `FONTS` | self-hosted / CDN — dictates the "no third-party font origin" rule |
| `CALENDAR` | Jalali / Gregorian / dual — dictates the shared calendar library |
| `DIGIT_RULES` | Persian on human surfaces / ASCII on machine feeds — dictates a normalization module |
| `PAGES` | every top-level page name mentioned (drives the frontend split) |

Optional (read when present):

- `business/docs/users/` — every user-type card (dictates frontend split + role registry sizing).
- Newest `business/docs/competitor-analysis/YYYY-MM-DD-feature-catalog.md` — workload signals not obvious from `IN_SCOPE_FEATURES` (append-only volume, PSP requirements, real-time expectations, ML compute).

### Version resolution

If the argument starts with `v` followed by digits → use that.
Otherwise auto-detect:

1. Scan `product/docs/features/` for subfolders matching `v<N>/`.
2. If none → halt: *"No feature catalog found — run `/init features v1` first."*
3. If any → target = highest `v<N>` (the freshest catalog).

The resolved `<N>` must correspond to an existing
`product/docs/features/v<N>/all-features.md`. If not, halt with the
specific missing path.

### Binary shape only — microservices by default

Every codebase in this workspace lands on **monolith** or **microservices**. No hybrid, no mixed shape.

**Microservices is the default.** Monolith is reserved for genuinely simple projects — one backend domain, marketing site + maybe a tiny admin, no analytics workload, no PSP, no real-time, no cross-service coordination. Anything with real SaaS shape (multiple domains, per-domain scaling concerns, RBAC across surfaces, external integrations) goes microservices.

The pivot is a single low number (4 out of 18):
- Total ≤ 3 → monolith (the exception, for truly simple projects).
- Total ≥ 4 → microservices (the default).
- Borderline (exactly 3 or 4) → microservices — bias toward splitting so blast-radius isolation is preserved from day one; collapsing services into one process later is cheaper than untangling a monolith.

### Pipeline (five stages, in order)

#### Stage 1 — Ingest [x] features and bucket them by domain

1. Read `all-features.md`. For every `- [x]` bullet, capture:
   - Dimension section header it lives under (§ 1 through § 28 of the source catalog).
   - Feature description text.
   - Any inline tags carried by `/init features` (`priority`, `kano`, `effort`, `moat`, `paywall`, `personas`).
2. Group by **domain bucket** — coarse buckets, each one either becomes a
   microservice or a module inside the monolith. The default 12 buckets:

   | Bucket | What lands here |
   |---|---|
   | `auth` | identity, OTP, JWT, sessions, RBAC, API keys, rate-limit |
   | `content` | typed content types, workflow, taxonomy, versioning, redirects, sitemap / RSS / JSON-LD feeds, webhooks |
   | `assets` | uploads, DAM, image transform, CDN purge, video embeds |
   | `search` | search engine wrapper, indexers, type-ahead, locale normalization |
   | `engagement` | comments, reactions, polls, moderation, captcha |
   | `analytics` | pageviews, custom events, popular-content rollups (**append-only, high volume**) |
   | `notification` | in-app notifications, SMS, email, web-push, broadcasts |
   | `finance` | wallet, payments, PSP, packs, subscriptions, invoices |
   | `job` | queue control plane over the broker, priority lanes, DLQ surface |
   | `support` | tickets, FAQ, guest contact-us |
   | `workspace` | user projects / folders / tags / editor state (SaaS domain object) |
   | `activity-log` | cross-service audit trail sink |

   Buckets with zero `[x]` features are dropped from the output — they
   do not become a repo or a module.

3. Every `[x]` bullet must land in exactly one bucket. Unclassifiable
   bullets go to a synthetic `misc` bucket and emit
   `⚠️ unbucketed: <feature>` to the Warnings tail block.
4. Frontend-owned features (edit UX, block editor, block renderer,
   share buttons, JSON-LD emission at build) do **not** get a backend
   bucket — they are assigned to a frontend repo in Stage 3.

#### Stage 2 — Score architecture signals and pick the binary shape

Score each signal 0 / 1 / 2 and total them.

| Signal | 0 | 1 | 2 |
|---|---|---|---|
| **Bucket count** (populated backend buckets from Stage 1) | ≤ 3 | 4–6 | ≥ 7 |
| **High-volume append-only workload** (analytics present + `[x]` says "high-volume" / "pageview" / "millions") | absent | present, small | present, called out as scale-critical |
| **Isolated compute** (ML / GPU / STT / heavy image / video encode) | absent | one small model or job | dedicated engine, GPU-bound |
| **Financial surface** (PSP / wallet / subscription / invoice) | absent | subscription only | full PSP integration with webhook idempotency |
| **Real-time async** (streaming, WebSocket badge fan-out, live cursors) | absent | one endpoint | end-to-end streaming or fan-out |
| **Cross-service audit or webhook fabric** (`activity-log` bucket populated OR external webhooks in `[x]`) | absent | audit only OR webhooks only | both |
| **Frontend surface count** (from Stage 3 pre-count) | 1 | 2 | 3+ |
| **`[x]` feature count** | < 40 | 40–120 | > 120 |
| **Locale / regulatory blast-radius isolation asked** (`NON_FEATURES` says "no cross-service SQL", or `POSITIONING` names data-residency / sanctions posture as a wedge) | absent | mentioned | explicit hard rule |

**Binary threshold — microservices-biased** (max possible total is 18):

| Total | Shape |
|---|---|
| ≥ 4 | **microservices** (one process per populated bucket + `backend-shared-logic` library) — **the default** |
| ≤ 3 | **monolith** (the exception, for genuinely simple projects) — one `backend-monolithic` repo, internal `src/modules/<bucket>/` matching the populated buckets |

Record for the report:

- The score per signal (with the `[x]` bullet or `product.md` sentence that triggered it).
- The total.
- The chosen shape.
- The one-paragraph rationale, in this shape:
  > *"{{PROJECT_NAME}} v{{N}} ships as a {{SHAPE}} because {{TOP_3_SIGNALS_BY_SCORE}}. {{ONE_SENTENCE_ABOUT_SIGNALS_THAT_ALMOST_TIPPED_IT_THE_OTHER_WAY}}."*

If the total is exactly 3 or 4 (right at the pivot), emit
`⚠️ borderline shape: total <T>, ±1 from pivot 3/4 → picks microservices by rule` and pick **microservices** — blast-radius isolation from day one is worth the extra process; collapsing services into one repo later is cheaper than untangling a monolith.

#### Stage 3 — Derive the frontend surface split

Read `KEY_FEATURES`, `TARGET_USER`, `PAGES` (from design-system + uiux
tree), and `business/docs/users/` (when present). Decide which frontends
ship using this decision table:

| Signal | Frontend it forces |
|---|---|
| Public marketing / SEO / reader-facing pages named in `PAGES` (Home, About, Services, blog, article renderer, section landings) | `frontend-landing` (always ships if this is present) |
| End-user authenticated app named in `PAGES` or user-types (customer dashboard, self-serve workspace, transcript editor, my-account) | `frontend-dashboard` |
| Editorial / operator / moderator surface named in `PAGES` or user-types (editorial calendar, moderation queue, admin sidebar, content-editing, plan management) | `frontend-admin` |
| Platform-operator surface (super-admin, tenant management, billing ops — usually multi-tenant only) | `frontend-platform-admin` — v.next slot, reserve only if the current version needs it |

Rules:

- If the product has both an editorial admin and an end-user dashboard,
  **ship them as two separate SPAs**, never one SPA with a role-gated
  sidebar. Reason: bundle size, auth surface, route-tree isolation, blast
  radius on RBAC bugs.
- If v.current has no reader accounts (marketing-only or editorial-only),
  drop `frontend-dashboard` and let `frontend-admin` host every
  authenticated surface.
- Every frontend produces static output served by nginx. No Node at the
  edge, no SSR. `frontend-landing` uses Astro 5 SSG (islands);
  `frontend-admin` / `frontend-dashboard` use Vite 6 + React 19 static
  SPA. Pinned regardless of architecture shape.

Emit the count back to Stage 2 (the "Frontend surface count" signal).

#### Stage 4 — Derive the infra footprint

Every populated slot in the table below ships as its own `infra-<name>`
repo. Slots not needed are dropped.

| Slot | Always? | Trigger to include |
|---|---|---|
| `infra-postgresql` | **always** | needed by every backend |
| `infra-nginx` | **always** | single edge for both frontends and backend REST |
| `infra-minio` | **always** if any bucket needs object storage | assets, exports, backups, voice tickets — realistically always |
| `infra-redis` | **almost always** | rate-limit counters, OTP TTL, revoked-JWT flags, render cache; only skip if the monolith is CRUD-only with zero rate-limit / OTP / cache needs |
| `infra-kafka` | **only if** SHAPE=microservices OR the "Cross-service audit or webhook fabric" signal scored ≥ 1 | four canonical day-one flows: search-indexer, webhook dispatcher, audit-recorded sink, assets CDN purge |
| `infra-meilisearch` | **only if** `search` bucket is populated AND the product needs facets / type-ahead beyond Postgres FTS | otherwise Postgres FTS covers it |
| `infra-observability` | **always** for microservices; **optional** for monolith | Grafana + Loki + Promtail + Prometheus + Tempo + OTel Collector + Alertmanager + blackbox exporter |
| `infra-metabase` | only if `product.md` § 8 names KPI dashboards or the users catalog names a data / ops role | self-hosted BI over the primary Postgres |

Naming convention: prefix is `infra-`.

#### Stage 5 — Print the chat report (the ONLY deliverable)

Print a **compact** report directly to stdout. No file is written.

**Report scope:** shape decision + score + repo list. Nothing else.

Explicitly **DO NOT PRINT**:
- Feature → owner mapping (per-dimension tables)
- Fixed stack tables (backend / frontend)
- Deployment topology block
- "What lives outside v<N>" bullet list
- Any narrative that repeats what the user can read in the source docs

Format:

```
━━━ {{PROJECT_NAME}} v{{N}} — architecture recommendation ━━━

Shape: {{SHAPE}}          (score {{TOTAL}} / 18 — pivot ≤3 monolith / ≥4 microservices; microservices default)

Signal scores:
  Bucket count                             = {{s1}}  ({{trigger}})
  High-volume append-only workload         = {{s2}}  ({{trigger}})
  Isolated compute                         = {{s3}}  ({{trigger}})
  Financial surface                        = {{s4}}  ({{trigger}})
  Real-time async                          = {{s5}}  ({{trigger}})
  Cross-service audit / webhook fabric     = {{s6}}  ({{trigger}})
  Frontend surface count                   = {{s7}}  ({{trigger}})
  [x] feature count                        = {{s8}}  ({{count}})
  Locale / regulatory blast-radius         = {{s9}}  ({{trigger}})
  Total                                    = {{TOTAL}}

{{if borderline}}⚠️ borderline shape: total {{TOTAL}}, ±1 from pivot 3/4 — picks microservices by rule (bias to split){{/if}}

Why {{SHAPE}}: {{ONE_PARAGRAPH_RATIONALE — top 3 signals + the near-miss signal}}

Counts: {{N_BACKEND}} backend + {{N_FRONTEND}} frontend + {{N_INFRA}} infra = {{N_TOTAL_REPOS}} engineering repos

────── Backend ──────
  {{repo}}                — {{one-line scope}}
  ...

────── Frontend ──────
  {{repo}}  @ {{domain}}   — {{one-line scope}}
  ...

────── Infra ──────
  {{repo}}                — {{one-line role}}
  ...

────── Warnings ──────
  {{one ⚠️ line per warning emitted during Stages 1–4, or "_none — clean derivation_"}}
```

That is the entire report. Length target: **≤ 60 lines total**, most
of them in the signal-scores table + the three repo lists. No section
beyond Warnings ever gets printed.

The report is the deliverable. Nothing is written to disk. The next
sub-op (`/init tech-standards`) walks `tech/` directly and detects
what the user created — no plan file needed to bridge them, and the
detailed feature→owner map + fixed stack tables land in
`tech/docs/project-architecture/v<N>.md` at that point (not now).

#### Row-emission rules for the Backend section

- **Microservices shape** — one row per populated bucket from Stage 1
  (repo name = `backend-<bucket>`), plus one row for
  `backend-shared-logic` (library — no app, no DB, no container; JWT
  verifier, MinIO adapter, DbAction, calendar lib, OTel bootstrap,
  broker wrappers).
- **Monolith shape** — one row for `backend-monolithic`. The "scope"
  column lists every populated bucket as an internal `src/modules/<bucket>/`
  module.
- Never invent a bucket that has no `[x]` feature.
- Never rename buckets away from the twelve-bucket vocabulary in
  Stage 1 — a rename kills the feature→owner map.

### Hard rules

- **Never write files.** The chat report is the ONLY deliverable. Do
  not create `product/docs/tech-plan/` or any other file. Do not
  suggest paths the user should copy the report into.
- **Never write to `tech/docs/`.** That tree may not even exist at this
  stage.
- **Never suggest a third shape.** Binary monolith or microservices.
  Hybrid is not offered.
- **Never invent** a repo the shape rules did not derive. If the user
  wants an extra service, they add it after review, not this sub-op.
- **Never assign a `[ ]` feature to a repo.** `[ ]` features are ignored
  for repo derivation; they appear only in "What lives outside".
- **Never touch `product.md`, `all-features.md`, `design-system/`.**
  Read-only.
- **Never merge stages** — do not offer to also scaffold the repos or
  write per-service PRD-TDDs in the same turn. That is a separate
  sub-op.
- **Never commit** on behalf of the user.

### Ask-vs-fill policy

Silent by default. Reads inputs, applies rules, prints report. No
mid-run questions.

**Exception** — halt and ask exactly once when:

- `PAGES` names an admin surface AND a customer dashboard AND
  `TARGET_USER` is a single role — ambiguous whether one SPA or two.
  Prompt: *"Ship the admin as a separate `frontend-admin` SPA, or fold
  it into `frontend-dashboard` as a role-gated area?"* Default answer
  after 60s of silence is "separate SPA" (the safer blast-radius call).

Every other ambiguity resolves to the documented default (monolith on
the 6/7 pivot, drop the frontend-dashboard when no reader accounts,
etc.); do not chain questions.

---

## tech-standards

This sub-op drives what was previously `/tech-standards-init`. It renders
project-agnostic templates into the concrete `tech/docs/` tree for one
product version by grounding every substitution in two sources:

1. **The existing `tech/` directory.** The user has already created
   the engineering repo folders (guided by the report from
   `/init tech-architecture`, or by hand). This sub-op walks `tech/` and
   detects the ARCH_SHAPE + repo lists + HAS_* infra flags from what's
   actually on disk. No plan file to bridge them.
2. **`product/docs/product.md`.** Locale, calendar, digit rules,
   positioning, market geography.

Provider names come from either `product/docs/product.md` (when the user
recorded them there) or an interactive prompt at scaffold time. Every
provider-specific clause lives inline in whichever template needs it,
gated by `{{#IF <PROVIDER>}}...{{/IF}}`. No external registry lookup.

**Binary shape.** ARCH_SHAPE is `monolith` OR `microservices`. Never
hybrid — that's not a shape this workspace offers.

Never overwrites a real file unless the user passes `::overwrite`. Never commits.

**Optional `::mode`** — see [`## Mode behavior`](#mode-behavior-merge-vs-overwrite). Applied to a `tech-standards` run:
- **`::merge`** — every populated target (> 5 non-blank lines) is **skipped** verbatim; every stub (≤ 5 non-blank lines) or missing path is rendered from template. Report per file: `merged (rendered) <path>` OR `skipped (populated) <path>` OR `created <path>`.
- **`::overwrite`** — every target is wiped and re-rendered from templates regardless of prior content.

### Source of truth for shape + repo list

The on-disk `tech/` directory. Not a plan file. The user has already
created the engineering repo folders (guided by the report from
`/init tech-architecture`, or by hand), and this sub-op detects what
exists.

- Only `tech/backend-monolithic/` present → monolith.
- Multiple `tech/backend-<name>/` folders (at least one not
  `backend-monolithic`) → microservices.
- Both patterns at once → halt with an error; the workspace only supports
  one shape.

### Preconditions

Halt immediately if any is unmet:

- `product/docs/product.md` exists. If missing → stop: *"`product/docs/product.md` not found. Run `/init product` first."*
- `tech/` directory exists.
- `tech/` contains at least one of:
  - Exactly one `backend-monolithic/` subdirectory (→ ARCH_SHAPE=monolith)
  - **OR** two or more `backend-<name>/` subdirectories where at least one is NOT `backend-monolithic` (→ ARCH_SHAPE=microservices)
  - If neither pattern matches (e.g. empty `tech/`, or only one non-monolithic `backend-<name>/`) → halt: *"Cannot detect ARCH_SHAPE from `tech/`. Expected either a single `tech/backend-monolithic/` (monolith) or multiple `tech/backend-<name>/` folders (microservices). Create the repo folders first, then re-run."*
- `Claude-Files/tech/docs/_templates/` exists and contains:
  - `CLAUDE.md`
  - `README.md`
  - `project-architecture.md`
  - `standards/` with the 12 template files:
    - `api-and-data-contracts.md`
    - `ci-cd.md`
    - `coding.md`
    - `documentation.md`
    - `errors-and-observability.md`
    - `frontend.md`
    - `frontend-layout.md`
    - `git.md`
    - `infrastructure.md`
    - `monolith-layout.md`
    - `microservice-layout.md`
    - `security-and-auth.md`
    - `testing.md`
- Every target file that already exists under `tech/docs/` is a stub
  (< 5 non-blank lines) OR the user passed `::mode`. Any target with real
  content AND no `::mode` blocks the run — refuse and list every blocking
  file path with the hint: *"Re-run with `::merge` to skip populated files
  and fill only stubs / missing paths, or `::overwrite` to rewrite every
  target from templates."*
- `::mode` present but not `merge` | `overwrite` — refuse with the
  offending value named.

### Argument

- `/init tech-standards` → default `v1`. Version is auto-detected from the highest existing `product/docs/features/v<N>/`.
- `/init tech-standards v2` → explicit version. Must correspond to `product/docs/features/v2/all-features.md`.

### Runtime context (assemble once)

#### From `product/docs/product.md`

| Variable | Source |
|---|---|
| `PROJECT_NAME` | § 1 Overview → `Name:` |
| `PROJECT_SLUG` | § 1 Overview → `Slug:` |
| `LOCALE_MODE` | derive from § 6 `PRODUCT_LANGUAGES` — `farsi-only` if only Farsi; `bilingual` if Farsi + English; `latin-only` if no Persian |
| `DIGIT_RULES` | § 6 → `LOCALE_RULES` (freeform) |
| `CALENDAR` | infer from `LOCALE_RULES` — `jalali` if Persian dates referenced; `gregorian` if Latin; `dual` if both. Default `jalali` when `LOCALE_MODE ∈ farsi-only, bilingual`. |
| `MARKET_GEOGRAPHY` | § 6 |
| `POSITIONING` | § 9 (used as the anchor paragraph in the emitted `CLAUDE.md`) |

#### Detect from the on-disk `tech/` directory

Walk `tech/` non-recursively (one level of subdirectories) and populate:

| Variable | Detection rule |
|---|---|
| `ARCH_SHAPE` | If `tech/backend-monolithic/` exists AND no other `backend-<name>/` → `monolith`. If two or more `backend-<name>/` where at least one is NOT `backend-monolithic` → `microservices`. |
| `OWNER_TERM` | `module` when `monolith`; `service` when `microservices`. |
| `BACKEND_REPOS` | Every `tech/backend-<name>/` folder. For monolith: exactly one row `backend-monolithic` whose scope lists the internal modules (derived from top-level dirs inside `tech/backend-monolithic/src/modules/`, or `[unknown — populate later]` when the source tree is empty). For microservices: one row per folder; scope is `[unknown — populate later]` unless a `<repo>/README.md` or `<repo>/CLAUDE.md` names it. Emit `backend-shared-logic` explicitly when the folder exists. |
| `FRONTEND_REPOS` | Every `tech/frontend-<name>/` folder. |
| `INFRA_REPOS` | Every `tech/infra-<name>/` folder, plus every `tech/devops-<name>/` folder (some projects use the `devops-` prefix — accept both, emit a `⚠️ prefix drift: devops-* detected` warning so the user picks one convention). |
| `HAS_KAFKA` | true if `tech/infra-kafka/` or `tech/devops-kafka/` exists |
| `HAS_REDIS` | true if `tech/infra-redis/` or `tech/devops-redis/` exists |
| `HAS_MEILISEARCH` | true if `tech/infra-meilisearch/` or `tech/devops-meilisearch/` exists |
| `HAS_MINIO` | true if `tech/infra-minio/` or `tech/devops-minio/` exists |
| `HAS_OBSERVABILITY_STACK` | true if `tech/infra-observability/` or `tech/devops-observability/` exists |
| `HAS_MIRROR_TABLES` | true if `ARCH_SHAPE=microservices` AND `HAS_KAFKA=true` |
| `BE_COVERAGE_FLOOR` | 95 (house-style default) |
| `FE_COVERAGE_FLOOR` | unset (default) |

If both `backend-monolithic/` AND another `backend-<name>/` are present
→ halt: *"`tech/backend-monolithic/` co-exists with other `backend-*` folders. This workspace supports monolith OR microservices, not both. Remove one shape and re-run."*

#### Providers (each may be null)

Try each source in order until a value is found:

1. **`product/docs/product.md` § 10 Providers** — if the user recorded a `Providers:` block naming any of the six slots (`OTP_PROVIDER`, `CAPTCHA_PROVIDER`, `CDN_PROVIDER`, `PSP_PROVIDER`, `BLOCK_EDITOR`, `VIDEO_EMBED_PROVIDER`), use those values verbatim.
2. **Locale-tied defaults** — when § 10 does not name a slot:
   - `LOCALE_MODE ∈ farsi-only, bilingual` AND `HAS_NEED_OTP` (any `tech/backend-notification/` OR `tech/backend-auth/` exists) → suggest `kavenegar` for `OTP_PROVIDER`.
   - `LOCALE_MODE ∈ farsi-only, bilingual` AND any frontend that hosts a form → suggest `arcaptcha` for `CAPTCHA_PROVIDER`.
   - `LOCALE_MODE ∈ farsi-only, bilingual` AND (`tech/backend-assets/` exists OR any frontend surface exists) → suggest `arvancloud` for `CDN_PROVIDER`.
   - `LOCALE_MODE = latin-only` → suggest `twilio` / `turnstile` / `cloudflare` respectively.
   - `PSP_PROVIDER`, `BLOCK_EDITOR`, `VIDEO_EMBED_PROVIDER` → default `null` unless § 10 names them or the tech/ layout clearly implies (e.g. `tech/backend-finance/` present → prompt for PSP).
3. **Prompt user once** with the assembled suggestion list before rendering. Format:

   ```
   Providers detected / suggested:
     OTP_PROVIDER      = kavenegar   (suggested from LOCALE_MODE=farsi-only + backend-notification/ present)
     CAPTCHA_PROVIDER  = arcaptcha   (suggested)
     CDN_PROVIDER      = arvancloud  (suggested)
     PSP_PROVIDER      = null        (no backend-finance/, no product.md § 10 entry)
     BLOCK_EDITOR      = null
     VIDEO_EMBED_PROVIDER = null

   Accept all? (Y/n/edit)
   ```

   `Y` proceeds. `n` halts. `edit` allows per-slot override before proceeding. If the caller passed CLI overrides (`--otp=<slug>` etc. via the argument), those bypass the prompt for the named slots.

If a provider slot is null, every `{{#IF <PROVIDER>}}...{{/IF}}` block
that gates on it is dropped entirely. Never leave a `{{PROVIDER_NAME}}`
literal in the rendered output.

### Version resolution

If the argument starts with `v` followed by digits → use that.
Otherwise auto-detect:

1. Scan `product/docs/features/` for subfolders matching `v<N>/`.
2. If none → halt: *"No feature catalog found — run `/init features v1` first."*
3. If any → target = highest `v<N>` (the freshest catalog).

Version drives only the output filename `tech/docs/project-architecture/v<N>.md`; the standards files are versionless.

### Pipeline (six stages)

#### Stage 1 — Load templates and validate structure

1. Read every file under `Claude-Files/tech/docs/_templates/` into
   memory. Verify all 16 expected files are present (14 rendered
   candidates + 2 arch-shape layout variants of which exactly one is
   rendered): `CLAUDE.md`, `README.md`, `project-architecture.md`,
   `standards/` × 12 (including both `microservice-layout.md` and
   `monolith-layout.md`).
2. For each template, scan for balanced `{{#IF}}` / `{{/IF}}` +
   `{{#UNLESS}}` / `{{/UNLESS}}` + `{{#ELSE}}` markers. If any are
   unbalanced → halt: *"Template `<path>` has unbalanced conditional
   block at line <L>."*
3. Collect the full set of `{{VAR}}` placeholders referenced across all
   templates. Every one must be resolvable from the runtime context
   (§ Runtime context above). Unresolved placeholders → halt with the
   list.

#### Stage 2 — Assemble runtime context

Populate the context table using the sources in § Runtime context —
walk `tech/` for detection, read `product/docs/product.md` for locale,
resolve providers via § Providers.

Every value must be concrete — no `null`, no `undefined`. When a value
is genuinely absent (e.g. `PSP_PROVIDER` when no monetization ships),
set it to the sentinel `false` (used by `{{#IF}}` / `{{#UNLESS}}` gates).

Print the resolved context to stderr for the user's eyes, one line per
variable. Halt on ambiguity — do not guess. Example ambiguities:

- `LOCALE_MODE` unclear because `PRODUCT_LANGUAGES` lists three languages → prompt once: *"`LOCALE_MODE`: which of `farsi-only` / `bilingual` / `latin-only` / other applies?"*
- The `tech/` walk is ambiguous (e.g. mixed prefixes `infra-*` AND `devops-*`) → prompt once: *"Prefix drift detected. Use `infra-` or `devops-` for infra repos in the rendered docs?"*

Everything else is silent.

#### Stage 3 — Render templates

For every template, in this exact order:

1. `CLAUDE.md`
2. `README.md`
3. `project-architecture.md`
4. `standards/git.md`
5. `standards/documentation.md`
6. `standards/api-and-data-contracts.md`
7. `standards/security-and-auth.md`
8. `standards/frontend-layout.md`
9. `standards/frontend.md`
10. `standards/coding.md`
11. `standards/errors-and-observability.md`
12. `standards/testing.md`
13. `standards/ci-cd.md`
14. `standards/infrastructure.md`
15. `standards/microservice-layout.md` **OR** `standards/monolith-layout.md` — pick by `ARCH_SHAPE`:
    - `microservices` → `microservice-layout.md`
    - `monolith` → `monolith-layout.md`

**Special handling for `project-architecture.md`** — this template
composes the canonical tech-side arch doc from the detected runtime
context. Since there is no arch plan file to promote from anymore,
every section is filled directly from:

- Repo lists → the `tech/` walk (Stage 2)
- Feature → owner map → `product/docs/features/v<N>/all-features.md` (dimension section + bucket-inference rules matching `/init tech-architecture` Stage 1)
- Signal-score rationale → OMITTED (the arch-init report carries this; the tech-side doc records the shape as a decision, not the derivation)
- Fixed stack tables → the house-style pinned choices (Python 3.13 + FastAPI + Postgres 17 + …), with rows gated on the corresponding `HAS_*` flag or `PROVIDER` slot
- §Cross-cutting decisions → conditional blocks in the template (redirect+slug-history when `content` bucket + Redis; CDN purge when `assets` + CDN + Kafka; Jalali storage primitive when `CALENDAR=jalali`; etc.)
- §Glossary → the standard entries + one row per bucket present

For each template:

- Replace every `{{VAR}}` with its resolved value.
- Evaluate `{{#IF VAR}}...{{/IF}}` / `{{#IF VAR=value}}...{{/IF}}`:
  - True → keep contents, drop markers.
  - False → drop the entire block including markers.
- `{{#UNLESS VAR}}...{{/UNLESS}}` is the inverse.
- `{{#ELSE}}` inside an `IF` / `UNLESS` swaps to the alternate branch.
- Nested blocks resolve inside-out.
- Loops over `BACKEND_REPOS` / `FRONTEND_REPOS` / `INFRA_REPOS` render
  one row per repo — expand the template's row-form for every entry.

**Never write a rendered file that still contains a `{{...}}` marker.**
If any survives, halt and report which template / which variable.

#### Stage 4 — Write outputs

Write each rendered template to `tech/docs/` at the matching path:

| Template | Output |
|---|---|
| `_templates/CLAUDE.md` | `tech/docs/CLAUDE.md` |
| `_templates/README.md` | `tech/docs/README.md` |
| `_templates/project-architecture.md` | `tech/docs/project-architecture/v<N>.md` |
| `_templates/standards/<f>.md` | `tech/docs/standards/<f>.md` |

Create `tech/docs/project-architecture/` if missing (writing the file
creates the folder).

For the arch-shape file — exactly one of
`tech/docs/standards/microservice-layout.md` or
`tech/docs/standards/monolith-layout.md`. **Never both.**

#### Stage 5 — Post-write sanity checks

Per rendered file:

- File size ≥ 100 non-blank lines (otherwise → warn `⚠️ suspiciously short: <path>`).
- No `{{` or `}}` character sequences remain (otherwise → refuse: *"Rendered `<path>` still has template markers. Aborting; delete and re-run."*).
- No `TODO(template)` or `TODO(fill)` marker remains.

#### Stage 6 — Print chat summary

After every file is on disk, print:

```
━━━ tech/docs/ scaffolded for {{PROJECT_NAME}} v{{N}} ━━━

Shape (detected): {{ARCH_SHAPE}}
Detected from tech/: {{N_BACKEND}} backend + {{N_FRONTEND}} frontend + {{N_INFRA}} infra

Rendered:
  tech/docs/CLAUDE.md                                  ({{L}} lines)
  tech/docs/README.md                                  ({{L}} lines)
  tech/docs/project-architecture/v{{N}}.md             ({{L}} lines)
  tech/docs/standards/git.md                           ({{L}} lines)
  ...                                                  ...
  tech/docs/standards/{{microservice|monolith}}-layout.md   ({{L}} lines)

Total: {{N}} files, {{TOTAL_LINES}} lines.

Providers included:
  {{slot}} = {{slug}}
Providers dropped (null):
  {{slot}}

Warnings: {{count}}  {{list any ⚠️ from Stage 5 + prefix-drift + repo-scope-unknown}}
```

### Hard rules

- **Never read `product/docs/tech-plan/`.** That path is not the source
  of truth for this sub-op — the on-disk `tech/` directory is.
- **Never overwrite** a file whose content exceeds the 5-non-blank-line
  stub threshold. Halt and list the blocking files.
- **Never touch** anything under `tech/docs/` outside `CLAUDE.md` +
  `README.md` + `standards/` + `project-architecture/v<N>.md`. Do not
  touch `tech/docs/v<other_N>/` or any decisions/runbooks folders.
- **Never touch** anything under `tech/` outside `tech/docs/`. The
  engineering repos are owned by their own worktrees; this sub-op only
  reads their folder names.
- **Never assume ARCH_SHAPE.** Detect from disk. Two conflicting shapes
  (monolith folder AND other backend folders) → halt, do not pick.
- **Never emit both layout files.** Exactly one, chosen by the detected
  `ARCH_SHAPE`.
- **Never leave a `{{VAR}}` literal** in a rendered file. Better to
  halt than to ship half-rendered docs.
- **Never invent a provider-specific rule** that is not already in the
  template. Provider clauses are template-owned; the skill only fills
  the slug and gates the block.
- **Never touch the templates** at `Claude-Files/tech/docs/_templates/`.
  Read-only from this sub-op's perspective.
- **Never touch source-of-truth files** (`product/docs/product.md`,
  `product/docs/features/v<N>/all-features.md`). Read-only.
- **Never commit** on behalf of the user.

### What this sub-op is NOT

- Not for editing an existing populated `tech/docs/`. Once real content lives there, standards are owned by the tech-docs repo itself.
- Not for per-service PRD-TDDs. Those come from a later `/docs prd-tdd-*` (or equivalent scaffolder).
- Not for scaffolding actual code repos. This sub-op emits documentation only; the user (or a separate scaffolder) creates the repo folders first.
- Not a reader of `product/docs/tech-plan/`. That path is intentionally absent from this workflow.

### Ask-vs-fill policy

Silent by default. Detects, resolves, renders, writes.

**Exception** — halt and ask exactly once when:

- `LOCALE_MODE` cannot be unambiguously derived from `PRODUCT_LANGUAGES`.
- Mixed infra prefixes (`infra-*` AND `devops-*`) — pick one.
- Provider suggestions are presented — user confirms `Y` / edits / halts.
- Two rendered files would conflict (e.g. someone manually created
  `tech/docs/standards/microservice-layout.md` when `ARCH_SHAPE=monolith`
  — refuse and let the user decide).

Every other ambiguity resolves to the documented default; do not chain
questions.

---

## Mode behavior — merge vs overwrite

Shared semantics for the optional `::mode` argument on `product`,
`design-system`, `features`, and `tech-standards`. `business` (routed
into its own four sub-stages) and `tech-architecture` (chat-only, writes
nothing) do NOT accept `::mode`.

### No mode given — safe default

For each target path this sub-op writes:

- Path absent OR stub (≤ 5 non-blank lines) → render normally.
- Path populated (> 5 non-blank lines) → **refuse the whole run** and
  list every blocking path with the hint that the user can re-invoke
  with `::merge` or `::overwrite`.

This is the historical behavior — never silently clobber a real file.

### `::merge`

For each target path:

- **Absent** OR **stub (≤ 5 non-blank lines)** → render the template
  into the file. Every placeholder resolves as normal.
- **Populated (> 5 non-blank lines)** → probe the current section /
  row / bullet structure, then splice in only the pieces the template
  declares that are NOT already present. Concretely:
  - For section-headered templates (`## §1`, `## §2`, …) — walk the
    template heading order; every heading the user has → keep verbatim;
    every heading the user does not have → append the template's version
    of that whole section at the point it should live in the header
    order.
  - For table / list templates (feature catalog, checklist, glossary)
    — walk the template rows in declared order; every row already present
    (matched by primary key — feature name, term, whatever the template
    treats as identifier) → keep verbatim; every row missing → insert in
    declared order.
  - For scalar values inside a section (e.g. a `Language:` line) — never
    overwrite. If the user has it, keep it; if the user does not, insert
    the template's value.
- **Sub-op deltas:**
  - `product` — merges at section granularity. Missing Groups A–H get
    the interactive Q&A; present groups keep the user's answers verbatim.
  - `design-system` — merges at section granularity across the twelve
    section headers. Never re-derives tokens the user already set.
  - `features` — merges at row granularity. Only feature rows not yet
    listed (by feature name) get appended, with their classification
    computed as normal. Existing rows keep their `[x]` / `[ ]` decision
    exactly as the user has them.
  - `tech-standards` — merges at file granularity. Populated files
    (> 5 non-blank lines) are skipped verbatim; stubs and missing paths
    render from template.

**Never delete** a user-authored line. **Never rewrite** a value the user
already set. **Never reorder** existing content. **Report per file:**
`merged (<N> additions) <path>` OR `skipped (already complete) <path>`
OR `created <path>`. End-of-run summary counts each bucket.

### `::overwrite`

For each target path — render from template as if the file did not
exist. Every prior line is lost.

The user asked explicitly; skill does not second-guess. Every non-mode
refusal still applies (missing template, missing precondition file,
post-render `{{marker}}` still present). Report per file:
`overwrote <path>` OR `created <path>`. End-of-run summary counts
each bucket.

### Sanity checks (both modes)

- Post-render — every touched file passes the template-marker check
  (no `{{...}}` left). Failure → refuse: *"Rendered `<path>` still has
  template markers. Aborting; delete and re-run."*
- Every rendered file meets its minimum-line-count expectation from the
  sub-op's own checklist. Below-threshold files surface as
  `⚠️ suspiciously short: <path>` in the summary — not a refusal, but a
  visible warning the user should investigate.
- No stage / commit / push / MR in any mode. The user reviews the
  working tree and commits themselves.
