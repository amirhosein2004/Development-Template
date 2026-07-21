---
description: setup — link|unlink|refresh. Symlinks <config-dir>/.claude/ into workspace .claude/ (idempotent), or re-reads every repo to rewrite workspace CLAUDE.md and rebuild memory.
argument-hint: <link|unlink|refresh>
---

Set up or refresh the workspace's agent context. One positional argument:

- **`link`** — create five **relative** symlinks under `<workspace-root>/.claude/` pointing at `../<config-dir>/.claude/<entry>`. Idempotent: if a correct link already exists, skip it; if something **else** lives at the path, surface the conflict and stop without overwriting.
- **`unlink`** — delete the five symlinks under `<workspace-root>/.claude/`, then remove the `.claude/` directory itself if (and only if) it is now empty. Never deletes a real file or a third-party `.claude/` entry the user added.
- **`refresh`** — meticulously re-read every repo, clean and rewrite the workspace-root context file, and rebuild the project memory directory from scratch.

If the argument is missing or not one of `link` | `unlink` | `refresh`, stop and ask which sub-op — never default, never infer from the surrounding prompt. Even bare `/setup` with no second word stops and asks.

`<config-dir>` = the workspace-root child directory that carries the shared Claude Code config (i.e. contains a `.claude/` subdir with `commands/`, `hooks/`, `skills/`, `sounds/`, and `settings.json`). Commonly `docs/` or `agent-config/`. Detected at call time — do not hardcode.

| Sub-cmd | Anchor | One-line summary |
|---|---|---|
| `link` | [`## link`](#link) | Create five relative symlinks `<workspace-root>/.claude/{commands,hooks,skills,sounds,settings.json}` → `../<config-dir>/.claude/<same-entry>`. Idempotent. |
| `unlink` | [`## unlink`](#unlink) | Delete the five symlinks; remove `<workspace-root>/.claude/` only if now empty. |
| `refresh` | [`## refresh`](#refresh) | Discover repos from disk, re-read onboarding + standards + PRD-TDDs, rewrite the workspace-root context file, wipe and refill project memory. |

## link

Wire the workspace's shared Claude Code config into `<workspace-root>/.claude/` by creating five relative symlinks.

### Step 1 — pre-flight (both OSes)

1. **Confirm CWD is the workspace root.** The directory must contain `business/`, `product/`, `tech/` as subdirectories, **plus at least one docs container** — a child directory that holds a `.claude/` subdir. If any of the three disciplines is missing or no docs-container child holds a `.claude/`, stop with `not at workspace root` and print the CWD. Do not try to detect by walking upward — explicit is safer.
2. **Resolve `<config-dir>`.** Scan the workspace root's immediate children for a directory containing a `.claude/` subdirectory whose shape matches the shipped bundle (has `commands/`, `hooks/`, `skills/`, `sounds/`, `settings.json`). The name is commonly `docs/` or `agent-config/` — do not hardcode. If more than one candidate exists, stop and ask which one to use.
3. **Confirm source layout.** All five entries `<config-dir>/.claude/{commands,hooks,skills,sounds,settings.json}` must exist with the correct kind (directories vs file). If any is missing, stop with `<config-dir>/.claude/ incomplete — pull <config-dir>/ first`.
4. **Detect the OS once.** Run `uname -s 2>/dev/null`.
   - Output `Linux`, `Darwin`, or one of `MINGW*` / `MSYS*` / `CYGWIN*` → treat as **POSIX** and use `ln -s`.
   - Empty output or non-zero exit → treat as **Windows-native** and use PowerShell `New-Item -ItemType SymbolicLink` (with `mklink` as the elevated-cmd fallback).

The five entries and their kinds:

| Source under `<config-dir>/.claude/` | Destination under `.claude/` | Kind |
|---|---|---|
| `commands` | `commands` | directory |
| `hooks` | `hooks` | directory |
| `skills` | `skills` | directory |
| `sounds` | `sounds` | directory |
| `settings.json` | `settings.json` | file |

The expected symlink target is always `../<config-dir>/.claude/<entry>` (relative — never absolute).

### Step 2 — create links

For each of the five entries:

1. **Inspect** `.claude/<entry>`.
   - **POSIX:** run `readlink .claude/<entry> 2>/dev/null`.
   - **Windows PowerShell:** run `(Get-Item -Force .claude\<entry> -ErrorAction SilentlyContinue).Target`.
2. **Classify** the result:
   - Path does not exist → **create**.
   - Path exists, is a symlink, and resolves to `../<config-dir>/.claude/<entry>` → **skip — already linked**.
   - Path exists, is a symlink, but resolves elsewhere → **conflict**: print expected vs actual target, do not overwrite.
   - Path exists and is *not* a symlink (real file or real directory) → **conflict**: print the kind, do not overwrite.
3. **Create** when needed:

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

   **Windows elevated cmd.exe (Developer Mode off)** — fallback only when PowerShell errors with a privilege message.

   ```cmd
   mkdir .claude
   mklink /D .claude\<entry> ..\<config-dir>\.claude\<entry>     :: for the four directories
   mklink    .claude\settings.json ..\<config-dir>\.claude\settings.json
   ```

4. **Verify** the new link resolves to the expected relative target (re-run the inspect step). If the verification fails, mark the row as **failed** and continue — do not retry.

Fan the five entries out in parallel where possible (one `Bash` / PowerShell call per entry), but stop the whole step on the first **conflict** — never overwrite something the user put there.

## unlink

Remove the shared-config symlinks. Pre-flight is identical to the [`link`](#link) pre-flight — same workspace-root check, same `<config-dir>` resolution, same source-layout check, same OS detection. The entry list and expected target are also identical.

For each of the five entries:

1. Inspect `.claude/<entry>` the same way as the `link` step 2.
2. If it is a symlink to `../<config-dir>/.claude/<entry>` → delete:
   - **POSIX:** `rm .claude/<entry>`.
   - **Windows PowerShell:** `Remove-Item .claude\<entry>`.
3. If it is anything else (real file, real directory, or a symlink pointing elsewhere) → **skip and surface** the path. Never `rm -rf`, never `Remove-Item -Recurse -Force`. The user owns anything they added themselves.

After all five passes, attempt to remove the `.claude/` directory **only if empty**:

- **POSIX:** `rmdir .claude 2>/dev/null || true`.
- **Windows PowerShell:** `if (-not (Get-ChildItem .claude -Force)) { Remove-Item .claude }`.

Never delete a non-empty `.claude/` — there may be `.claude/settings.local.json` or other per-machine state.

## Reporting (link / unlink)

One markdown table after the pass. Lead with one bolded header line: `## /setup <link|unlink> — <YYYY-MM-DD>`.

| Entry | Action | Detail |
|---|---|---|
| `commands` | linked / already-linked / **conflict** / removed / not-present / **skipped (not a link)** | resolved target, or the conflicting path's kind |
| `hooks` | … | … |
| `skills` | … | … |
| `sounds` | … | … |
| `settings.json` | … | … |

Below the table, totals line: `**Totals**: X linked · Y already-linked · Z conflicts · W removed · V skipped.`

If any row is a conflict (`link`) or skipped-not-a-link (`unlink`), follow with a `**Conflicts**` sub-section, one bullet per row, with the exact instruction the user should run to resolve (rename the existing entry aside, then re-invoke). Do not auto-resolve.

If the `link` pass ended cleanly, follow the totals line with a one-line **next step**: `Launch a Claude Code session at the workspace root; approve the one-time hooks-approval prompt on first launch.`

Stop after the report. Do not commit, push, open MRs, or modify any file outside `<workspace-root>/.claude/` — this sub-command only manages symlinks at the workspace root.

## refresh

Refresh the **workspace-root context file** and the project memory for the workspace, grounded in what is true on disk right now (not in what the existing context file or memory currently claim).

Workspace root is the directory that contains `business/`, `product/`, `tech/`, and at least one docs container (`<config-dir>`). This is **not** a git repo; the root context file and the memory directory live outside any tracked repository, so no MR / push / branching is involved.

The full procedure lives in the [`setup`](../skills/setup/SKILL.md) skill under the `## refresh` section. Load it now and execute every step end-to-end, without pausing for confirmation between steps.

Hard constraints (also enforced by the skill — repeated here so they bind even if the skill body drifts):

- Do **not** edit any file under any repo (`business/`, `product/`, `tech/`, or the docs container(s), including their per-repo onboarding files). The only files this sub-command writes are the workspace-root context file and the memory directory contents.
- Do **not** touch anything under `<config-dir>/.claude/` — refresh never edits the shared config itself (commands, hooks, skills, sounds, settings.json, reference docs).
- Do **not** scan or read `tmp/` — it's scratch space.
- Do **not** open any merge request, push, branch, or commit. There is no git anywhere in this flow.
- No `Co-Authored-By:` lines, no Claude/agent attribution in anything written.

Report at the end with: the absolute path of the rewritten root context file, the count of memory entries written (and `MEMORY.md` line count), and a one-line confirmation that no per-repo file was touched.
