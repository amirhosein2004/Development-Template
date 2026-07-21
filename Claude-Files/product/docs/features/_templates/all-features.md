---
title: "{{PROJECT_NAME}} — all features + v{{VERSION}} selection"
version: "v{{VERSION}}"
scope: "{{SCOPE_ONELINE}}"
source: "{{SOURCE_FEATURE_CATALOG_PATH}}"
last_updated: "{{YYYY-MM-DD}}"
---

# {{PROJECT_NAME}} — all features + v{{VERSION}} selection

> **Source.** Features extracted and consolidated from `{{SOURCE_FEATURE_CATALOG_PATH}}`. Scores (1–10) represent strategic priority for {{PROJECT_NAME}}, carried over from the source catalog without modification.
>
> **Legend.**
> - `[x]` — **selected for v{{VERSION}}**
> - `[ ]` — deferred to a later version
> - `[~]` — reserved slot (empty in v{{VERSION}}, materializes later without breaking the public interface)
> - **Score** shown after each line, followed by a one-sentence description.
>
> **v{{VERSION}} cut philosophy.** {{VERSION_CUT_PHILOSOPHY}}
>
> **v{{VERSION}} roles in scope ({{N_IN_SCOPE}} of {{N_TOTAL}}).** {{ROLES_IN_SCOPE}}
>
> **Hard rules for this catalog:**
> - Only `[x]` items are in scope for v{{VERSION}}. Anything not `[x]` does not ship.
> - Score is inherited from the competitor feature catalog. Do not re-score here.
> - When a feature is renamed or absorbed into another, add a one-sentence deferral / absorption note referencing the destination.
> - Adding a new feature line requires a competitor-catalog citation OR a positioning-anchored rationale in `product/docs/product.md § 9`.

---

## 1. {{DIMENSION_1_NAME}}

- [ ] **{{FEATURE_NAME}}** ({{OPTIONAL_QUALIFIER}}) — **{{SCORE}}** — {{ONE_SENTENCE_DESCRIPTION}}

## 2. {{DIMENSION_2_NAME}}

- [ ] **{{FEATURE_NAME}}** — **{{SCORE}}** — {{ONE_SENTENCE_DESCRIPTION}}

## 3. {{DIMENSION_3_NAME}}

- [ ] **{{FEATURE_NAME}}** — **{{SCORE}}** — {{ONE_SENTENCE_DESCRIPTION}}

## 4. {{DIMENSION_4_NAME}}

- [ ] **{{FEATURE_NAME}}** — **{{SCORE}}** — {{ONE_SENTENCE_DESCRIPTION}}

<!-- Add one section per capability dimension from the source catalog. Bullets ordered by score desc within each dimension. Keep `[x]` and `[ ]` distinct — never quietly upgrade a `[ ]` without a scope note. -->

---

## Absorbed / superseded features

Features present in the source catalog that have been folded into another feature in this version. Not deletions — inheritance notes.

- **{{FEATURE_ABSORBED}}** → absorbed into **{{HOST_FEATURE}}** — {{RATIONALE}}

## Deferred with reason

Features scored ≥ 7 that are deferred anyway. Each carries a one-sentence rationale so future readers know why.

- **{{FEATURE_DEFERRED}}** ({{SCORE}}) — {{DEFERRAL_RATIONALE}}
