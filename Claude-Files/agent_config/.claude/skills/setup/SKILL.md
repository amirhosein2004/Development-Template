---
name: setup
description: |
  How to set up and refresh the workspace's agent context — either by registering the workspace's shared Claude Code config under `<config-dir>/.claude/` into `<workspace-root>/.claude/` (five **relative** symlinks `../<config-dir>/.claude/<entry>`), or by meticulously re-reading every repo to rewrite the workspace-root `CLAUDE.md` and rebuild the project memory directory from scratch. First positional argument is `<link|unlink|refresh>`.

  `<config-dir>` is the workspace-root child directory that holds the shared Claude Code config (i.e. contains a `.claude/` subdir with `commands/`, `hooks/`, `skills/`, `sounds/`, and `settings.json`). Commonly `docs/` or `agent-config/`. Detected at call time — do not hardcode.

  - `link` registers / re-registers the shared config (idempotent — already-correct links are skipped; conflicts surface and stop, never overwrite). Works on Ubuntu / WSL2 / macOS / Git Bash (`ln -s`) and native Windows (`New-Item -ItemType SymbolicLink` in PowerShell with Developer Mode, or elevated `cmd.exe` `mklink`).
  - `unlink` removes the five symlinks and removes `<workspace-root>/.claude/` only if it is now empty.
  - `refresh` discovers repos from disk, reads each one's onboarding + standards + PRD-TDDs, rewrites the root `CLAUDE.md` in the conditional `@`-path table format, then wipes and refills the memory directory from zero.

  Use when the user asks to "register the shared config", "wire the .claude bundle into the workspace", "link the workspace .claude config", "install the workspace .claude", "set up the shared agent config for this workspace", "symlink <config-dir>/.claude/", "hook up the workspace claude config on a new machine", or to "refresh / rebuild / regenerate the workspace-root `CLAUDE.md`", "rebuild workspace memory", "refresh root context", "re-scan all repos and rewrite `CLAUDE.md`", or invokes `/setup`.

  If the first arg is missing or not one of `link` | `unlink` | `refresh`, stop and ask which sub-op — never default, never infer from the surrounding prompt. Do **not** use `refresh` for per-repo `CLAUDE.md` work — it is workspace-root + memory only, and it never touches anything under `<config-dir>/.claude/`.

  Refuses to run unless the CWD contains `business/`, `product/`, `tech/` as direct subdirectories **and** at least one child directory carrying a `.claude/` bundle (the workspace root). Never overwrites a non-link file, never recursively deletes a real directory, never touches anything outside `<workspace-root>/.claude/` (for `link` / `unlink`) or the workspace-root `CLAUDE.md` + project memory directory (for `refresh`).
---

# setup

Set up or refresh the workspace's agent context in one routed entry point.

```
/setup <link|unlink|refresh>
```

`<config-dir>` throughout this skill = the workspace-root child directory that contains a `.claude/` subdir with the shipped bundle's shape (`commands/`, `hooks/`, `skills/`, `sounds/`, `settings.json`). Commonly `docs/` or `agent-config/`. Resolved once at call time from the workspace root's immediate children — never hardcoded.

| Sub-cmd | Anchor | One-line summary |
|---|---|---|
| `link` | [`## link`](#link) | Create five **relative** symlinks `<workspace-root>/.claude/{commands,hooks,skills,sounds,settings.json}` → `../<config-dir>/.claude/<same-entry>`. Idempotent. |
| `unlink` | [`## unlink`](#unlink) | Delete the five symlinks; remove `<workspace-root>/.claude/` only if now empty. |
| `refresh` | [`## refresh`](#refresh) | Discover repos from disk, re-read onboarding + standards + PRD-TDDs, rewrite the workspace-root `CLAUDE.md`, wipe and refill project memory. |

If the first arg is missing or not one of `link` | `unlink` | `refresh`, stop and ask which sub-op — never default, never infer from the surrounding prompt. Even bare `/setup` with no second word stops and asks.

## link

Register the workspace's shared agent config under `<config-dir>/.claude/` into `<workspace-root>/.claude/` by creating five relative symlinks.

Workspace root is the directory that contains `business/`, `product/`, `tech/` as direct subdirectories plus at least one docs-container child (`<config-dir>`) carrying a `.claude/` bundle. This is **not** a git repo — that is why the install pattern is symlinks rather than a git submodule or plugin.

### Entries to manage

| Source under `<config-dir>/.claude/` | Destination under `<workspace-root>/.claude/` | Kind |
|---|---|---|
| `commands` | `commands` | directory symlink |
| `hooks` | `hooks` | directory symlink |
| `skills` | `skills` | directory symlink |
| `sounds` | `sounds` | directory symlink |
| `settings.json` | `settings.json` | file symlink |

Expected target is always `../<config-dir>/.claude/<entry>` (relative). **Never** absolute — absolute targets break when teammates clone the workspace at a different path.

### Step 1 — pre-flight

1. **Workspace-root check.** Confirm the CWD contains `business/`, `product/`, `tech/` as directories, plus at least one child directory holding a `.claude/` subdir. If any discipline is missing, or no docs-container child holds a `.claude/`, stop with `not at workspace root` and print the CWD. Do not walk upward looking for the root.
2. **Resolve `<config-dir>`.** Enumerate the workspace root's immediate child directories and pick the one whose `.claude/` subdir has all five bundle entries (`commands/`, `hooks/`, `skills/`, `sounds/`, `settings.json`). Commonly `docs/` or `agent-config/`. If more than one candidate matches, stop and ask which one to use.
3. **Source-layout check.** Confirm `<config-dir>/.claude/commands`, `<config-dir>/.claude/hooks`, `<config-dir>/.claude/skills`, `<config-dir>/.claude/sounds`, and `<config-dir>/.claude/settings.json` all exist with the correct kind. Anything missing → stop with `<config-dir>/.claude/ incomplete — pull <config-dir>/ first`.
4. **OS detection.** Run `uname -s 2>/dev/null` once.
   - `Linux` / `Darwin` / `MINGW*` / `MSYS*` / `CYGWIN*` → **POSIX** path: use `ln -s`.
   - Empty output or non-zero exit → **Windows-native** path: PowerShell `New-Item -ItemType SymbolicLink`, with `mklink` as the elevated-cmd fallback.

### Step 2 — create links

For each of the five entries, in parallel where possible:

1. **Inspect** `<workspace-root>/.claude/<entry>`.
   - **POSIX:** `readlink .claude/<entry> 2>/dev/null` (prints the target if it is a symlink, empty otherwise).
   - **Windows PowerShell:** `(Get-Item -Force .claude\<entry> -ErrorAction SilentlyContinue).Target`.
2. **Classify**:
   - Path does not exist → **create**.
   - Path is a symlink resolving to `../<config-dir>/.claude/<entry>` → **already-linked**, skip.
   - Path is a symlink resolving elsewhere → **conflict**, surface expected-vs-actual, do not overwrite.
   - Path is a real file or real directory → **conflict**, surface the kind, do not overwrite.
3. **Create** when classification is "create":

   **POSIX (Ubuntu / WSL2 / macOS / Git Bash)**

   ```sh
   mkdir -p .claude
   ln -s ../<config-dir>/.claude/<entry> .claude/<entry>
   ```

   **Windows PowerShell (Developer Mode on, or elevated)**

   ```powershell
   New-Item -ItemType Directory -Force -Path .claude | Out-Null
   New-Item -ItemType SymbolicLink -Path .claude\<entry> -Target ..\<config-dir>\.claude\<entry>
   ```

   **Windows elevated `cmd.exe`** — fallback only when PowerShell errors with a privilege message:

   ```cmd
   mkdir .claude
   mklink /D .claude\<entry> ..\<config-dir>\.claude\<entry>     :: for the four directories
   mklink    .claude\settings.json ..\<config-dir>\.claude\settings.json
   ```

4. **Verify** by re-running the inspect step. If verification fails, mark the row **failed** and continue — do not retry.

**Stop the whole run on the first conflict.** Never overwrite a path the user populated. The user resolves the conflict (rename the existing entry aside) and re-invokes.

### Reporting

Lead with one bolded header line: `## /setup link — <YYYY-MM-DD>`.

One markdown table — one row per entry:

| Entry | Action | Detail |
|---|---|---|
| `commands` | linked / already-linked / **conflict** / removed / not-present / **skipped (not a link)** | resolved target or conflicting-path kind |
| `hooks` | … | … |
| `skills` | … | … |
| `sounds` | … | … |
| `settings.json` | … | … |

Below the table, totals line: `**Totals**: X linked · Y already-linked · Z conflicts · W removed · V skipped.`

If any row is a conflict, follow with a `**Conflicts**` sub-section — one bullet per row with the exact instruction to resolve manually (rename aside, then re-invoke).

If the link pass ended cleanly, end with one line: `Launch a Claude Code session at the workspace root; approve the one-time hooks-approval prompt on first launch.`

Stop after the report. Never commit, push, open MRs, or modify any file outside `<workspace-root>/.claude/`.

## unlink

Remove the shared-config symlinks from `<workspace-root>/.claude/`.

Pre-flight is identical to [`## link`](#link) step 1 — same workspace-root check, same `<config-dir>` resolution, same source-layout check, same OS detection. The entry list and expected target are also identical (see the [Entries to manage](#entries-to-manage) table above).

### Step — delete links

For each of the five entries:

1. Inspect `<workspace-root>/.claude/<entry>` the same way as in [Step 2](#step-2--create-links).
2. If it is a symlink resolving to `../<config-dir>/.claude/<entry>` → delete:
   - **POSIX:** `rm .claude/<entry>`.
   - **Windows PowerShell:** `Remove-Item .claude\<entry>`.
3. If it is anything else (real file, real directory, symlink elsewhere) → **skip and surface**. Never `rm -rf`, never `Remove-Item -Recurse -Force`.

After all five passes, try to remove `<workspace-root>/.claude/` itself **only if empty**:

- **POSIX:** `rmdir .claude 2>/dev/null || true`.
- **Windows PowerShell:** `if (-not (Get-ChildItem .claude -Force)) { Remove-Item .claude }`.

Never delete a non-empty `.claude/` — it may hold `settings.local.json` or other per-machine state.

### Reporting

Lead with one bolded header line: `## /setup unlink — <YYYY-MM-DD>`.

One markdown table — one row per entry, same shape as the `link` reporting table (rows take `removed` / `not-present` / `**skipped (not a link)**` here). Same totals line.

If any row is `skipped (not a link)`, follow with a `**Conflicts**` sub-section — one bullet per row with the exact instruction to resolve manually.

Stop after the report. Never commit, push, open MRs, or modify any file outside `<workspace-root>/.claude/`.

## refresh

This sub-command rebuilds two pieces of agent context for the workspace, end-to-end, in one pass:

1. The workspace-root `CLAUDE.md` at `<workspace-root>/CLAUDE.md`.
2. The project memory directory at the runtime's `~/.claude*/projects/<encoded-workspace-path>/memory/`.

It does **not** touch any per-repo `CLAUDE.md` / `README.md`, does **not** touch anything under `<config-dir>/.claude/` (the shared config — commands, hooks, skills, sounds, settings.json, reference docs — is version-controlled in `<config-dir>/` and out of scope), does not stage / commit / push, and does not open merge requests. The workspace root is not a git repo; the root `CLAUDE.md` and the memory directory live outside any tracked repository.

Workspace root in this sub-command = the directory that contains `business/`, `product/`, `tech/`, and at least one docs container carrying a `.claude/` bundle (`<config-dir>`). Use the absolute path in every `Bash` call so the working directory does not drift between steps.

Execute the five phases below in order, without stopping for confirmation between them.

### Phase 0 — Sanity-check the environment

One `Bash` call:

```sh
ls -1 <workspace-root> \
  && echo --- \
  && ls -1d <workspace-root>/business/*/ <workspace-root>/product/*/ <workspace-root>/tech/*/ 2>/dev/null \
  && echo --- \
  && ls -1d <workspace-root>/scripts <workspace-root>/scripts/*/ 2>/dev/null
```

Verify from the output:

- Workspace root contains `business/`, `product/`, `tech/`, at least one docs-container child (`<config-dir>`), the existing `CLAUDE.md` (if one exists), and `tmp/` (if one exists). `scripts/` is **optional** — if present, note it and read below; if absent, skip.
- The repo discovery glob returns whatever directories currently exist under `business/`, `product/`, and `tech/`. Do not assume a fixed count — enumerate what's on disk.
- The scripts probe returns either `scripts/` itself (single-repo layout — `<workspace-root>/scripts/.git` present) or `scripts/<name>/` subdirectories (multi-repo layout — each subdirectory has its own `.git`). Include whichever `.git` entries actually exist; skip if neither.

If any of the mandatory disciplines (`business/`, `product/`, `tech/`) or the docs container is missing, stop and surface the problem — do not invent a workspace layout.

### Phase 1 — Wipe memory

Delete every `.md` under the runtime's project memory directory, including `MEMORY.md`. Phase 4 will rebuild from zero.

```sh
rm -f <memory-dir>/*.md
```

Do **not** `rm -rf` the directory itself. Keep it in place — Phase 4 writes back into it. Do not touch sibling `projects/` entries.

### Phase 2 — Meticulously explore the workspace

Ground the rewrite in current truth, not in the existing `CLAUDE.md`. Read **before** you write. Do not edit any file in this phase.

#### 2.1 — Discover the repo list from disk

Authoritative source of truth is the filesystem, not the current `CLAUDE.md`. One `Bash` call:

```sh
ls -1d <workspace-root>/<config-dir> \
        <workspace-root>/business/docs \
        <workspace-root>/product/docs \
        <workspace-root>/tech/docs \
        <workspace-root>/tech/*/ \
        <workspace-root>/scripts \
        <workspace-root>/scripts/*/ 2>/dev/null
```

Enumerate whatever exists — do **not** assume a fixed number of repos. Typical shape:

| Class | Where | Default branch |
|---|---|---|
| Umbrella docs / shared config | `<config-dir>/` | resolve at call time |
| Discipline docs (present when the discipline ships a `docs/` sub-repo) | `business/docs/`, `product/docs/`, `tech/docs/` | resolve at call time |
| Engineering repos | every child directory under `tech/` (any naming — `backend-*`, `frontend-*`, `infra-*`, libraries, and future patterns) | resolve at call time |
| Workspace-tooling repos (optional) | `scripts/` itself (single-repo layout — `scripts/.git` present) OR every `scripts/<name>/` with its own `.git` (multi-repo layout, e.g. `scripts/initializer`) | resolve at call time |

Resolve each repo's default branch at call time via `git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null` (fall back to `git -C <repo> rev-parse --abbrev-ref HEAD` when there is no `origin/HEAD`). Do not hardcode branch names. Any repo the discovery finds joins the table without editing the skill.

**`scripts/` handling** — probe at call time; not every project ships one:
- No `<workspace-root>/scripts/` → skip.
- `<workspace-root>/scripts/.git` present → single-repo layout; workspace-relative path is `scripts`.
- Otherwise, every `<workspace-root>/scripts/<name>/.git` present → multi-repo layout; workspace-relative path per repo is `scripts/<name>`.
- Include whichever `.git` entries actually exist; scripts repos are treated identically to any other engineering repo in every phase below (onboarding read, standards read, PRD-TDD read where present, root `CLAUDE.md` row, memory entry).

If the filesystem disagrees with the current `CLAUDE.md` (a repo appeared or disappeared), the filesystem wins.

#### 2.2 — Read each repo's onboarding contract

For every discovered repo, read **in parallel** (fan out one `Read` call per file per repo, batched into single messages of ≤ 20 reads):

- `<repo>/CLAUDE.md` — the per-repo onboarding file (where present). Some repos ship only a `README.md` until their `CLAUDE.md` layer lands.
- `<repo>/README.md` — for the human-readable overview where it adds something the `CLAUDE.md` omits (and the sole onboarding signal in repos without a `CLAUDE.md`).
- `<repo>/docs/` and `<repo>/standards/` — read every relevant file end-to-end when the target is an engineering repo under `tech/` (per the workspace's `Grounding before working on tech/` rule). Extend the read set as they fill.

If a repo lacks `CLAUDE.md`, flag it in the final report but continue.

#### 2.3 — Read the standards layer

Read in parallel every file present under each of these locations (skip silently what is not on disk — do not fail):

- Everything under `<config-dir>/standards/` if it exists (cross-repo baseline — git, MR shape, hard rules). Common file: `git.md`. Future files (`documentation.md`, `adr-template.md`, brand voice if reused across repos) join as they land. Some workspaces place this content under `docs/standards/` — read whichever exists.
- Everything under `tech/docs/standards/` if `tech/docs/` exists (engineering baseline — layout, infrastructure, API + data contracts, errors + observability, security + auth, coding, frontend, frontend-layout, CI/CD, testing, documentation, per-discipline git deltas). Landings grow file-by-file; read what exists and ignore what doesn't.
- `tech/docs/v1/project-architecture.md` (or the equivalent versioned platform architecture file — some projects use `tech/docs/vN/`) if present.
- `<workspace-root>/architecture-decisions.md` if present — locked architectural decisions that bind every repo.
- Index of `business/docs/competitor-analysis/` (`ls -1` is enough; only read the top-level synthesis files plus any audit prompt), when present.
- Index of `product/docs/features/v1/` (`ls -1`; only read the front-matter of `all-features.md` for `derived_from` / `audited_at`) and of `product/docs/uiux/v1/`, when present. Some projects use `vN` other than `v1` — read whichever exists.

#### 2.4 — Read each service's PRD-TDD

For every engineering repo under `tech/`:

- `<repo>/docs/v1/PRD-TDD.md` if present — that's where service-level invariants live (which async topics it owns, which object-storage buckets, which cache namespace, which `<service>__` tables, etc.). Some projects use `<repo>/doc/vN/PRD-TDD.md` (singular `doc/`) or a different version folder — read whichever path exists. Read what exists and skip silently where absent.

Skim only — extract the one-line invariants that need to appear in the **Repo map** Notes column of the root `CLAUDE.md`.

#### 2.5 — Note what is **not** in scope

- `tmp/` — scratch space. Do **not** scan, do **not** read.
- `<config-dir>/.claude/` — the shared config itself. `refresh` never touches it (hard rule); read nothing under it except command frontmatter needed for §4 of Phase 3.
- The existing root `CLAUDE.md` — read it once at the start of Phase 3 only to diff what you're about to rewrite against; do not treat it as ground truth for repo identity.

### Phase 3 — Rewrite the workspace-root `CLAUDE.md`

Overwrite `<workspace-root>/CLAUDE.md` with the **conditional `@`-path format**. The shape below is mandatory; the contents come from Phase 2.

#### 3.1 — Required sections, in order

1. **Title + one-paragraph purpose.** Name the project, state the workspace is **not** a git repo, give the repo total as `<N> repos in total (<M> docs + <E> engineering)` — derive both counts from Phase 2.1 rather than hardcoding. If the count shifts between refresh runs, the number here shifts with it.

2. **Repo map** — one Markdown table, one row per discovered repo, in this order: docs first (`<config-dir>`, `business/docs`, `product/docs`, `tech/docs` — whichever exist), then engineering repos under `tech/` sorted alphabetically. Columns:

   | Column | Contents |
   |---|---|
   | Path | repo path relative to workspace root, in backticks |
   | Default branch | resolved per-repo at call time from `origin/HEAD` (do not hardcode). |
   | Notes | one line — what the repo owns, with the binding invariants collected in Phase 2.4 inlined |

3. **Conditional reading (read on demand)** — one Markdown table, two columns: *When the prompt is about…* and *Read*. Path cells are backtick-wrapped with a leading `@` so the path reads as a reference without triggering Claude Code's auto-import. Paths are **relative to the workspace root**. Include only rows whose targets actually exist on disk (Phase 2 discovered them). Common rows:

   - Cross-repo git baseline (every repo) → `@<config-dir>/standards/git.md` or `@docs/standards/git.md`, whichever exists
   - Locked architectural decisions (when `architecture-decisions.md` exists) → `@architecture-decisions.md`
   - Engineering standards (when `tech/docs/standards/` exists) → `@tech/docs/standards/`
   - Platform architecture (when it exists) → `@tech/docs/v1/project-architecture.md` (or the discovered path)
   - Brand assets → `@business/docs/brand/`
   - Competitor research → `@business/docs/competitor-analysis/`
   - v1 feature catalogue (only `[x]` items ship) → `@product/docs/features/v1/all-features.md`
   - v1 UI/UX pages and design system → `@product/docs/uiux/v1/`
   - Per-service PRD-TDD (when `tech/<repo>/docs/v1/PRD-TDD.md` exists) → `@tech/<repo>/docs/v1/PRD-TDD.md`
   - Per-repo onboarding rules — when working in a specific repo → `@<repo>/CLAUDE.md`

   Future files that arrive under either directory extend these rows, not new ones.

4. **Workflow** — the six-step procedure for changing anything in any repo: read relevant standards first → worktree from the repo's fresh default branch under `tmp/worktrees/<repo-short-name>` → edit there → open MR back to the default branch → squash-merge → pull → clean up. Note the branch-naming convention for workspace-level multi-repo passes (`document/root/<2-4-word-description>`) and the *"one concern per MR"* rule. Close the section by stating the mechanical work is codified in the bundled slash commands that live as skills under `<config-dir>/.claude/skills/` and whose full descriptions are auto-loaded into every session, then list the routine-workflow shortcuts — `/workspace sync`, `/workspace status`, `/workspace mrs`, `/mr open`, `[[mr]]` — each with a one-line description matched to the command file's frontmatter (include the *"load before authoring any MR"* hint on `[[mr]]`). Discover the command list dynamically with `ls <workspace-root>/<config-dir>/.claude/commands/` so any newly-added routine-workflow command is included automatically; the domain scaffolders (`docs`, `implement`, `author`, etc.) stay out of this shortcut list — they're auto-loaded as skills and don't belong in the root workflow summary.

5. **Grounding before working on `tech/`** — one dedicated `##` section of its own, with one bolded rule. Do **not** bury this inside the Workflow section, the conditional-reading table, or Hard rules — the whole point is that it must be impossible to miss. Word it as a hard workflow requirement, not a suggestion:

   > **Before any coding, implementation, scaffolding, refactor, or engineering-shaped task targeting `tech/` (whether `tech/docs/` today or any engineering repo under `tech/`), read the target repo's onboarding (`<repo>/CLAUDE.md`) and every relevant file under its `docs/` and `standards/` directories end-to-end first.** A partial skim is not sufficient. Prior-session memory is not sufficient. Engineering context has higher blast radius than doc edits, and the agent must not begin work until it has re-grounded on the current on-disk state.

   Enumerate the current mandatory grounding set from Phase 2: whichever of `tech/docs/standards/`, `tech/docs/v1/project-architecture.md`, `architecture-decisions.md`, per-repo `CLAUDE.md`, and per-repo `docs/v1/PRD-TDD.md` actually exist on disk. As per-repo files land (PRD-TDDs first), they become mandatory reads before any work on that repo; extend (never remove) this rule as they arrive.

6. **Hard rules (do not violate, anywhere in this workspace)** — open the section with one preamble sentence: *"Items marked **[hook]** are also blocked at the tool layer by `.claude/hooks/{bash,write-edit}-guard.sh`. If you see a `BLOCKED` message, fix the offense — never bypass."* Then bullets. Discover the hook-enforced rules by reading `<config-dir>/.claude/hooks/bash-guard.sh` and `<config-dir>/.claude/hooks/write-edit-guard.sh` — mark each corresponding bullet `**[hook]**`. Common bullets (include only those actually present in the project's ruleset or hook scripts):

   - **[hook]** No `Co-Authored-By:` footers on commits or MR descriptions.
   - **[hook]** No references to `CLAUDE.md` / `README.md` inside documents (they're derived; inline the relevant content instead).
   - **[hook]** No direct push to `main`.
   - **[hook]** No bulk staging (`git add -A` / `--all` / `.` / `*`), no `--no-verify`, no `--no-gpg-sign`.
   - Any project-specific hook-enforced rules discovered from the two guard scripts (content-body invariants, digit / calendar rules on machine-feed emitters, forbidden schema columns, etc.).
   - No committed secrets, credentials, `.env*`, private keys, or auth tokens.
   - Only `[x]` features in `product/docs/features/v1/all-features.md` are in scope. `[ ]` items are automatic 🔴 in review until flipped.
   - Any project-declared positioning / scope invariants surfaced in Phase 2 (e.g. "multi-language is one feature among many — never headline it" when the project has declared it).
   - `refresh` never touches `<config-dir>/.claude/*` — the shared config is version-controlled in `<config-dir>/`; only the workspace-root context file and project memory are rewritten.

   The `[hook]` markers must match what the two guard scripts actually enforce; before writing this section, re-read the two scripts and update the `[hook]` markers if a hook check has been added, removed, or its scope has shifted.

7. **Temporary scratch files** — `tmp/` is the destination for ad-hoc `.md` files; `tmp/` should not be scanned unless required; worktrees live under `tmp/worktrees/`.

#### 3.2 — Style constraints

- Wrap every workspace-relative path in backticks. Wrap every `@`-prefixed reference in backticks too — Claude Code only auto-imports unbacktick'd `@paths`, so the backticks are load-bearing.
- Use bold for emphasis (`**…**`) sparingly — invariants only, not every noun.
- No headings beyond H2 (`##`); the file must read top-to-bottom without nested H3 fluff.
- No "Last updated:" date line, no "Generated by" footer, no Claude/agent attribution.
- No CLAUDE.md / README.md cross-references in the rewritten file — even though this *is* a CLAUDE.md, the rule "documents do not refer to CLAUDE.md / README.md" still applies to its content (i.e. don't write *"see the per-repo README"* inside; inline instead).

#### 3.3 — Write

Use the `Write` tool against the absolute path `<workspace-root>/CLAUDE.md`. The existing file gets overwritten — read it once first (so the `Write` tool's safety check passes), then replace it wholesale.

### Phase 4 — Refill memory

Populate the runtime's project memory directory with the discrete knowledge a future agent needs cold. Memory is for things that are **not** derivable from reading the workspace — repo structure and current `CLAUDE.md` content are derivable, so don't duplicate them.

#### 4.1 — Required entries (minimum)

Each entry is its own `.md` file with the standard memory frontmatter, in the format the runtime expects:

```markdown
---
name: <kebab-slug>
description: <one-line — used to decide relevance in future conversations, so be specific>
metadata:
  type: <user | feedback | project | reference>
---

<body — for feedback / project, structure as: rule/fact, then **Why:** and **How to apply:** lines. Link related memories with [[name]].>
```

Minimum set, one file per entry:

| File | Type | What it captures |
|---|---|---|
| `project-shape.md` | `project` | The project's one-paragraph identity, the total repo count (derived from Phase 2.1 — do not hard-code numbers that could drift), and one-line per repo of what it owns. |
| `workflow.md` | `project` | Multi-repo workflow: worktree under `tmp/worktrees/` from fresh default branch → edit → MR back to that default → squash-merge → ff-pull → clean. Branch naming `document/root/<2-4-word-description>` for cross-repo passes. Default branches resolved per-repo, not hardcoded. Tech-grounding requirement is non-negotiable. |
| `hard-rules.md` | `feedback` | The hard rules from Phase 3.1 §6, copied as-is — preserve the `[hook]` markers and the hook-enforcement preamble so memory matches the root context file. **Why:** these are the invariants the user has reaffirmed across sessions; the `[hook]` markers signal which ones the tool layer also blocks. **How to apply:** every commit, every MR, every doc edit, in every repo. |
| `locked-decisions.md` | `project` | The locked architectural decisions every skill honors (from `architecture-decisions.md` if present) — one line each, plus one line of *why they are locked, not preferences*. Skip this file if the project has no `architecture-decisions.md`. **How to apply:** check any relevant work against them before writing a line. |
| `claude-md-style.md` | `feedback` | Every root-context file uses the conditional-reading `@path` table format: purpose paragraph → repo map (root only) → conditional-reading table → repo-local rules → hard rules. Backtick-wrapped `@paths` to prevent auto-import. |
| `slash-commands.md` | `reference` | List of workspace-wide slash commands under `<config-dir>/.claude/commands/` (discovered in Phase 3.1 §4), each with a one-line description from its frontmatter. Note that `/setup refresh` rebuilds the root context file + memory itself. |

Link related entries with `[[name]]` — e.g. `claude-md-style.md` should link to `[[hard-rules]]` and `[[project-shape]]`, and `locked-decisions.md` should link to `[[project-shape]]`.

If Phase 2 surfaced a stable, non-obvious fact that doesn't fit any of the entries above (e.g. a cross-cutting invariant from a standards file or a PRD-TDD), add a new entry rather than stuffing it into an existing one.

#### 4.2 — Update `MEMORY.md`

Write `MEMORY.md` as a plain index — no frontmatter, one bullet per entry, in this exact format:

```markdown
- [<Title>](<file>.md) — <one-line hook, <150 chars>
```

Keep the whole file under 200 lines (it gets truncated past that point and the truncation is silent).

#### 4.3 — What **not** to write to memory

Do not save any of:

- The current repo list in detail (already in the root context file).
- The conditional-reading paths (already in the root context file).
- Code patterns, file paths, or architecture details derivable from reading the workspace.
- Per-session context, in-progress task notes, or "today's plan".
- Anything that duplicates what the root context file already encodes — memory is for what it can't carry.

### Phase 5 — Report

End the run with exactly this report shape:

```markdown
## /setup refresh — <YYYY-MM-DD>

- **Root context file:** rewrote `<absolute-path>` (<N> lines).
- **Memory:** wrote <K> entries; `MEMORY.md` index = <I> lines.
- **Repos read:** <N> discovered (<M> docs + <E> engineering under `tech/`). New since prior root context: <list or `none`>. Missing: <list or `none`>.
- **No per-repo file was touched.**
```

If anything in Phase 2 surfaced a discrepancy worth raising (a repo without its per-repo onboarding file, a standards file the conditional-reading table doesn't yet cover, an invariant in a PRD-TDD that contradicts the prior root context), add one short `**Notes**` bullet list under the report.

Do not include co-author / agent-attribution lines anywhere in the report or in any file written by this sub-command.
