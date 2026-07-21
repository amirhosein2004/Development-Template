# docs — agent instructions (umbrella standards repo)

This is the **umbrella standards repo** for the Heptapeak (شرکت هفت فراز فناوری) company website program. It owns the cross-repo rules that every other Heptapeak repo follows — git conventions, MR templates, merge strategy, antipatterns — and nothing else. It does **not** own brand assets (those live in `business/docs`), competitor research (also `business/docs`), product scope (`product/docs`), or engineering documentation (`tech/docs`). If a rule applies to two or more repos, it lives here; if it applies to one repo, it stays in that repo.

## Repo metadata

- **Default branch:** `main`
- **GitLab remote:** `git@gitlab.com:heptapeak-website/docs.git`
- **Workspace umbrella container:** sibling-checkout at `/heptapeak-website/`, alongside `business/docs/`, `product/docs/`, `tech/docs/`. The container itself is **not** a git repo — it just hosts the four checkouts and a `tmp/` area.
- **This repo IS the standards directory** referenced from the other three repos' onboarding files. Its `standards/git.md` is the cross-repo git source of truth; other standards files will land here over time.

## Where things live

- `standards/git.md` — cross-repo git conventions. Branching strategy, commit conventions, merge strategy, MR description template, MR size limits, MR review format, shared git config, recovery playbook, antipatterns, and a quick-reference card. Read this before any commit, branch, or MR in any Heptapeak repo.
- `.gitattributes` — universal text/binary defaults (LF normalization for source-of-truth text formats; binary for embedded assets). Mirrors §1.2 of `standards/git.md`.
- `.gitignore` — OS and editor noise exclusions. Mirrors §1.1 of `standards/git.md`.

That is the entire contents at the moment. Future standards files (documentation style, ADR template, brand voice if reused across repos, etc.) land under `standards/` alongside `git.md`. Per-repo standards (engineering-only, brand-only) do **not** land here — they go in the relevant repo's own `standards/` directory.

## Repo-specific conventions

- **Cross-repo only.** A rule lands here only if it applies to two or more Heptapeak repos. Single-repo rules belong in that repo (e.g. brand SVG-only rule → `business/docs`; "only `[x]` features ship" → `product/docs`; deployment-branch flow → `tech/docs/standards/git.md` once introduced).
- **Layering is one-way.** Repo-local standards extend the umbrella standards; they do not contradict them. When the engineering layer arrives at `tech/docs/standards/git.md`, this repo's `standards/git.md` documents what carves out from the cross-repo baseline (and which side wins for which concern — see `standards/git.md` itself for the resolution rule).
- **Treat `standards/` files as canonical.** Other repos' `CLAUDE.md` / `README.md` pull from here by reference (the human-facing pointer "see `docs/standards/git.md`"), not by copy. Updates here propagate by the next time a contributor reads the onboarding file.

## Workflow (worktree → MR → squash-merge)

1. Read `standards/git.md` itself — every rule that applies to this MR is already documented there.
2. From the main checkout: `git checkout main && git pull origin main`.
3. Create a worktree from fresh `main` under the workspace-level `tmp/worktrees/umbrella-docs` on a new branch named `<type>/<short-kebab-description>` (e.g. `document/onboarding-refresh`, `feature/standards/add-documentation-style-guide`). For workspace-level multi-repo passes, use `document/root/<2-4-word-description>`.
4. Make changes in the worktree only. One concern per branch; one MR per branch. A standards change is high-blast-radius — bundle the change with the corresponding updates to per-repo onboarding when those references are tightly coupled, but never bundle two unrelated standards changes.
5. Push the branch and open a GitLab MR back to `main`, using the MR template from `standards/git.md` §6.
6. Merge with **squash + remove source branch**. Do not force-push. Do not use `--no-verify`.
7. Back in the main checkout: `git checkout main && git pull origin main`, then `git worktree remove tmp/worktrees/umbrella-docs` and delete the local branch.

## Hard rules (do not violate)

- **No `Co-Authored-By:` footers** on commits or MR descriptions.
- **No content from the other repos.** Brand assets, competitor research, feature catalogues, architecture docs do not belong here. If you find yourself adding them, the change belongs in another repo.
- **No direct push to `main`.** Every change goes through an MR.
- **No committed secrets** (API keys, tokens, credentials).
- **A standards change must be explicit about blast radius.** The MR description should call out which repos and which existing workflows the new or changed rule affects, so reviewers can sanity-check downstream impact.

## Temporary scratch files

For ad-hoc markdown drafts that should not be committed, use the workspace-level `/heptapeak-website/tmp/` directory. Worktrees live under `tmp/worktrees/`.
