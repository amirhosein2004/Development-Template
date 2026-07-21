# business/docs — agent instructions

This repo owns the **business material** behind **{{PROJECT_NAME}}**: brand identity assets (opt-in), the competitor research corpus, and canonical legal/founding documents (opt-in). It does **not** own product scope — what ships in a release lives in `product/docs/features/v{N}/`. It does **not** own engineering or implementation documentation — that belongs in `tech/docs/`. It does **not** own cross-repo standards — those live in the workspace umbrella `docs/` repo under `docs/standards/`. If a change is about brand, market research, or company legal documents, it belongs here; anything else goes elsewhere.

## Source of truth

The product's identity, positioning, features, non-features, and market context all live in **`../product/docs/product.md`**. That file is the single source of truth. This CLAUDE.md is derived from it by `/business-audit init`.

**When positioning changes, edit `product/docs/product.md` first**, then re-run `/business-audit init` to refresh this file and `README.md`. Do not edit positioning here directly — it will be overwritten on the next refresh.

## Positioning (mirrored from `product/docs/product.md § 9`)

{{POSITIONING}}

Every strategic-priority score in `feature-catalog.md` and every "borrow / gap / threat" call in a per-competitor `analysis.md` must trace back to this paragraph.

## Repo metadata

- **Default branch:** `main`
- **Cross-repo standards:** live in the umbrella repo at `docs/standards/git.md`. Read it before any commit, branch, or MR — it defines branch naming, commit conventions, MR templates, merge strategy, and the antipatterns that apply here.

## Where things live

- `competitor-analysis/AUDIT_PROMPT.md` — the constant. Project-agnostic spec (dimensions, per-dimension record format, scoring, deliverables). Loads project-specific values from `../product/docs/product.md` at runtime. Do not edit during a snapshot run; if the spec itself needs to evolve, do it in its own MR before the next snapshot date.
- `brand/` — {{PROJECT_NAME}} brand assets. Logos are **SVG only**. Do not add raster logo formats here.
- `documents/` — canonical legal/founding documents. Treat as authoritative text — **do not paraphrase, translate, or summarize** into the file itself; if a derived summary is needed, put it in a separate document and cite the article number.
- `competitor-analysis/` — competitor research, snapshot-dated. Two shapes:
  - **Per-competitor snapshots** at `<segment>/<slug>/<YYYY-MM-DD>/analysis.md` (plus `screenshots/` and `raw/`). Segments group competitors by market posture (see `product/docs/product.md § 6`).
  - **Top-level synthesis** at `<YYYY-MM-DD>-{feature-catalog,comparison-and-ranking,roles}.md`. Each synthesis is derived from a fixed set of per-competitor `analysis.md` files under the same snapshot date. Regenerating a synthesis produces a new dated file; do not overwrite the prior one.
- `_templates/` — copy-and-fill starting points. Never edit these when producing a real artifact; copy first, then edit the copy.

## Snapshot dating

- Per-competitor audits: `<segment>/<slug>/<YYYY-MM-DD>/`. Re-audits get a new dated folder. Old audits are immutable except for transcription corrections.
- Top-level synthesis files: `<YYYY-MM-DD>-<kind>.md`. Two syntheses of the same kind on the same date disambiguate with `<YYYY-MM-DD>-<kind>-<slug>.md`.
- Never `README.md` for content, never `v1.md`, never a bare undated `feature-catalog.md`. The filename is the freshness signal.

## Repo-specific conventions

- **Every score is 0–3** in per-competitor audits (0 absent, 1 basic, 2 solid, 3 best-in-class) and **1–10** in the feature catalog (strategic priority to {{PROJECT_NAME}}). Do not invent new scales.
- **Every synthesis file lists its source set** in frontmatter (`source: competitor-analysis/*/{slug}/YYYY-MM-DD/analysis.md`) and its scoring axis in a leading section. A reader must be able to reconstruct the snapshot from the synthesis alone.
- **Unverified observations are excluded** from feature catalog and ranking. Mark them 🔴 in the per-competitor audit and re-run once verified.
- **Stubs (unreachable / parked origins) are listed explicitly** in every synthesis so the snapshot is exhaustive, but they are excluded from averages and rankings.
- **{{LOCALE_RULES}}** — e.g. Persian/RTL content: preserve direction and Persian numerals in source; do not auto-convert to Latin numerals or LTR. Machine-facing feeds (JSON-LD, sitemap, RSS) emit ASCII digits and Gregorian dates.

## Workflow (worktree → MR → squash-merge)

1. Read the umbrella's `docs/standards/git.md` (and any repo-specific standards under `standards/` once they exist).
2. From the main checkout: `git checkout main && git pull origin main`.
3. Create a worktree from fresh `main` under `tmp/worktrees/business-docs` on a new branch named `<type>/<short-kebab-description>` (e.g. `document/onboarding-refresh`, `feature/audit/YYYY-MM-DD-snapshot`).
4. Make changes in the worktree only. One concern per branch; one MR per branch.
5. Push the branch and open an MR back to `main` using the MR template from the umbrella standards.
6. Merge with **squash + remove source branch**. Do not force-push. Do not use `--no-verify`.
7. Back in the main checkout: `git checkout main && git pull origin main`, then `git worktree remove tmp/worktrees/business-docs` and delete the local branch.

## Hard rules (do not violate)

- **No `Co-Authored-By:` footers** on commits or MR descriptions.
- **No references to `CLAUDE.md` or `README.md` from inside content documents** (anything under `brand/`, `competitor-analysis/`, `documents/`). These two files are derived from the documents — referring back creates a circular dependency. If content is needed inside a document, copy it inline.
- **No direct push to `main`.** Every change goes through an MR.
- **No committed secrets** (API keys, tokens, credentials).
- **No overwriting a past-dated audit or synthesis.** Add a new dated file instead.
- **No paraphrase of canonical legal documents** under `documents/`. Correct transcription errors only.
- **No editing positioning here.** Edit `../product/docs/product.md` first, then re-run `/business-audit init`.

## Temporary scratch files

For ad-hoc markdown drafts that should not be committed, use the workspace-level `tmp/` directory. Worktrees live under `tmp/worktrees/`.
