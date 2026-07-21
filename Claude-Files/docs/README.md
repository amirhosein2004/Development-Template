# docs — Heptapeak umbrella standards

The umbrella standards repo for the **Heptapeak** (شرکت هفت فراز فناوری) company website program. It holds the cross-repo rules every other Heptapeak repo follows — currently just the git baseline (`standards/git.md`), with documentation style, ADR templates, and other shared rules expected to land here over time. It does not host content — brand assets, competitor research, product scope, and engineering documentation each live in their own dedicated repo.

- **GitLab remote:** `git@gitlab.com:heptapeak-website/docs.git`
- **Default branch:** `main`

## What's inside

- `standards/git.md` — the cross-repo git baseline. Covers repository hygiene (`.gitignore`, `.gitattributes`), branching strategy (long-lived branches, three-segment branch names, short-lived working branches), branch lifecycle automation (auto-delete on merge, stale-branch reaper, fetch-prune-by-default), commit conventions (typed commits with priority order, subject discipline, body format, breaking changes, footer references, revert format), merge strategy (squash / merge-commit / rebase-merge with the chosen default), MR description template (TLDR, summary, test plan, validation table), MR size limits with engineering thresholds and a qualitative override, MR review format (two-section flat output with 🔴 blocking and 🟡 nice-to-have), shared `.gitconfig` snippet, recovery playbook, antipatterns, and a quick-reference card.
- `.gitattributes` — repo-level text/binary defaults that match §1.2 of `standards/git.md`.
- `.gitignore` — OS and editor noise exclusions that match §1.1 of `standards/git.md`.

## Sibling repos in the workspace

The umbrella container at `/heptapeak-website/` is not a git repo — it just hosts four checkouts as siblings:

- `docs/` — this repo, the cross-repo standards.
- `business/docs/` — brand identity, competitor research, founding charter (`gitlab.com:heptapeak-website/business/docs.git`).
- `product/docs/` — versioned feature catalogue, the v1 scope contract (`gitlab.com:heptapeak-website/product/docs.git`).
- `tech/docs/` — engineering documentation (`gitlab.com:heptapeak-website/tech/docs.git`), currently near-empty.

Each of those repos has its own `CLAUDE.md` and `README.md` and points back here for git conventions. Repo-local rules (brand SVG-only, "only `[x]` ships," engineering deployment branches) live in the relevant repo, not here.

## How to contribute

This repo lives outside any monorepo. Cross-repo git conventions are defined here in `standards/git.md` — read that file before opening an MR (and rest assured the same rules apply when changing the file itself). The flow is the standard worktree → MR → squash-merge cycle:

1. From the main checkout, refresh `main`: `git checkout main && git pull origin main`.
2. Create a worktree from fresh `main` under `tmp/worktrees/umbrella-docs` on a new branch named `<type>/<short-kebab-description>` (e.g. `document/onboarding-refresh`, `feature/standards/add-documentation-style-guide`).
3. Make your changes in the worktree. Keep one concern per branch — a standards change is high blast radius; do not bundle unrelated standards together.
4. Push the branch and open a Merge Request to `main` on GitLab, using the MR template from `standards/git.md` §6.
5. Merge with **squash + remove source branch**. Do not force-push to `main`. Do not use `--no-verify`.
6. Back in the main checkout, pull and remove the worktree: `git checkout main && git pull origin main && git worktree remove tmp/worktrees/umbrella-docs`.

## Context worth knowing

- A standards change is high-blast-radius — every repo that pulls from `standards/git.md` is affected the next time a contributor reads it. MR descriptions should call out which repos and existing workflows are touched so reviewers can sanity-check the downstream impact.
- The engineering-only git layer is reserved for `tech/docs/standards/git.md` and does not exist yet. Until it lands, this repo's `standards/git.md` is the sole git source of truth for every Heptapeak repo, including `tech/docs/`.
- Persian-language considerations (`asasnameh.md` direction, brand bilingualism) belong in the repos that host that content, not in cross-repo standards. The umbrella stays language-neutral.
