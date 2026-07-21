---
name: mr
description: |
  Single entry point for everything MR-shaped in the workspace. Assumes the standard workspace shape — `business/`, `product/`, `tech/`, and a docs container (`<config-dir>`, usually `docs/`, sometimes `agent-config/`) at the workspace root — with any number of git repos under each (count varies per project; `<repo-path>` accepts **any** existing checkout, not a fixed whitelist). First positional argument is `<open|ship|format>`; for `open` and `ship` a scope arg (`touched|all|current|<repo-path>`) is required.

  - `open <scope>` — stage explicit paths, conventional-commit, push, open MR via `glab` and stop after the report.
  - `ship <scope>` — same as `open`, plus wait-for-mergeable, squash-merge, ff-pull the repo's default branch, clean up the worktree/branch.
  - `format` — the operative reference for branch name, commit subject, MR title, MR body shape (four sections: TLDR / Summary / Test Plan / Validation), mirror/hotfix variants (`fix/*` fan-out per the workspace's declared promotion chain), hard rules, and a self-check. Other skills load this via `[[mr]]` before authoring any MR.

  Use when the user asks to "open an MR", "stage / commit / push and open a merge request", "ship this to develop", "merge and pull back", "fan out a hotfix", "just tell me the MR body shape", "how do I write the MR description", or invokes `/mr`. Always load this before authoring any MR body across the workspace.

  If the first arg is missing or not one of `open` | `ship` | `format`, stop and ask. For `open` and `ship`, if the scope arg is missing or not `touched` | `all` | `current` | `<repo-path>`, stop and ask — never default, running `all` by accident is too costly to undo.

  Enforces (generic): no `Co-Authored-By:` footers, no direct push to a protected branch (per the workspace's own git standards), no bulk staging (`git add -A/--all/./*`), no `--no-verify`/`--no-gpg-sign`, no secrets, only `[x]` features from `product/docs/features/v<N>/all-features.md` (highest `v<N>` present) in scope. `bash-guard.sh` blocks the bulk-staging / verify-bypass / direct-push offenses at the tool layer. Project-specific hard rules (schema invariants, locale rules, scope gates, reserved-slot guards) live in the workspace's per-project sibling hooks under `<config-dir>/.claude/hooks/`, layered on top of the two generic guards this bundle ships — `/mr` respects whatever those hooks reject and surfaces the block message unchanged.
---

# mr — MR flow

Single entry point for MRs across every workspace repo. Assumes the standard shape (`business/`, `product/`, `tech/`, plus a docs-container `<config-dir>` — typically `docs/`), discovered at call time — no hardcoded repo list. `<repo-path>` accepts any existing checkout by workspace-relative path; the whitelist is out.

```
/mr <open|ship> <touched|all|current|<repo-path>>
/mr format
```

| Sub-cmd | Anchor | One-liner |
|---|---|---|
| `open` | [`## open`](#open) | Stage explicit paths, conventional-commit, push, open MR — stop after the report. |
| `ship` | [`## ship`](#ship) | Same as `open` plus wait-for-mergeable, squash-merge, ff-pull the repo's default branch, clean up the worktree/branch. |
| `format` | [`## format`](#format) | The operative MR/branch/commit shape reference — pre-flight chain, body template, mirror/hotfix variants, hard rules, self-check. |

If the first arg is missing or not one of `open` | `ship` | `format`, stop and ask — never default. For `open` and `ship`, if the scope arg is missing or not one of `touched` | `all` | `current` | `<repo-path>`, stop and ask.

## Workspace shape

- `<workspace-root>/business/docs/`
- `<workspace-root>/product/docs/`
- `<workspace-root>/tech/docs/`
- `<workspace-root>/tech/*/` — every immediate subdirectory of `tech/` that is a git checkout (count varies per project).
- `<workspace-root>/<config-dir>/` — the docs container that carries this bundle's `.claude/` folder (`docs/` by default; discover by finding the workspace-root child whose `.claude/` matches this bundle's shape).
- `<workspace-root>/scripts/` — **optional** workspace-tooling folder holding bootstrap / initializer / cross-repo maintenance scripts. Not every project ships one — always probe before enumerating. Two on-disk layouts, both valid:
  - **Single-repo layout** — `<workspace-root>/scripts/.git` exists (directory or file). `scripts/` is itself the repo; workspace-relative path is `scripts`.
  - **Multi-repo layout** — `<workspace-root>/scripts/<name>/.git` exists for one or more subdirectories. Each such subdirectory is an independent repo; workspace-relative path is `scripts/<name>` (e.g. `scripts/initializer`).
  - If neither `scripts/.git` nor any `scripts/*/.git` is present → `scripts/` is either absent or empty-of-git; skip it entirely.

  Scripts repos participate in `touched` / `all` / `<repo-path>` scopes exactly like any other repo — same per-repo default-branch resolution (`git symbolic-ref --short refs/remotes/origin/HEAD`, strip `origin/`), same worktree + commit + push + `glab mr create` flow, same MR body shape, same protected-branch protection. Discovery / candidate-list steps in each sub-op below must probe `scripts/` and expand it into whichever layout is present. `current` scope naturally picks a scripts repo when cwd is inside one.

## open

Open MRs across the workspace. Scope selects candidates:

- `touched` — only repos this session edited. Source of truth is conversation context. Empty list → stop with "nothing touched this session".
- `all` — scan every discovered workspace repo (count varies per project) and open MRs wherever there are pending changes.
- `current` — single-repo mode targeting the repo containing cwd. If cwd isn't inside a workspace repo, stop and ask.
- `<repo-path>` — single-repo mode targeting **any** workspace repo checkout by workspace-relative path. Validate by existence — `<workspace-root>/<repo-path>/.git` must exist (dir for a clone, file for a worktree). Missing / non-git path → stop and ask. Do **not** enforce a fixed whitelist.

Target branch per repo — resolve at call time via `git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD` (strip `origin/` prefix). Do **not** hardcode. Convention across the standard workspace shape: docs-container repos on `main`, engineering repos under `tech/` on `develop` (promotion `develop → staging → main`) — but every repo self-declares via its remote HEAD, and the exact promotion chain is declared in `<workspace-root>/tech/docs/standards/git.md`.

### Repo discovery (used by `all` only)

Discover at call time — do **not** hardcode. Single listing:

```sh
ls -1d <workspace-root>/<config-dir> \
        <workspace-root>/business/docs \
        <workspace-root>/product/docs \
        <workspace-root>/tech/docs \
        <workspace-root>/tech/*/ 2>/dev/null
```

Then filter to entries whose `.git` exists (a directory for a clone, a file for a worktree). Any future repo surfaces automatically without editing this skill.

### Hard rules (every mode, every scope)

- No `Co-Authored-By:` footers.
- No direct push to a protected branch (per the workspace's own git standards — typically `main`, `staging`, `develop`).
- No bulk staging (`git add -A/--all/./*`).
- No `--no-verify` / `--no-gpg-sign`.
- No secrets, no `.env*`, no credentials, no private keys, no API tokens.
- Only `[x]` features from `<workspace-root>/product/docs/features/v<N>/all-features.md` (discover `<N>` as the highest `v<N>` directory present under `product/docs/features/`) are in scope. A `[ ]` feature reaching the diff is a stop-and-ask.

The bulk-staging / verify-bypass / direct-push offenses are also enforced by `.claude/hooks/bash-guard.sh`. If the hook blocks a call, fix the offense — never bypass.

**Project-specific hard rules** — schema invariants (e.g. "no `body_html` in the content service"), locale rules (e.g. "no Persian digits in machine feeds"), scope gates (e.g. "no money columns until v<N>"), reserved-slot guards (e.g. "no scaffolding for a reserved service slot") — live in the workspace's own per-project sibling hooks under `<config-dir>/.claude/hooks/`, layered on top of the two generic guards this bundle ships (`bash-guard.sh`, `write-edit-guard.sh`). `/mr` respects whatever those hooks reject and surfaces the block message unchanged.

Branch / commit / title / body follow [`## format`](#format).

### Step 1 — build the candidate-repo list

- **`touched`**: from session context. Empty → stop.
- **`all`**: one `Bash` call per repo, in parallel — `git status --porcelain`, `git branch --show-current`, `git rev-list --left-right --count origin/<default>...HEAD` (per-repo default), `glab mr list --source-branch <branch>`. Absolute paths so calls stay independent; do not `cd`.
- **`current`**: repo containing cwd.
- **`<repo-path>`**: that one repo.

Qualifying rule:

- `open` — repo qualifies if any checkout has a dirty working tree or a non-protected branch with commits ahead of `origin/<default>` and no MR yet open. Clean-default-only repos → "clean".
- `ship` — same, plus branches whose MR is already open (they get merged).

Single-repo scopes with only a clean default branch → stop with "nothing to commit".

### Step 2 — verify clean baseline (single-repo scopes only)

Before staging in `current` | `<repo-path>` scope:

```sh
git -C <workspace-root>/<repo> fetch origin <default>
git -C <workspace-root>/<repo> status --porcelain
git -C <workspace-root>/<repo> rev-parse --abbrev-ref HEAD
```

If currently on the default branch and the working tree is dirty, create a worktree from `origin/<default>` and **move** the changes (never copy):

```sh
git -C <workspace-root>/<repo> worktree add ../tmp/worktrees/<short-name> -b <branch-name> origin/<default>
```

Both steps mandatory:

1. **Re-author or transplant** the changes inside the worktree (Write/Edit against the worktree path, or stash-and-pop with explicit paths).
2. **Restore the original checkout** to `working tree clean` — `git restore --staged --worktree -- <paths>` for tracked files and `git clean -fd -- <untracked paths>` for new files. Verify with `git status --porcelain` returning empty.

Skipping step 2 leaves the same diff alive in two places; `git pull --ff-only` on the main checkout will refuse after the squash-merge.

If already on a non-default branch (likely a worktree), continue in place.

For multi-repo scopes (`touched` | `all`), if a candidate repo has uncommitted changes on its default branch, run the same auto-worktree + two-step move for that repo — never silently skip. Mark it in the report as `<subject> (auto-worktree)`.

### Step 3 — open (and optionally merge) MRs

Per candidate repo, inside the worktree/branch:

- `git status` + `git diff` to confirm staged scope.
- Stage explicit paths.
- `git commit -m "<conventional-commit subject>"` (`type(scope): subject`). Match the tone of `git log -n 10`. No `Co-Authored-By:`. No `--no-verify` / `--no-gpg-sign`.
- `git push -u origin HEAD`.
- `glab mr create --target-branch <default> --title "<commit subject>" --description "$(cat <tmp-body>)" --remove-source-branch --squash-before-merge` (`<default>` = the target repo's default branch). In single-repo scopes also pass `--repo <workspace-root>/<repo>` and `--source-branch <branch-name>`. **Never `--fill`.** Body follows [`## format`](#format) — four sections, Validation ≥ 3 rows on surface changes, no agent attribution; mirror MRs lead `## TLDR` with `**Mirrors:** [repo!N](url).`; `fix/*` hotfix MRs end `## TLDR` with `**Hotfix paired MRs:** !A (→…), !B (→…).`
- In `ship`, if an MR is already open for the source branch, **reuse it** — no duplicate.

Run repos **in parallel** where independent (one `Bash` call per repo). Sequence only for mirror MRs that need the source MR's URL.

### Step 4 — guardrails

- Candidate branch is a protected branch declared in the workspace's git standards (typically `main` / `staging` / `develop`) → skip with a reason (never commit on a protected branch).
- `glab` missing/unauth → stop the batch (no `gh` fallback).
- Nothing staged and nothing to stage → skip with "nothing to commit" (no empty commit).
- `open` mode `all` scope with a pushed branch that has no MR → still open one.

### Reporting

Single-repo scopes → 5-line block:

```
Repo:        <repo>
Branch:      <branch-name> → <default>
Commits:     <n>
MR:          <web_url>
Worktree:    <relative-path>  (or "Merged: <sha>" in ship mode)
```

Multi-repo scopes → markdown table.

**`open` columns:** Repo, Branch, Status (`**opened**` / `skipped` / `**failed**`), MR, Reason.

**`ship` columns:** Repo, Branch, Status (`**merged**` / `opened (blocked)` / `skipped` / `**failed**`), MR, HEAD (new SHA on the repo's default branch), Reason.

Header line: `## /mr <mode> <scope> — <YYYY-MM-DD>`. Totals line below. `**Failures**` sub-section per failure with the exact error.

In `all` scope, if more than 6 repos are skipped as `clean`, collapse them into one `(clean repos)` row with the comma-joined repo list — keeps the table scannable regardless of workspace size.

`open` mode → stop after the report, no merge. `ship` mode continues to [`## ship`](#ship).


## ship

Runs the full [`## open`](#open) flow, then:

### Merge phase

Per candidate repo, after the open phase:

- **Wait for mergeable.** CI green, no blocking discussions. Blocked → surface the blocker, skip the merge for that repo, keep going. **Never force-merge.**
- **Merge:** `glab mr merge <iid> --squash --remove-source-branch --yes`.
- **Sync:** switch back to the **main checkout** (not the worktree). `git checkout <default> && git pull --ff-only` (`<default>` = repo's default branch).
- **Clean up:** `git worktree remove tmp/worktrees/<short-name>` and `git branch -d <branch>` if it still exists.

Reuse-not-duplicate: an already-open MR is merged, not re-opened.

### Reporting deltas

`ship` mode columns and totals (`**merged**` / `opened (blocked)` / `skipped` / `**failed**`); failure stages widen to `commit` / `push` / `open` / `merge` / `pull` / `cleanup`. Single-repo 5-line block replaces `Worktree:` with `Merged:` + new HEAD SHA.

## format

The operative reference. Other skills load via `[[mr]]` for the body shape. Standards behind it: the cross-repo git baseline at `<config-dir>/standards/git.md` (typically §6 — cross-repo MR description template) and the engineering deltas at `<workspace-root>/tech/docs/standards/git.md` (hotfix multi-MR, the `feature`-MR-needs-a-test rule). If this section and the standards ever drift, the standards win.

### 1. Pre-flight chain

```
branch:   <type>/<scope>/<2-4-word-description>
commit:   <type>(<scope>): <imperative subject>           ≤ 50 chars soft / 72 hard
title:    <commit subject>                                literally identical
body:     four sections — TLDR / Summary / Test Plan / …
```

If those four don't line up, fix the *branch* first — everything cascades.

### 1.1 Branch/commit types (priority order — pick first match)

| Branch type | Commit type | When |
|---|---|---|
| `document/...` | `document` | Docs-only change. Default in docs repos. |
| `bugfix/...` | `bugfix` | Regular bug fix on the mainline. In docs repos: the doc said something incorrect and is now correct. |
| `fix/...` *(engineering only)* | `bugfix` | Hotfix workflow — see §6. |
| `test/...` *(engineering only)* | `test` | Test additions / modifications, no behavior change. |
| `CICD/...` | `CICD` | CI/CD / build / pipeline config. |
| `feature/...` | `feature` | New functionality, new page, new spec section. |
| `maintenance/...` | `maintenance` | Refactor, perf, deps, style, link rot, restructure. |
| `release/...`, `experiment/...` | mixed | Promotion / spike — use whichever type each commit needs. |

`revert` is commit-only — no `revert/*` branch; reverts live on a regular shipping branch.

### 1.2 Branch scopes

Scope names are declared per repo in the workspace's git standards. Convention across the standard shape:

- Docs repos (docs container, `business/docs`, `product/docs`, `tech/docs`) — the doc tree touched: `root`, `glossary`, `repo-map`, `standards`, `competitor-analysis`, `brand`, `users`, `features`, `uiux`, `v<N>`.
- Backend repos (`tech/backend-*`, incl. any shared-logic library) — mirrors `src/` layout: `root`, `migrations`, `docker`, `scripts`, `tests`, `docs`, `src_infra_platform`, `src_infra_integrations_<client>`, `src_api`, `src_api_v<N>_<entity>`, `src_domain_<entity>`, `src_consumers_<event>`, `src_cronjobs_<job>`. Full list in `<workspace-root>/tech/docs/standards/git.md`.
- Frontend repos (`tech/frontend-*`) — `root`, `docs`, `public`, `scripts`, `tests`, `src_features_<area>_<feature>`, `src_shared_<subsystem>`, `src_lib_<subsystem>`.
- Infra repos (`tech/infra-*`) — `root`, `docker-compose`, `config`, `scripts`, `docs`.
- **Workspace-level multi-repo passes** — scope is `root`. Branch is `document/root/<2-4-word-description>` in every repo of the pass.

Description is 2–4 lowercase hyphen-separated words. No spaces / underscores / camelCase. Aim < 60 chars total.

### 1.3 Commit subject

Imperative mood, no leading capital after `):` (proper nouns excepted), no trailing period, ≤ 50/72 chars, one concern. If `and` sneaks in, split. Breaking → `type(scope)!:` subject or `BREAKING CHANGE:` footer.

### 2. Target branch

Per repo — do **not** hardcode; resolve at call time via `git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD` (strip `origin/`):

- Docs-container repos (docs container, `business/docs`, `product/docs`, `tech/docs`) → typically `main`.
- Engineering repos under `tech/` (`backend-*`, `frontend-*`, `infra-*`, any shared library) → typically `develop`, per the promotion flow declared in `<workspace-root>/tech/docs/standards/git.md` (commonly `develop → staging → main`). Promotion MRs use merge-commit and are out of scope here.
- `fix/*` hotfix branches target multiple protected branches simultaneously — see §6.
- Any future repo self-declares via its remote HEAD — no code change here.

The exact promotion chain (which branches are protected, in what order they promote, what merge strategy each hop uses) is declared in `<workspace-root>/tech/docs/standards/git.md`; the skill respects whatever is declared there.

### 3. MR title

Literally the commit subject. No prefix / suffix / ticket unless already in the subject. On squash of many commits, the title is still the squash subject the operator wants on the default branch.

### 4. MR body

Four required sections, headings verbatim:

```markdown
## TLDR

- **Problem:** one line — what's wrong or what's needed.
- **Solution:** one line — what this MR does.
- **How to validate in under 1 minute:** exact steps a reviewer runs.
- **Merge Risk Score:** High / Medium / Low
- **Hotfix paired MRs:** (engineering-only — `fix/*` MRs) cross-link the set, e.g. `!123 (→develop), !124 (→staging)`. Omit on non-hotfix MRs.

## Summary

What changed and why (bullets).

## Test Plan

What was tested locally and what the reviewer should test.
- Engineering: which commands you ran — run / lint / type / suite — and the outcomes.
- Docs / design: render preview, link check, screenshot diff.

## Validation

| # | Action | Expected | Actual |
|---|--------|----------|--------|
| 1 | ... | ... | ✅ / ❌ |
| 2 | ... | ... | ✅ / ❌ |
| 3 | ... | ... | ✅ / ❌ |
```

Rules:

- All four required. No omission.
- Validation ≥ 3 rows for any surface change (endpoint, page, public claim).
- `Summary` bullets state what changed; add a *why* clause only when the motivation isn't visible in the diff. Never a standalone "why" bullet that restates the subject.
- No `Co-Authored-By:`. No Claude / agent attribution. No emoji unless the change itself is about emoji.
- No mentions of `CLAUDE.md` / `README.md` — inline the content instead.

### 4.1 Conditional sections

- **DB migration / spec change** → rollback plan + downtime notes.
- **UI / design change** → before/after screenshot or video.
- **Feature flag** → rollout plan, default state, kill-switch.
- **Touches auth / PII / public claim / content-schema contract / `[x]` checkbox flip** → explicit security or strategy-owner review checkbox + CODEOWNERS approval.

### 4.2 Mirror MR

First bullet of `## TLDR`:

```markdown
- **Mirrors:** [tech/docs!34](<mr-url>).
```

### 4.3 Hotfix MR (engineering only)

Last bullet of `## TLDR` on every MR in a `fix/*` fan-out set (see §6):

```markdown
- **Hotfix paired MRs:** !123 (→develop), !124 (→staging).
```

### 5. Authoring the MR

```sh
glab mr create \
  --target-branch <default> \
  --title "<commit subject>" \
  --description "$(cat <tmp-body-file>)"
```

- Multi-line body via `--description "$(cat <path>)"`. No `--description-file` flag exists on the installed `glab`. **Never `--fill`.**
- No `--allow-collaboration`, no `--draft` unless explicitly requested.

### 6. The `fix/*` hotfix multi-MR protocol (engineering only)

Same source branch tip → multiple open MRs into different protected targets. The exact fan-out is declared in `<workspace-root>/tech/docs/standards/git.md`; the standard workspace convention is a `develop → staging → main` promotion chain, giving:

| Bypass case | Cut from | MRs from the same `fix/*` branch |
|---|---|---|
| Staging hotfix | `staging` | → `staging` **AND** → `develop` (2 MRs) |
| Main hotfix | `main` | → `main` **AND** → `staging` **AND** → `develop` (3 MRs) |

Rules:

- Each MR's diff is computed against its own target.
- **Cross-link every MR in the set.** Lead each body with `Hotfix paired MRs: !A (→<target>), !B (→<target>).`
- A `fix/*` MR without its paired companion(s) is an automatic block in review.
- Delete the source branch only after every paired MR has merged. Disable the host's "auto-delete source branch on merge" for `fix/*` MRs.
- Rebase each MR on its own target.
- A revert that fixes a regression on a protected branch follows the same fan-out protocol.

### 7. Hard rules

- No `git add -A` / `git add .`.
- No staging `.env*`, `*.pem`, `*.key`, `*.p12`, `credentials.json`, `service-account*.json`, kubeconfigs, third-party API tokens, or anything the standard `.gitignore` would catch.
- No `Co-Authored-By:`.
- No Claude / agent attribution, no emoji (unless the change is about emoji), no "Generated by …" lines.
- No direct push to a protected branch (per the workspace's own git standards — typically `main` on docs repos; `main` / `staging` / `develop` on engineering repos).
- No `glab mr create --fill`.
- No mentions of `CLAUDE.md` / `README.md` from an MR body or doc.
- No unrelated changes in one MR. One concern per MR.
- No `[ ]` features from `<workspace-root>/product/docs/features/v<N>/all-features.md` (highest `v<N>` present) treated as in scope.
- Engineering only: a `feature` MR without a test is an automatic block in review.
- **Project-specific hard rules** — schema invariants, locale rules, scope gates, reserved-slot guards — live in the workspace's own per-project sibling hooks under `<config-dir>/.claude/hooks/`. If one of those blocks a change, fix the offense; do not bypass. The block message is surfaced unchanged.

### 8. Self-check before opening

1. Branch = `<type>/<scope>/<2-4-word-description>`, types from §1.1, scope from §1.2.
2. Target = repo's default per §2 (per-repo remote HEAD — typically `main` for docs-container repos, `develop` for engineering repos under `tech/`), or one of the protected branches (hotfix per §6).
3. Subject ≤ 72, imperative, no period, no `and`.
4. Title = subject character-for-character.
5. Body: four sections, Validation ≥ 3 rows on surface change, no attribution.
6. Mirror → first bullet of TLDR is `**Mirrors:** [<repo>!N](<url>).`
7. `fix/*` hotfix → TLDR ends with `**Hotfix paired MRs:** !A (→…), !B (→…).` and the companion MRs are open (or about to be opened in this same batch).
8. Staged files are exactly the relevant ones — no drift, no secrets.
9. (Engineering, `feature/*` only) the diff includes a `tests/` file.

Any failure → fix before opening.
