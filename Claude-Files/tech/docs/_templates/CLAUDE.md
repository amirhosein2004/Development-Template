---
title: "{{PROJECT_NAME}} — tech/docs onboarding"
category: "tech"
last_updated: "{{YYYY-MM-DD}}"
owner: "{{PROJECT_NAME}} / <human or model>"
---

# {{PROJECT_NAME}} — `tech/docs` onboarding

> **Fill me in.** This file is the entry point for any agent working inside
> `tech/docs/`. Keep it short — link outward via the conditional-reading
> table; do not inline standards content here.

## 1. Positioning (verbatim, from `product/docs/product.md` § 9)

{{POSITIONING}}

## 2. Repo metadata

- **Project name:** {{PROJECT_NAME}}
- **Project slug:** {{PROJECT_SLUG}}
- **Architecture shape:** {{ARCH_SHAPE}}
- **Default branch (this repo):** `main`
- **Default branch (engineering repos under `tech/`):** {{DEFAULT_BRANCH}}
- **Branch chain (engineering repos):** {{DEV_BRANCH_CHAIN}}
- **Locale mode:** {{LOCALE_MODE}}
- **Calendar:** {{CALENDAR}}
- **Digit rules:** {{DIGIT_RULES}}

## 3. Conditional reading

| When the prompt is about… | Read |
|---|---|
| Platform architecture, {{OWNER_TERM}} map, feature → {{OWNER_TERM}} map | `@project-architecture/v1.md` |
| Engineering standards (all) | `@standards/` |
| Feature catalog (only `[x]` items in scope) | `@../../product/docs/features/v1/all-features.md` |
| Per-repo onboarding when working in a specific repo | `@<repo>/CLAUDE.md` |

## 4. Hard rules

- No `Co-Authored-By:` footers on commits.
- Documents must not reference `CLAUDE.md` / `README.md` from inside content.
- No direct push to `main`. Worktree → MR → squash-merge.
- No committed secrets.
- Only `[x]` features in the feature catalog are in scope.
