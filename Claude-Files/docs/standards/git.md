# Git Best Practices — Cross-Repo Standards

This document defines the git conventions that apply to **every** Heptapeak repository. Today the program is three GitLab docs repos under `gitlab.com:heptapeak-website/` — `business/docs`, `product/docs`, `tech/docs` — all using `main` as their default branch. When engineering repositories are added under `tech/` (anticipated `backend-*`, `devops-*`, `frontend-*`), they inherit every rule in this document by default.

This file lives at the umbrella workspace's `docs/standards/git.md`. The umbrella `heptapeak-website/` itself is **not a git repo** — it is a sibling-checkout container — so edits to this file are direct, not via MR. Edits inside any of the three docs repos follow the MR flow described in §2–§7.

Tech-only rules — deployment branches (`develop → staging → main`), the hotfix multi-MR protocol, secrets-and-credentials `.gitignore`, build-artifact / dependency exclusions, automated secret scanning, Git LFS for large binaries, code-specific quality gates, build tooling, SemVer mapping, release tagging, and code-repo bootstrapping — will live in `tech/docs/standards/git.md` (not yet created) and layer on top of these baseline rules. Until that file exists, this document is the sole source of truth. If the future tech doc and this document disagree, this document wins for cross-repo concerns, the tech doc wins for engineering-only concerns.

---

## Table of Contents

1. [Repository Hygiene](#1-repository-hygiene)
2. [Branching Strategy](#2-branching-strategy)
3. [Branch Lifecycle Automation](#3-branch-lifecycle-automation)
4. [Commit Conventions](#4-commit-conventions)
5. [Merge Strategy](#5-merge-strategy)
6. [MR Description Template](#6-mr-description-template)
7. [MR Size Limits](#7-mr-size-limits)
8. [MR Review Format](#8-mr-review-format)
9. [Shared Git Config](#9-shared-git-config)
10. [Recovery Playbook](#10-recovery-playbook)
11. [Antipatterns](#11-antipatterns)
12. [Quick Reference Card](#12-quick-reference-card)

---

## 1. Repository Hygiene

Engineering code repos will add further hygiene concerns (secrets, build artifacts, lockfiles, secret scanning, Git LFS) — see `tech/docs/standards/git.md` once that file is introduced.

### 1.1 `.gitignore` — OS and editor noise

| Category | Examples |
|---|---|
| OS metadata | `.DS_Store`, `Thumbs.db`, `desktop.ini` |
| Editor scratch / swap files | `*~`, `*.swp`, `*.swo` |
| Editor workspace dirs | `.vscode/` (unless team-shared snippet config), `.idea/` |

Never commit first and gitignore later — once a file is in history, removal requires `git filter-repo` + force-push + every clone rewriting.

### 1.2 `.gitattributes` — universal minimum config

```gitattributes
# Auto-detect text files and normalize to LF in the repo.
* text=auto eol=lf

# Force LF for the text formats that docs repos actually use.
*.md      text eol=lf
*.json    text eol=lf
*.yml     text eol=lf
*.yaml    text eol=lf
*.html    text eol=lf
*.css     text eol=lf
*.svg     text eol=lf

# Common embedded binary assets used in docs — never diff, never normalize.
*.png     binary
*.jpg     binary
*.jpeg    binary
*.gif     binary
*.ico     binary
*.pdf     binary
*.woff    binary
*.woff2   binary
*.ttf     binary
```

Engineering repos will extend this with language-specific text types (`*.py`, `*.ts`, `*.tsx`, `*.js`, `*.sh`) and ML / archive binary patterns (`*.onnx`, `*.bin`, `*.pt`, `*.zip`, `*.tar.gz`) — see `tech/docs/standards/git.md` once that file is introduced.

---

## 2. Branching Strategy

### 2.1 Long-lived branches

| Repo class | Long-lived branches |
|---|---|
| **All docs repos** — `business/docs`, `product/docs`, `tech/docs` | **`main` only** |
| **Engineering code repos** under `tech/` (anticipated `backend-*`, `devops-*`, `frontend-*` — none exist yet) | **`develop → staging → main`** |

`tech/docs` follows the docs-repo rule.

Every long-lived branch must be protected at the host level with:

- No direct push. All changes via MR.
- No force push, including `--force-with-lease`.
- Required approvals — at least 1 for normal MRs; 2 for High-risk or sensitive areas (via CODEOWNERS).
- Required passing pipeline where one exists.
- Required up-to-date branch — source must be rebased on target before merge.
- Linear history on `main` (see §5.3).
- Auto-delete source branch on merge (with hotfix exception — see `tech/docs/standards/git.md` once introduced).

### 2.2 Three-segment branch naming

```
<type>/<scope>/<description>
<type>/<scope>/<TICKET-NN>-<description>
```

| Branch type | Commit type used for its commits | Notes |
|---|---|---|
| `feature/...` | `feature` | New functionality, new content, new page. |
| `bugfix/...` | `bugfix` | Regular bug fix on the mainline. |
| `fix/...` | `bugfix` | **Hotfix workflow marker — engineering only.** Branch name `fix/*` triggers the multi-MR fan-out rules in `tech/docs/standards/git.md`. Doc-only repos do not use `fix/*`. |
| `document/...` | `document` | Docs-only changes. Default type in a pure-docs repo. |
| `test/...` | `test` | Test additions / modifications without behaviour change. Engineering only. |
| `maintenance/...` | `maintenance` | Refactor, perf, deps, style, link rot, restructure. |
| `CICD/...` | `CICD` | CI/CD / build / pipeline config. |
| `release/...` | (mixed) | Promotion branch. Carries whatever commit types its contents need. |
| `experiment/...` | (mixed) | Short-lived spike / draft. Subject to stricter staleness threshold (§3.2). |
| *(any branch)* | `revert` | Reverts live on a regular shipping branch — usually `bugfix/...` or `fix/...` — never on a `revert/*` branch. |

Rules:

- Lowercase only.
- Hyphens between words in description. No spaces, no underscores, no camelCase.
- Description: 2–4 words. Aim < 60 chars total.
- Optional ticket prefix: `<TICKET-NN>-<description>` (e.g. `HPK-123-add-create-endpoint`). The `HPK-` prefix is illustrative — Heptapeak has not committed to an external tracker yet. Don't invent a ticket to fill the slot.

Examples (matching scopes that exist in the three repos today):

- `feature/brand/diamond-logo-motions` *(business/docs — adds motion specs alongside the brand reference)*
- `feature/features/add-v1-feature-inventory` *(product/docs — extends the v1 feature catalogue)*
- `bugfix/competitor-analysis/correct-iran-section-counts` *(business/docs — fixes a wrong number in the ranking file)*
- `document/root/update-readme` *(any repo — touches top-level `CLAUDE.md` / `README.md`)*
- `maintenance/competitor-analysis/restructure-iranian-section` *(business/docs — reorders without rewording)*
- `CICD/root/add-link-check-job` *(any repo — adds a pipeline job)*
- `release/root/v1-4-0` *(only in engineering / release-cut repos; no Heptapeak repo qualifies yet)*
- `experiment/brand/spike-logo-motion-variants` *(business/docs — short-lived design spike)*

For **workspace-level multi-repo passes** that touch every repo with the same intent (e.g. seeding `CLAUDE.md` / `README.md` across all three repos at once), use `document/root/<2-4-word-description>` in each repo so the branches are recognisably part of the same pass.

When engineering repos are added under `tech/`, they will use scopes drawn from their own source layout (e.g. `src_modules_emails/...`, `src_api_v1_emails/...`, `src_core/...`) — see `tech/docs/standards/git.md` once introduced. The *structure* (three segments, types, casing) is identical.

### 2.3 Short-lived working branches

- Open the MR early.
- If a branch is > 5 days old and has > 3 commits ahead of target, ship it, split it, or close it.
- No personal-fork workflow — work on shared branches in the upstream repo.
- Worktrees in this workspace are created under `tmp/worktrees/<repo-short-name>` (`business-docs`, `product-docs`, `tech-docs`) and removed after the MR merges.

### 2.4 `review-<YYYYMMDD>` snapshots

When the author hands off for review, push `review-<YYYYMMDD>` (e.g. `review-20260608`) pointing at the reviewed commit. The author iterates on `feature/...`; reviewers diff `feature/...` vs `review-<YYYYMMDD>` to see what changed. Not a replacement for protected branches.

### 2.5 Rebase on the MR's target — not just `main`

Correct rebase base = the MR's target branch. When the same source branch fans out into multiple MRs (the engineering hotfix flow — see `tech/docs/standards/git.md` once introduced), each MR rebases against its own target. In the current docs-only state, the target is always `main`.

---

## 3. Branch Lifecycle Automation

### 3.1 Auto-delete source branch on merge

Enable the host-level "delete source branch when MR is merged" toggle. Exception: `fix/*` hotfix branches with paired companions — disable per MR (engineering-only; see `tech/docs/standards/git.md` once introduced).

### 3.2 Stale branch reaper

A scheduled CI job (daily or weekly) that:

1. Lists all branches.
2. Excludes protected (`main`, any environment branches, `release/*`).
3. Finds branches with no commits in the last N days (60 for `feature/*`, `maintenance/*`; 30 for `experiment/*`).
4. Notifies the author first; deletes after a grace period if no response.

Reference implementation (GitLab CI, run via scheduled pipeline):

```yaml
stale-branch-reaper:
  stage: maintenance
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $REAPER == "true"
  script:
    - |
      THRESHOLD=$(date -d '60 days ago' +%s)
      # Match this exclusion list to the repo's protected long-lived branches:
      #   - docs repos (business/docs, product/docs, tech/docs): origin/main
      #   - future engineering repos:                            origin/main|origin/staging|origin/develop|origin/release/*
      PROTECTED='origin/main'   # docs-repo default; engineering repos extend this
      for branch in $(git for-each-ref --format='%(refname:short) %(committerdate:unix)' refs/remotes/origin | awk -v t="$THRESHOLD" '$2 < t {print $1}'); do
        case "$branch" in
          $PROTECTED) continue ;;
          *) echo "STALE: $branch" ;;
        esac
      done
```

### 3.3 `git fetch --prune` by default

```ini
[fetch]
  prune = true
  pruneTags = true
```

Distribute via the shared config in §9.

### 3.4 No long-lived personal forks

Work on branches in the upstream repo. Forks are for external contributors and isolated experiments only.

---

## 4. Commit Conventions

### 4.1 Typed commits with strict vocabulary

| Order | Type | Use for | Conventional bridge |
|---|---|---|---|
| 1 | `document` | Docs only (prose docs, comments, docstrings, runbooks, design notes) | `docs` |
| 2 | `bugfix` | Any bug fix (broken code, broken link, broken claim in a doc) | `fix` |
| 3 | `test` | Test additions / modifications | `test` |
| 4 | `CICD` | CI/CD / build config | `ci` + `build` |
| 5 | `feature` | New functionality, new doc page, new spec section | `feat` |
| 6 | `maintenance` | Refactor, perf, deps, style, restructure, link rot fixes | `refactor` + `chore` + `perf` + `style` |
| 7 | `revert` | Reverts a previous commit | `revert` |

**Priority-order resolution.** When a commit could be multiple types, pick the **first** type that matches top-to-bottom. Enforce via commitlint where the repo uses commitlint.

In pure-docs repos (all three Heptapeak repos today), `document` is the default type. Reserve `feature` for "add a new doc / page / spec section that did not previously exist" and `bugfix` for "the doc said something incorrect and is now correct."

### 4.2 Subject line discipline

| Rule |
|---|
| ≤ 50 chars soft / 72 chars hard. |
| Imperative mood ("add", "fix", not "added", "fixes"). |
| No leading capital after `):`. Proper nouns excepted. |
| No trailing period. |
| One concern — if you need "and" in the subject, it's two commits. |

### 4.3 Body format

- Subject, blank line, body.
- Wrap body at ~72 chars. Bullets fine. One blank line between paragraphs.
- Body explains **WHAT** (at a higher altitude than the diff) and **WHY** (context the diff cannot show). Never **HOW** — the diff already shows that.

Canonical example:

```
feature(brand): add diamond logo motion specs

Define the entry, idle, and exit motion sequences for the diamond
logo, including the easing curves, durations, and the
prefers-reduced-motion fallback. Targets the brand reference page
and any downstream implementations on the marketing site.

Previously the motion treatment lived only in the design deck —
implementers re-derived the curves from screen recordings, which
produced inconsistent results across surfaces.

Closes #42
```

### 4.4 One concern per commit; atomic and independently meaningful

Test: `git revert <sha>` and the repo still builds / renders / passes checks. Never mix unrelated changes (e.g. "feature X + unrelated refactor + version bump + typo fix") in one commit.

### 4.5 Breaking changes — `!` after type, or `BREAKING CHANGE:` footer

Two equivalent forms:

```
maintenance(brand)!: rename brand/ scope to identity/
```

or:

```
maintenance(brand): consolidate brand assets under identity/

BREAKING CHANGE: `business/docs/brand/` no longer exists. Brand
assets now live under `business/docs/identity/`. Cross-repo links,
embeds, and tooling that referenced `brand/` must update before
adopting this commit.
```

The `BREAKING CHANGE:` footer is uppercase and machine-readable.

### 4.6 Footer references

- Issue links: `Closes #123` (auto-closes on merge), `Refs #789` / `Relates to #789` (mention without closing).
- External tracker (when one is committed): `Refs HPK-123`, `Closes HPK-456`.
- **Heptapeak does not use co-author lines.** Do not add `Co-Authored-By:` footers to commits in any Heptapeak repo.
- Paired hotfix MRs: engineering-only — see `tech/docs/standards/git.md` once introduced.

### 4.7 The `revert` format

```
revert(<scope>): <original subject>

Reverts: <sha-of-the-reverted-commit>
Reason: one line — why this is being reverted.

Closes #<issue> | Refs #<issue>
```

Always fill in `Reason:`. A revert that itself fixes a regression on a protected engineering branch will follow the hotfix protocol — see `tech/docs/standards/git.md` once introduced.

---

## 5. Merge Strategy

### 5.1 The three options

| Strategy | `git log` shape | Pros | Cons |
|---|---|---|---|
| **Squash-merge** | One commit per MR; linear | Clean history; trivial revert; each `main` commit = one feature | Loses per-commit granularity |
| **Merge-commit** | Branch structure preserved; merge commit per MR | Full history retained; promotion chain visible | `git log --oneline` is noisy |
| **Rebase-merge** | Linear, every commit from the branch lands on target | Linear history; per-commit granularity preserved | WIP commits land if not cleaned up |

### 5.2 Default

- **Squash-merge MRs into the mainline.** All three Heptapeak docs repos use this today.
- **Merge-commit for promotion MRs** across long-lived branches (only relevant once engineering repos with `develop → staging → main` exist).

Alternative: rebase-merge everywhere, if the team enforces cleaned-up working-branch commits before every merge.

Enforce the chosen method host-side (GitLab "Merge method" / GitHub merge toggles). Mixed merge strategies are not permitted.

### 5.3 Linear history on `main`

Enforce "require linear history" in branch protection for `main`. No octopus merges (one merge commit with > 2 parents).

---

## 6. MR Description Template

### 6.1 Required sections

```markdown
## TLDR

- **Problem:** one line — what's wrong or what's needed.
- **Solution:** one line — what this MR does.
- **How to validate in under 1 minute:** exact steps a reviewer runs.
- **Merge Risk Score:** High / Medium / Low
- **Hotfix paired MRs:** (engineering-only — `fix/*` MRs) cross-link the set.

## Summary

What changed and why (bullets).

## Test Plan

What was tested locally (engineering: run / lint / type / suite. docs / design: render preview, link check, screenshot diff) and what the reviewer should test.

## Validation

| # | Action | Expected | Actual |
|---|--------|----------|--------|
| 1 | ... | ... | ✅ / ❌ |
| 2 | ... | ... | ✅ / ❌ |
| 3 | ... | ... | ✅ / ❌ |
```

Validation table requires ≥ 3 rows for any surface change (endpoint, page, public claim, brand asset published externally, feature checkbox flip in `product/docs/features/v1/all-features.md`).

### 6.2 Conditional required sections

Required *only when applicable*:

- **DB migration / spec change** → rollback plan + downtime.
- **UI / design change** → before/after screenshot or video.
- **Feature flag** → rollout plan, default state, kill-switch.
- **Touches auth / billing / PII / financial-spec / public claim / founding charter (`asasnameh.md`) / `[x]` checkbox flip** → explicit security / strategy-owner / legal-owner review checkbox + CODEOWNERS approval.

Use the host's templating (GitLab Liquid / GitHub multiple-template directory) so checking "includes a migration" expands the required fields.

### 6.3 Storing the template

- GitLab: `.gitlab/merge_request_templates/Default.md` (with `Hotfix.md` / `Release.md` variants where relevant).
- GitHub: `.github/PULL_REQUEST_TEMPLATE.md` (or a `PULL_REQUEST_TEMPLATE/` directory).

Commit the template so it versions alongside the content. Heptapeak hosts on GitLab — use the GitLab path.

---

## 7. MR Size Limits

### 7.1 Thresholds (engineering default)

| Threshold | Lines changed | Files changed |
|---|---:|---:|
| Best practice | 50 | 5 |
| Hard stop | 100 | 10 |

Best-practice = aim for it; hard-stop = MR must split. Doc and design repos (every Heptapeak repo today) use the qualitative gate in §7.3 as the primary rule, treating line counts as a soft signal.

### 7.2 Carve-outs (don't count toward the limit)

- Lockfiles (`package-lock.json`, `poetry.lock`). *(engineering)*
- Generated code (protobuf bindings, OpenAPI clients, GraphQL schemas). *(engineering)*
- Fixtures (test data, sample JSON). *(engineering)*
- Snapshot tests (Jest snapshots, Playwright screenshots). *(engineering)*
- Vendored assets (committed dependencies, embedded fonts, design exports, raw SVG logo masters in `business/docs/brand/`).
- Bulk content moves (file renames, directory restructures with no content change — e.g. reorganising `business/docs/competitor-analysis/` sections).

The author must call out the carve-outs in the MR description.

### 7.3 Qualitative override

**Every MR must be reviewable in a single focused 30–60 min session by one engineer / reviewer.** This gate overrides the raw line count. Author self-test: "Can one reviewer hold this entire change in their head and validate it in one session?" If no, split.

### 7.4 Natural split path

Engineering (future) — schema → services → routers + tests:

1. MR 1: schema. Migration + data models.
2. MR 2: services. Business logic using the schema.
3. MR 3: routers + tests. HTTP/UI layer + integration tests.

Prose / design (every Heptapeak repo today) — structure → content → polish:

1. MR 1: structure. New headings, page tree, cross-reference scaffolding.
2. MR 2: content. Fill in prose / designs against the structure.
3. MR 3: polish. Voice pass, link check, screenshot consistency, brand alignment.

Each MR must be independently meaningful.

### 7.5 Combo MRs require pre-opening approval

A wide refactor touching many files must be announced in chat and pre-approved before opening. No surprise mega-MRs.

---

## 8. MR Review Format

### 8.1 Two-section flat output

```
## **Pls change before merge:**

1. 🔴 **Short bold title.** What's wrong, where (file.md:42), and the concrete fix.

## **Better to resolve:**

1. 🟡 **Short bold title.** prose.
```

Two sections only. No overview, no summary, no "looks good," no CI dashboard restatement.

- 🔴 = must fix before merge. Correctness, security, privacy/PII, missing-claimed-change, non-parameterized SQL into a sink, a `feature` MR with no test (engineering), a `fix/*` MR without paired companion MRs (engineering), a strategy claim that contradicts another current spec, a design that violates the locked design system, an out-of-scope feature claim (see §8.3), a paraphrase of the founding charter `asasnameh.md`.
- 🟡 = worth addressing, non-blocking. Consistency, perf nits, missing validation table rows, hardcoding that should be a constant, voice / tone drift, redundant phrasing, minor accessibility nits.

Omit empty sections entirely. Silence = approval.

### 8.2 Every comment has `file:line`

The author must be able to click directly to the location.

### 8.3 Automatic 🔴 triggers

- **`feature` MR without a test** — engineering rule; see `tech/docs/standards/git.md` once introduced.
- **Claimed-but-missing change** — description says one thing, diff does not contain it.
- **Non-parameterized SQL into a sink** — engineering; e.g. `f"SELECT ... {user_input}"` heading toward `execute()`.
- **`fix/*` hotfix MR without paired companion MRs** — engineering.
- **Reference to `CLAUDE.md` / `README.md`** in a document under review — these two files are derived from the documents; any link or mention is automatic 🔴. Inline the relevant content instead.
- **Out-of-scope feature claim** — a doc, brand asset, competitor commentary, or spec section that assumes a `[ ]` (unchecked) feature from `product/docs/features/v1/all-features.md` is shipping. The v1 scope contract is "only `[x]` items ship." A `[ ]` item moves into scope only via a dedicated MR that flips its checkbox first.
- **Paraphrased founding charter** — `business/docs/documents/asasnameh.md` is canonical Persian legal text; any change that rewords (rather than corrects a transcription error) is automatic 🔴.

### 8.4 Blocking items require human sign-off

If the review has any 🔴 items, a human must explicitly sign off before the review is posted. The agent / tool drafts; the human approves.

### 8.5 The reviewer must read the actual diff

Never trust the description alone. Skim the description for context, then read the diff line by line.

### 8.6 Output format

Wrap the entire review in a triple-backtick code block with no language tag. The author copies the whole block into the MR comment.

---

## 9. Shared Git Config

Commit a `.gitconfig` snippet (or include in onboarding docs):

```ini
[pull]
  rebase = true
[push]
  default = current
  autoSetupRemote = true
[init]
  defaultBranch = main
[rerere]
  enabled = true
[fetch]
  prune = true
  pruneTags = true
[merge]
  conflictStyle = zdiff3
[diff]
  algorithm = histogram
[branch]
  sort = -committerdate
[column]
  ui = auto
```

Distribute via either:

1. Onboarding doc — contributors copy-paste into `~/.gitconfig` on first day.
2. `includeIf` from a repo-local config — repo ships a `.gitconfig`, each contributor adds an `[includeIf "gitdir:~/Codes/heptapeak/"]` block to their global config so the rules apply only when working inside the Heptapeak umbrella.

---

## 10. Recovery Playbook

| Scenario | Recipe |
|---|---|
| Lost a commit after a bad reset | `git reflog` → find SHA → `git reset --keep <sha>` or `git cherry-pick <sha>`. |
| Accidentally committed to the wrong branch | `git reset --keep HEAD~1` on the wrong branch → `git checkout <correct-branch>` → `git cherry-pick <sha>`. |
| Undo a pushed commit on a shared branch | `git revert <sha>` then `git push origin <branch>`. Never force-push to a shared branch. |
| Force-pushed over someone else's work | (1) host admin server-side reflog; (2) ask the author to re-push from their local reflog; (3) recover via CI artifacts / mirrors / forks. Do not force-push again — stop and ask. |
| Lost branch | `git reflog` → find a recent HEAD → `git branch <name> <sha>`. Works as long as `git gc` has not run. |
| Merge conflict overwhelming | `git merge --abort` or `git rebase --abort`. Re-approach in smaller chunks. |
| Worktree left behind under `tmp/worktrees/` | From the main checkout: `git worktree remove tmp/worktrees/<repo-short-name>`; then delete the local branch if no longer needed. |

When in doubt:

1. Stop. Don't run more destructive commands.
2. Snapshot working state: `git stash` or `git checkout -b panic-backup-$(date +%s) && git add -A && git commit -m "panic snapshot"`.
3. Ask.

Reflog default expiry is 90 days.

---

## 11. Antipatterns

- **Never** `git push --force` (or `--force-with-lease`) to a shared/protected branch.
- **Never** amend or rebase a commit that has been pushed to a shared branch.
- **Never** `git add -A` / `git add .` without reviewing — name the files you mean.
- **Never** merge your own MR without an approving review (except documented hotfix exceptions in `tech/docs/standards/git.md` once introduced).
- **Never** mix unrelated changes in one commit or one MR — split them.
- **Never** rebase a shared branch.
- **Never** push directly to a protected branch, even with the protection "temporarily disabled."
- **Never** use `--no-verify` to bypass commit / push hooks.
- **Never** add a `Co-Authored-By:` footer — Heptapeak does not use co-author lines.
- **Never** link to or mention `CLAUDE.md` / `README.md` from a document — those files are derived from the documents; inline the relevant content instead.
- **Never** treat a `[ ]` (unchecked) feature in `product/docs/features/v1/all-features.md` as in scope. Out-of-scope content is an automatic 🔴 across all three repos; the checkbox flip must land first, in its own MR.
- **Never** commit secrets — API keys, access tokens, credentials, infrastructure secrets, or anything in a `.env` family file.
- **Never** paraphrase the founding charter `business/docs/documents/asasnameh.md`. Correct transcription errors only.

Engineering code repos will add further antipatterns (committed secrets at scale, large binaries without Git LFS, skipping `pre-commit` hooks, moving release tags, failing tests, generated artifacts in `main`) — see `tech/docs/standards/git.md` once introduced.

---

## 12. Quick Reference Card

```
BRANCH:     type/scope/description                    feature/brand/diamond-logo-motions
BRANCH:     type/scope/TICKET-NN-description          feature/brand/HPK-123-add-diamond-logo-motions
REVIEW:     review-YYYYMMDD                           review-20260608

COMMIT:     type(scope): imperative subject           feature(brand): add diamond logo motion specs
FOOTER:     Closes #N | Refs TICKET-NN                Closes #42 • Refs HPK-123

types (branch):  feature  bugfix  test  document  maintenance  CICD  release  experiment  fix/* (engineering-only hotfix)
types (commit):  document bugfix test CICD feature maintenance revert        (priority order)
mapping:         same-name branch ↔ commit (feature→feature, bugfix→bugfix, …);
                 release/*, experiment/* use whichever commit type fits each change;
                 revert is commit-only — no revert/* branch.
                 fix/* (engineering hotfix) uses bugfix commits — see tech git standards once introduced.

REPOS:          business/docs · product/docs · tech/docs   (all GitLab, all main, all docs repos today)
UMBRELLA:       heptapeak-website/ is NOT a git repo — edits here are direct, no MR
BRANCHES:       docs repos → main only;   future engineering code repos → develop → staging → main   (tech/docs is a docs repo)
PROTECT:        every long-lived branch — no direct push, no force push, required approvals, required green pipeline
SIZE:           best 50 lines / 5 files; hard 100 / 10 (engineering); qualitative gate for prose / design (§7.3)
MERGE:          squash for MRs into mainline (default everywhere today); merge-commit for promotion (future engineering only)
REVIEW:         two-section output — 🔴 blocking, 🟡 nice-to-have
NO COAUTHOR:    do not add Co-Authored-By: footers in any Heptapeak repo
NO CLAUDE.MD:   documents must not reference CLAUDE.md or README.md
V1 SCOPE:       only [x] items in product/docs/features/v1/all-features.md ship; [ ] items are 🔴 until flipped
NO --no-verify: investigate and fix the hook failure; don't bypass it
```
