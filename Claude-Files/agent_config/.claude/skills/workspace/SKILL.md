---
name: workspace
description: |
  Multi-repo housekeeping for a `business/ product/ tech/ + <docs-container>/` workspace (docs container is `docs/` or `agent-config/` — detect by which child of the workspace root contains `.claude/`). Discovers repos at call time (never hardcodes): the docs container at the workspace top level plus the three discipline docs (`business/docs`, `product/docs`, `tech/docs`) plus every subdirectory of `tech/` whose `.git` exists (directory or file — worktrees count). First positional argument is `<status|sync|clean|mrs>`; second is `<touched|all>`. Both required — never default.

  - `status <touched|all>` — read-only snapshot per repo: branch, default, clean/dirty, ahead/behind, open-MR count, stash count, single-word verdict. No fetch, no pull, no push.
  - `sync <touched|all>` — checkout each repo's default branch and `git pull --ff-only`. Never pushes, force-deletes, drops stashes, or rewrites history.
  - `clean <touched|all>` — prune the worktree registry, remove merged worktrees under `tmp/worktrees/`, delete local branches merged into the repo's default with `git branch -d` (never `-D`), prune stale remote-tracking refs, list (never drop) stashes.
  - `mrs <touched|all>` — list every open merge request on origin via `glab mr list --state opened`, grouped by repo.

  Use when the user asks to "check workspace status", "give me a status of every repo", "sync all repos", "pull default across the workspace", "clean up merged branches / worktrees", "prune stale stuff", "show me the open MRs across the workspace", or invokes `/workspace`.

  If the first arg is missing or not one of `status` | `sync` | `clean` | `mrs`, stop and ask which sub-op. If the second arg is missing or not `touched` | `all`, stop and ask which scope — never default. Running `all` by accident fans out across every workspace repo.

  Never edits repo content, never pushes, never merges, never drops stashes, never `-D`-force-deletes a branch. `clean` uses `git worktree remove` without `--force` and `git branch -d` — refusals surface to the user, no escalation. Default branch is per-repo (convention: `main` for docs, `develop` for engineering under `tech/`); resolve at call time via `git symbolic-ref --short refs/remotes/origin/HEAD`, never hardcode. Project-specific guards (forbidden fields, banned literals, reserved slots) belong in a per-project sibling hook.
---

# workspace — multi-repo housekeeping

`/workspace <status|sync|clean|mrs> <touched|all>`

Routes to four sub-commands. The first argument selects the sub-command; the second selects the scope. Both required.

| Sub-cmd | Section | One-line summary |
|---|---|---|
| `status` | [status](#status) | Read-only snapshot per repo: branch, clean/dirty, ahead/behind, open-MR count, stash count, single-word verdict. |
| `sync` | [sync](#sync) | Checkout each repo's default branch and `git pull --ff-only`. Remote-read-only. |
| `clean` | [clean](#clean) | Prune the worktree registry, remove merged worktrees, delete merged local branches (`-d` only), prune stale remote-tracking refs, list (never drop) stashes. Local-only. |
| `mrs` | [mrs](#mrs) | List every open merge request on origin via `glab mr list --state opened`, grouped by repo. |

If the first arg is missing or invalid (anything other than `status`, `sync`, `clean`, or `mrs`), stop and ask — never default. If the second arg is missing or invalid (anything other than `touched` or `all`), stop and ask — never default; running `all` by accident fans out across every workspace repo and calls `glab` once per repo.

To replicate a pull + prune pass, run `/workspace sync <scope>` then `/workspace clean <scope>`.

Project-specific guards (per-workspace hard rules — forbidden fields, banned literals, reserved slots) belong in a per-project sibling hook, not in this command.

---

## Workspace repo list

Every candidate-list step below uses the same on-disk discovery. Do **not** hardcode; discover at call time so any repo added later surfaces automatically.

**Workspace root** is the directory that contains `business/`, `product/`, `tech/`, and a docs container. The docs container is usually named `docs/`, occasionally `agent-config/` — detect it as the child directory of the workspace root that contains a `.claude/` subdirectory.

Discovery command (one Bash call — substitute `<docs-container>` with the detected name):

```sh
ls -1d <workspace-root>/<docs-container> \
        <workspace-root>/business/docs \
        <workspace-root>/product/docs \
        <workspace-root>/tech/docs \
        <workspace-root>/tech/*/ \
        <workspace-root>/scripts \
        <workspace-root>/scripts/*/ 2>/dev/null
```

The candidate set is every discovered repo — the docs container at the workspace top level plus the three discipline docs (`business/docs`, `product/docs`, `tech/docs`) plus every subdirectory of `tech/` whose `.git` exists (directory or file — worktrees count), plus **optional** workspace-tooling repos under `scripts/` (bootstrap / initializer / cross-repo maintenance scripts; not every project ships one — always probe).

**`scripts/` handling** — probe at call time:
- No `<workspace-root>/scripts/` → skip.
- `<workspace-root>/scripts/.git` exists → single-repo layout; workspace-relative path is `scripts`.
- Otherwise, each `<workspace-root>/scripts/<name>/.git` present → multi-repo layout; workspace-relative path per repo is `scripts/<name>` (e.g. `scripts/initializer`).
- Both layouts can coexist; enumerate whichever `.git` entries actually exist.

Scripts repos participate in every sub-op (`status` / `sync` / `clean` / `mrs`) exactly like any other repo — same default-branch resolution via `git symbolic-ref --short refs/remotes/origin/HEAD`, same protected-branch protection, same reporting rows.

Expected shape:

| Class | Path | Default branch (convention) |
|---|---|---|
| Umbrella docs | `<docs-container>` | `main` |
| Discipline docs | `business/docs`, `product/docs`, `tech/docs` | `main` |
| Engineering | every subdirectory of `tech/` with `.git` | `develop` |

Default branches follow the workspace's git standards — the convention is docs on `main`, engineering repos under `tech/` on `develop` (promotion flow `develop → staging → main`). Resolve per repo at call time via `git -C <workspace-root>/<repo> symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/` prefix). Never hardcode. The umbrella git standards typically live at `tech/docs/standards/git.md` (or the docs container's own `standards/git.md` if that's where the workspace keeps them).

---

## status

Print a single compact status table across the workspace: branch, clean/dirty, ahead/behind origin, open-MR count, stash count. Workspace root is the directory that contains `business/`, `product/`, `tech/`, and the docs container. Read-only — no `git fetch`, no `git pull`, no `git push`, no edits.

Argument selects scope:

- `/workspace status all` — every discovered workspace repo.
- `/workspace status touched` — only repos this session edited (working tree, `tmp/worktrees/<name>` checkout, or any repo whose MR was opened/merged this session). Source of truth is conversation context. If empty, stop with `nothing touched this session`.

If the argument is missing or invalid, stop and ask which scope.

### Step 1 — collect signals per repo

For each candidate repo, issue these in parallel (one parallel batch per repo, all repos parallel across batches):

```sh
git -C <workspace-root>/<repo> rev-parse --abbrev-ref HEAD
git -C <workspace-root>/<repo> status --porcelain
git -C <workspace-root>/<repo> symbolic-ref --short refs/remotes/origin/HEAD
git -C <workspace-root>/<repo> rev-list --left-right --count @{u}...HEAD 2>/dev/null || echo "no-upstream"
git -C <workspace-root>/<repo> stash list --format=oneline
glab mr list --repo <workspace-root>/<repo> --state opened --output json
```

Do **not** fetch. `ahead/behind` is computed against the local view of upstream — that is the point of "status without side effects". If the user wants a fresh upstream snapshot, they can `/workspace sync <scope>` first.

If `glab` fails (auth, network, missing remote), mark the repo's MR cell `?` and continue — do not retry.

### Step 2 — derive a per-repo verdict

For each repo, compose:

- **branch**: from `rev-parse`.
- **default**: from `symbolic-ref --short refs/remotes/origin/HEAD` with the `origin/` prefix stripped (resolved per repo — do not assume).
- **clean**: `Y` if `status --porcelain` is empty, else `N`.
- **untracked**: count of `??` lines.
- **modified**: count of non-`??` non-empty lines.
- **ahead/behind**: parsed from `rev-list` left-right (or `—` if no upstream).
- **open-mr**: count of MRs from `glab` (or `?` if it failed).
- **stash**: count of stash entries.

Then the verdict column:

- `OK` — on the repo's default branch, clean, no ahead/behind, 0 open MRs, 0 stashes.
- `OFF-DEFAULT` — not on the repo's default branch. (Common when a worktree is checked out under `tmp/worktrees/<name>`.)
- `DIRTY` — has uncommitted or untracked changes.
- `AHEAD` — has commits not pushed.
- `BEHIND` — origin has commits not pulled (and clean).
- `DIVERGED` — both ahead and behind.
- `MR-OPEN` — has an open MR on origin.
- `STASHED` — has stash entries.

Multiple flags may apply; pick the most actionable one (priority: `DIRTY` > `DIVERGED` > `AHEAD` > `BEHIND` > `OFF-DEFAULT` > `MR-OPEN` > `STASHED` > `OK`). Keep the rest in the per-repo line.

### Reporting

Single table, repos sorted by `(verdict-priority desc, repo-path asc)`:

```
repo                                  branch          default  clean  ahead/behind  MR  stash  verdict     flags
business/docs                         main            main     Y      0/0           0   0      OK          —
product/docs                          feature/foo     main     Y      —             1   0      OFF-DEFAULT MR-OPEN
tech/<some-repo>                      develop         develop  Y      0/0           0   0      OK          —
tech/<other-repo>                     feature/nav     develop  N      —             0   1      DIRTY       STASHED
tech/docs                             main            main     N      2/0           0   0      DIRTY       AHEAD
...
```

Then a single summary line:

```
Summary: OK <n>, OFF-DEFAULT <n>, DIRTY <n>, AHEAD <n>, BEHIND <n>, DIVERGED <n>, MR-OPEN <n>, STASHED <n>
```

Repos whose `glab` call failed get a trailing one-line **MR-check failed** note (per repo, one line each).

Keep the whole report compact — one row per repo. Stop after the report. Do not pull, push, merge, stash, or stage.

---

## sync

Checkout each candidate repo's default branch and `git pull --ff-only`. Remote-read-only — no stage / commit / push / stash / reset.

Argument selects scope:

- `touched` — only repos this session edited (working tree, `tmp/worktrees/<name>` checkout, or any repo whose MR was opened/merged this session). Source of truth is conversation context.
- `all` — every discovered workspace repo.

If the scope argument is missing or invalid, stop and ask. Never default — running `all` by accident fans out across every workspace repo.

Workspace root is the directory that contains `business/`, `product/`, `tech/`, and the docs container. Default branch is **per repo** — resolve at call time; do not hardcode. The convention is `main` for docs, `develop` for engineering repos under `tech/`, but always trust `symbolic-ref`.

### Step 1 — build the candidate-repo list

**`touched` scope:** assemble from session context. If the list is empty, stop with a one-line "nothing touched this session".

**`all` scope:** use the discovery command from [Workspace repo list](#workspace-repo-list).

### Step 2 — pull each repo

Issue one `Bash` call per candidate repo, **all in parallel in a single message**, each running (use absolute paths so calls stay independent — do NOT `cd`):

```sh
default=$(git -C <workspace-root>/<repo-path> symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
git -C <workspace-root>/<repo-path> checkout "$default" && git -C <workspace-root>/<repo-path> pull --ff-only
```

Do not stage, commit, or push. Do not touch repos that have a dirty working tree (`git pull --ff-only` will refuse and surface the error — relay it as-is, don't try to stash or reset).

### Reporting

Above the table, lead with one bolded header line: `## /workspace sync <scope> — <YYYY-MM-DD>`.

Print a markdown table with one row per repo in the candidate list. Columns: **Repo**, **Branch** (the resolved default), **Result** (`**updated**` / `up-to-date` / `**failed**`), **Diffstat** (`N files, +A / -D` if the pull surfaced one, else `—`). Below the table, totals line: `**Totals**: X updated · Y up-to-date · Z failed.` If any repo failed, follow with a `**Failures**` sub-section. If any repo's working tree was dirty (pull refused), mark its **Result** cell `up-to-date *(dirty tree — see note)*` and add a `**Note — <repo> dirty tree**` paragraph after the totals listing the dirty paths. Do not stash or reset.

In `all` scope, if more than 6 repos came back `up-to-date`, collapse them into one row at the bottom of the table with **Repo** = `(unchanged repos)` and the comma-joined repo list in the **Result** cell. Keeps the table scannable.

Stop after the report. Do **not** push, stage, open MRs, merge, drop stashes, or rewrite history.

---

## clean

Prune the worktree registry, remove merged worktrees under `tmp/worktrees/`, delete local branches merged into the repo's default branch (`git branch -d`, never `-D`), prune deleted remote-tracking refs, and **list (never drop)** stashes. Local-only; no push / open MR / merge / drop stash / rewrite history.

Argument selects scope:

- `touched` — only repos this session edited (working tree, `tmp/worktrees/<name>` checkout, or any repo whose MR was opened/merged this session). Source of truth is conversation context.
- `all` — every discovered workspace repo.

If the scope argument is missing or invalid, stop and ask. Never default.

Workspace root is the directory that contains `business/`, `product/`, `tech/`, and the docs container. Default branch is per repo — resolve at call time. Convention is `main` for docs, `develop` for engineering repos under `tech/`, but always trust `symbolic-ref`.

### Step 1 — build the candidate-repo list

**`touched` scope:** assemble from session context. If the list is empty, stop with a one-line "nothing touched this session".

**`all` scope:** use the discovery command from [Workspace repo list](#workspace-repo-list).

### Step 2 — inspect

Issue one `Bash` call per candidate repo, **all in parallel in a single message**, each running an inspection block. Use absolute paths so calls stay independent — do not `cd` between calls. For each repo gather:

1. `git symbolic-ref --short refs/remotes/origin/HEAD` — resolve the default branch (strip `origin/`).
2. `git fetch --prune origin` — refresh remote refs and drop deleted remote-tracking heads.
3. `git worktree list --porcelain` — every registered worktree, with its branch and HEAD.
4. `git worktree prune --verbose` — clear admin entries for worktrees whose directories vanished.
5. `git branch --merged <default> --format '%(refname:short)'` — branches fully merged into the repo's default branch.
6. `git branch -vv` — to spot branches whose upstream is `[gone]`.
7. `git stash list` — every stash with its message and ref.
8. `git status --porcelain` for each worktree path — to detect dirty trees.

Run inspection only in this step — no destructive action yet.

For each repo, build three lists from the inspection output:

**Worktrees to remove** — every worktree under `tmp/worktrees/<name>` where **all** of the following hold:
- The worktree path is not the main checkout (i.e. it is a linked worktree under `tmp/worktrees/`).
- Its working tree is clean (`git status --porcelain` empty).
- Its branch is either (a) fully merged into the repo's default, **or** (b) its upstream is `[gone]` (source branch was deleted on origin after merge), **or** (c) it has no commits ahead of the repo's default.
- Its branch is not a protected branch (`main`, `staging`, `develop`).

**Branches to delete** — every local branch where **all** of the following hold:
- It is not currently checked out in any worktree.
- It is fully merged into the repo's default branch **or** its upstream is `[gone]`.
- It is not a protected branch (`main`, `staging`, `develop`).

`fix/*` hotfix branches stay across the three-branch deploy chain `develop → staging → main` until every paired MR lands (staging hotfix = 2 MRs, main hotfix = 3 MRs), so they normally surface under **Leftover unmerged branches** rather than getting deleted. Do not escalate to `-D`.

**Stashes to surface** — every entry from `git stash list`. **Never drop.** Stashes are user state; the command only reports them so the caller can decide.

**Leftover unmerged branches to surface** — every non-protected local branch that the auto-delete pass skipped (i.e. *not* in the **Branches to delete** list because it isn't merged into the repo's default and its upstream isn't `[gone]`). For each one, gather two extra signals via parallel calls (one Bash call per repo, gathering all that repo's leftover branches at once — do not fan out per branch):

- `git -C <repo> log -1 --format='%ci  %h  %s' <branch>` — tip-commit datetime, short hash, subject line.
- `git -C <repo> reflog <branch> --format='%gd  %gs  %ci' | tail -1` — earliest reflog entry (proxy for "when this branch first appeared in this checkout"; may be missing if reflog was GC'd or the branch was only ever fetched).

These are **surface-only** — never deleted, never touched. The point is to give the caller a per-session reminder of branches that may have outlived their purpose.

If any worktree is dirty, list it under the dirty-tree note in the report — do **not** stash, reset, or remove it.

### Step 3 — execute

For each repo with at least one item to clean, run the cleanup sequence **sequentially within the repo** (worktree removal first, then branch deletion), but **parallel across repos** — one `Bash` call per repo in a single message. Per repo:

1. `git worktree remove <absolute-path>` for each worktree to remove. Use plain `remove` (no `--force`) — if it refuses because the tree is unexpectedly dirty, surface the error and skip that worktree.
2. After all worktrees are gone, `git branch -d <branch>` for each branch to delete. Use lowercase `-d` (refuses unmerged) — **never** `-D`. If `-d` refuses, surface the error and skip; do not escalate.
3. `git worktree prune` once more at the end to clear any newly-orphaned admin entries.

Do **not** `git reflog expire`, `git gc`, or otherwise rewrite history. Do **not** delete files outside the `tmp/worktrees/<name>` directories the worktree machinery owns. Do **not** drop stashes.

### Reporting

Above the table, lead with one bolded header line: `## /workspace clean <scope> — <YYYY-MM-DD>`.

Print a markdown table with one row per repo in the candidate list. Columns: **Repo**, **Default** (the resolved default branch), **Worktrees removed** (count or `—`), **Branches deleted** (count or `—`), **Remote refs pruned** (count from `fetch --prune` or `—`), **Stashes (kept)** (count or `—`), **Leftover branches** (count of unmerged local branches surfaced, or `—`), **Result** (`**cleaned**` / `clean` / `**failed**`). Below the table, totals line: `**Totals**: X cleaned · Y clean · Z failed · S stashes kept · L leftover branches across workspace.` If any repo had stashes, follow with a `**Stashes — manual review**` sub-section: one bullet per repo listing each stash on its own indented line as `<stash@{N}>  <message>  (<branch>)`. State explicitly that nothing was dropped. If any repo had a dirty worktree under `tmp/worktrees/`, add a `**Dirty worktrees — skipped**` sub-section listing the path and the dirty file count. If any repo failed, follow with a `**Failures**` sub-section — one bullet per failed repo with the exact error and the step that failed (`fetch` / `worktree-remove` / `branch-delete`). Do not retry.

If any repo had leftover unmerged branches, follow with a `**Leftover unmerged local branches — surfaced, not deleted**` sub-section: one short intro line explaining `-d` would refuse them (so they were intentionally left in place — the caller can `git branch -D` if any look stale), then a single markdown table covering every repo's leftovers, sorted by repo, then by branch name within each repo:

| Repo | Branch | First appeared locally (reflog) | Tip commit |
|---|---|---|---|
| `<repo>` | `<branch>` | `<YYYY-MM-DD HH:MM ±TZ>` or `—` if no reflog | `<YYYY-MM-DD HH:MM ±TZ>` — `<short-hash>` <subject> |

Reflog-earliest cell is `—` when `git reflog <branch>` returned nothing (GC'd or fetch-only branch). Keep the subject column ungrouped — one row per branch, no merging.

In `all` scope, if more than 6 repos came back `clean`, collapse them into one row at the bottom of the table with **Repo** = `(clean repos)` and the comma-joined repo list in the **Result** cell. Keeps the table scannable.

Stop after the report. Do **not** push, stage, open MRs, merge, drop stashes, or rewrite history — this command is local housekeeping only.

---

## mrs

List every open merge request on the origin remote across the workspace. Workspace root is the directory that contains `business/`, `product/`, `tech/`, and the docs container. Read-only — never stage, commit, push, or merge.

Argument selects scope:

- `/workspace mrs all` — query every discovered workspace repo.
- `/workspace mrs touched` — only repos this session edited (working tree, `tmp/worktrees/<name>` checkout, or any repo whose MR was opened/merged this session). Source of truth is conversation context. If the list is empty, stop with a one-line "nothing touched this session".

If the argument is missing or invalid, stop and ask which scope.

### Step 1 — build the candidate-repo list

**`all` mode:** use the discovery command from [Workspace repo list](#workspace-repo-list). The set is the docs container at the workspace top level plus the three discipline docs plus every immediate subdirectory of `tech/` whose `.git` exists. Any repo added later surfaces automatically without editing this command.

**`touched` mode:** assemble from session context. If empty, stop with "nothing touched this session".

### Step 2 — query open MRs

Issue one `Bash` call per candidate repo, **all in parallel in a single message**, each running:

```sh
glab mr list --repo <workspace-root>/<repo-path> --state opened --output json
```

Use `--repo <absolute-path>` so calls stay independent — do not `cd` between calls. JSON output is stable for parsing; pull `iid`, `title`, `source_branch`, `target_branch`, `author.username`, `web_url`, `draft`, and `created_at` from each entry.

If `glab` is missing or unauthenticated, surface the exact error and stop the whole batch — do not fall back to `gh` (workspace assumes GitLab; swap `glab` for the workspace's actual forge CLI if that differs).

### Reporting

Print one section per repo **that has at least one open MR**, ordered by repo path. Per MR, one line:

```
<repo-path>
  !<iid>  <title>  (<source_branch> → <target_branch>)  @<author>  <web_url>
```

Mark drafts by prefixing the title with `[Draft]`. Sort MRs within a repo by `iid` ascending.

Then a single trailing line:

```
Repos with no open MRs: <count> — <comma-separated repo names, collapsed>
```

Repos where the `glab` call failed (network, auth, missing remote) get their own short **Failed** section at the bottom — one line each with the error. Do not retry.

Keep the whole report under ~50 lines. If a single repo has more than 10 open MRs, list the first 10 by `iid` and add a final line `… and <N> more — run \`glab mr list --repo <path> --state opened\` to see all`.

Stop after the report. Do not open, comment on, or merge any MR.
