# Claude Code — shared workspace config-layer guide

What lives under this `.claude/` bundle, how it gets wired into a workspace, and where to put new behavior. Reference material — most days you do not need to read it.

This bundle is **project-agnostic**. It is copied verbatim into any workspace that follows the shared workspace shape (`business/`, `product/`, `tech/`, plus a docs container — usually `docs/`, sometimes `agent-config/`). Every bundled command / skill discovers repos, stack pins, locale, and calendar rules from on-disk canonical files — never hard-coded.

## What lives in this bundle

```
.claude/
├── commands/          # slash-command macros — one .md per command, routed by first positional arg
├── hooks/             # generic bash-guard.sh, write-edit-guard.sh (project-agnostic)
├── skills/            # auto-discoverable procedures — one folder per skill, each with a SKILL.md
├── sounds/            # notification.wav, played by the Stop hook on Linux
├── settings.json      # hook wiring + permissions allowlist
├── claude-code-guide.md
└── commands-reference.md
```

The workspace root (the directory containing `business/ product/ tech/` + the docs container) is **not** a git repo. Install pattern is per-machine symlinks from `<workspace-root>/.claude/` into `<docs-container>/.claude/*`. Targets are version-controlled in the docs container, so `git pull` propagates updates automatically; the links themselves are per-machine.

## Setup — wire this directory into a workspace root

On a new machine, with Claude Code already installed, run `/setup link` once at the workspace root. The skill ([commands/setup.md](commands/setup.md), [skills/setup/SKILL.md](skills/setup/SKILL.md)) handles Ubuntu / WSL2 / macOS / Git Bash (`ln -s`) and native Windows (PowerShell `New-Item -ItemType SymbolicLink`, with `mklink` as elevated-cmd fallback). Idempotent; refuses to overwrite anything it did not create. To undo, run `/setup unlink`. First run triggers Claude Code's *"this project defines hooks, approve?"* prompt — approve once.

## Discovery — never hard-code

Every routed skill discovers three things at call time:

1. **Docs-container path.** Look for the directory that contains `.claude/`. Common shapes: `docs/` (Soradis, Heptapeak, Avakav, most projects), `agent-config/` (tizvir). Resolve by scanning workspace-root children for a `.claude/` subdirectory whose contents match this bundle's shape.
2. **Repo list.** Enumerate `<workspace-root>/docs`, `<workspace-root>/business/docs`, `<workspace-root>/product/docs`, `<workspace-root>/tech/docs`, plus every immediate subdirectory of `<workspace-root>/tech/` that contains a `.git` entry (directory or file — worktrees count). Any repo added later surfaces automatically.
3. **Per-repo default branch.** Resolve via `git symbolic-ref --short refs/remotes/origin/HEAD` and strip the `origin/` prefix. Docs repos typically default to `main`; engineering repos under `tech/` typically to `develop` with the `develop → staging → main` promotion chain. Never hard-code — every repo self-declares.

## Stack / locale / calendar knobs — read from canonical files

Skills that generate code or docs (`implement`, `docs`, `uiux`) read their pins from **the workspace's own architecture / design-system files**, never from the skill body. The canonical sources per knob:

| Knob | Canonical source |
|---|---|
| `ARCH_SHAPE` (microservices / monolith / hybrid) | `tech/docs/project-architecture/v<N>.md` §1 (or `tech/docs/v<N>/project-architecture.md`) |
| `HAS_KAFKA` / `HAS_REDIS` / `HAS_MINIO` / `HAS_MEILISEARCH` / `HAS_SHARED_LIBRARY` | same file, §3 backend stack + §5 infrastructure |
| `LOCALE_MODE` / `CALENDAR` / `DIGIT_RULES` | same file, §4 frontend stack (or design-system §1) |
| `OTP_PROVIDER` / `CDN_PROVIDER` / `CAPTCHA_PROVIDER` / `PSP_PROVIDER` | same file, §3 backend stack |
| `SHARED_LIBRARY_NAME` / `AUTH_OWNER` / `CONTENT_OWNER` / `SEARCH_OWNER` / … | same file, §1.1 backend map |
| Locale / direction / brand-mark path / spec-filename prefix for UI/UX | `product/docs/uiux/<version>/design-system/*.md` §1 Brand essentials |
| Standards (layout, testing, api, security, coding, frontend, git, …) | `tech/docs/standards/` — `microservice-layout.md` OR `monolith-layout.md` picked by `ARCH_SHAPE` |
| Feature scope (`[x]` = in, `[ ]` = deferred) | `product/docs/features/v<N>/all-features.md` |
| Per-repo contract | `<repo>/docs/v<N>/PRD-TDD.md` (some projects use `<repo>/doc/v<N>/`) |

If a canonical file is missing or unparseable, a skill stops and asks — it never guesses stack or locale.

## The seven layers (TL;DR)

| Mechanism | Loaded… | Best for | Context cost |
|---|---|---|---|
| **Always-on onboarding** (`CLAUDE.md`) | Every turn | Project map, hard rules, conditional `@path` index | Burns context every turn |
| **Slash command** (`commands/<name>.md`) | On user typing `/<name>` | User-named workflow macros, no assets | Zero baseline; description in always-on list |
| **Skill** (`skills/<name>/SKILL.md`) | On agent auto-route via description; user can also `/<name>` it | Auto-discoverable procedures, folders with assets | Zero baseline; description in always-on list |
| **Hook** (`settings.json` → `hooks`) | On system event (`PreToolUse`, `Stop`, …) | Guardrails and side effects with no agent judgment | Zero — runs in the harness |
| **`settings.json`** | By harness | Hook wiring, permissions, env vars | Zero — consumed by harness |
| **Memory** (runtime-specific project memory dir) | When the agent recalls a relevant entry | Cross-session facts about *you* | Cheap; only `MEMORY.md` index always-on |
| **Subagent** (`Agent` tool) / **MCP server** | When dispatched / invoked | Heavy parallel work / external system access | Per-invocation only |

**Rule of thumb.** Needed on turn 1, always → always-on file. Procedure named by user → slash command. Procedure auto-discovered by agent → skill. Must fire on an event → hook. About who you are / how you work → memory. Big or external → subagent / MCP.

## Per-layer notes

### Always-on onboarding file
Eager — loaded every turn. Use for project shape, hard rules, token recognition, conditional-reading `@path` index to standards docs. Avoid multi-step procedures (use a command or skill), long reference material (split out and `@path`-include), or anything user-specific (use memory). Past ~200 lines, value-per-token drops.

### Slash commands
Lazy — body loaded only when the user types `/<name>` (or the agent matches the `description:`). Use for short workflow macros that fit one file with no assets.

### Skills
Lazy — same loading model as commands, but the folder layout lets you ship templates, scripts, or sub-prompts alongside `SKILL.md`. Two layers: global at `~/.claude/skills/<name>/`, project at `<repo>/.claude/skills/<name>/`. The `description:` is the router — a routing-rule description listing every reasonable trigger phrase ("Use when the user asks to …") gets picked up.

Every `<name>` is paired: `commands/<name>.md` and `skills/<name>/SKILL.md` share the same body and routing. Each `<name>` routes to a sub-operation by its first argument; subsequent arguments are sub-op specific. Reference material that other skills compose with is folded into the same routed skill as its own sub-op (e.g. `/mr format` is loaded by other skills via `[[mr]]`).

### Hooks
The harness — not the agent — runs hooks on system events. Exit code `2` from a `PreToolUse` hook blocks the tool call and surfaces stderr as the rejection reason.

Wired in [settings.json](settings.json):

- **[hooks/bash-guard.sh](hooks/bash-guard.sh)** — `PreToolUse` on `Bash`. Blocks `--no-verify` / `--no-gpg-sign`, `Co-Authored-By:` footers in `git commit`, bulk staging (`git add -A` / `--all` / `.` / `*`), and direct `git push` to a protected branch (`main` / `staging` / `develop`).
- **[hooks/write-edit-guard.sh](hooks/write-edit-guard.sh)** — `PreToolUse` on `Write|Edit`. Blocks documents referring to derived-artifact markdown files (`CLAUDE.md`, `README.md`).
- **Project-specific guards** — schema invariants ("no `body_html` in a content service"), locale rules ("no Persian digits in machine-feed emitters"), or scope gates ("no money columns until vN") belong in a per-project sibling hook layered on top of the two generic hooks. Never add project-specific patterns into the two generic files above.
- **`Stop` notification sound** — plays `sounds/notification.wav` via `powershell.exe SoundPlayer` on Windows, `paplay`/`aplay`/`afplay` fallbacks on POSIX.

### settings.json
JSON consumed by the harness. Carries `hooks` (event-handler wiring), `permissions` (auto-allow vs prompt), and `env`. The shipped [settings.json](settings.json) wires the two `PreToolUse` guards, the `Stop` sound, and a read-only command allowlist (`git status` / `log` / `diff` / `branch` / `fetch` / `show` / `rev-parse` / `rev-list` / `worktree list`, `glab mr list` / `mr view` / `repo view`, `ls`).

### Memory
Per-project file store, indexed by an always-on `MEMORY.md`. Four flavors: `user`, `feedback`, `project`, `reference`. Use for facts that span conversations. Do not store codebase facts.

### Subagents and MCP servers
Delegation, not configuration.

## Decision matrix

| Question | Use |
|---|---|
| Needed on the first message of every turn? | Always-on onboarding file |
| Short procedure the *user* names explicitly? | Slash command |
| Procedure the *agent* should auto-discover from its description? | Skill |
| Procedure that needs scripts / templates / sub-prompts? | Skill (folder structure) |
| Must fire automatically on a system event? | Hook |
| Permission, env var, or hook wiring? | `settings.json` |
| About *me* or how I prefer to work? | Memory |
| Current-conversation state only? | Don't persist — context carries it |
| Big research or parallel investigation? | Subagent |
| Access to an external system? | MCP server |

## Naming standard for bundled commands and skills

The bundle ships **nine routed skills** — `workspace`, `setup`, `author`, `mr`, `docs`, `audit`, `uiux`, `implement`, `init`. The `init` skill routes the project-birth pipeline (six sub-ops: `product | business | design-system | features | tech-architecture | tech-standards`); the other eight are the ongoing workflow surface. Every entry is bare kebab-case, no prefix. If a specific workspace later needs isolation from a name collision, that workspace's install step can add its own prefix (e.g. `hp-` / `sd-` / `av-`) at symlink time — the shared bundle itself stays bare.

Rules for authoring new entries:

1. **Bare kebab-case name.** `commands/<name>.md` + `skills/<name>/SKILL.md`, always paired. `^[a-z][a-z0-9-]*$`. One word preferred (`workspace`, `mr`, `docs`, `implement`, `audit`, `uiux`, `setup`, `author`, `init`); multi-segment allowed for sub-ops (`design-system`, `tech-architecture`, `tech-standards`).
2. **First positional = sub-op.** Sub-ops live inside the skill as `## <sub-op>` sections, not as separate files.
3. **`::` separator for entity args.** The `argument-hint:` mirrors the grammar exactly.
4. **`|` for alternation** in every argument shape, prose, error message, and legal-value list. Never `or` / `vs` / `/`.
5. **No defaults.** Missing or unrecognized arg → stop and ask, never fall through.
6. **Positional only.** No `--flag=value`, no `-x` shorthand.
7. **Values globally unique** across every position — a token's position must be inferable from its value alone.
8. **Discovery over hard-code.** Every value that can be read from disk (repo list, default branch, stack pins, locale) must be read at call time.

Author new ones via `/author command <name>` (unpaired) or `/author skill <name>[::<sub-op-1>,<sub-op-2>,…]` (paired canonical form). See [commands-reference.md](commands-reference.md) for the full command catalog.
