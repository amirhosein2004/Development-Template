---
name: author
description: |
  Scaffold new bare-name slash commands and skills for the shared workspace bundle. First positional argument is `<command|skill>`; the remaining tokens are parsed per sub-op contract.

  - `command <name>` — write an unpaired single-file slash command at `<config-dir>/.claude/commands/<name>.md`, plus reference-doc entries in `claude-code-guide.md` and `commands-reference.md`.
  - `skill <name>[::<sub-op-1>,<sub-op-2>,…]` — write the canonical paired artifact (both `skills/<name>/SKILL.md` and `commands/<name>.md`), plus reference-doc entries. Trailing sub-op list flips the body to a routed layout; absent → single-purpose.

  Use when the user asks to "scaffold a new command", "add a new skill", "create a routed skill with sub-ops X and Y", "generate the paired command + skill for <name>", "author a new bundled entry", "start a new slash command for the workspace", or invokes `/author`.

  If the first arg is missing or not one of `command` | `skill`, stop and ask which sub-op — never default. Every sub-op writes files only (no stage / commit / push / MR); ship with `/mr open current` afterwards.

  Refuses on precondition violations: `<name>` missing / non-kebab / equal to `command` | `skill`; sub-op tokens duplicated / equal to `command` | `skill` | `<name>`; existing files at any target path. Refusals name the offending value. No prefix is added — the user supplies the final `<name>` verbatim; per-workspace prefixing (`hp-` / `sd-` / project-slug-based) is handled at install time, not by the scaffold.
---

# author — scaffold new bundled commands and skills

```
/author command <name>
/author skill   <name>[::<sub-op-1>,<sub-op-2>,…]
```

`<config-dir>` is the workspace's docs container — the child of the workspace root that carries a `.claude/` folder matching this bundle's shape. Discover it at call time by scanning workspace-root children (usually `docs/`; sometimes `agent-config/`). Never hard-code.

| Sub-op | Anchor | One-liner |
|---|---|---|
| `command` | [`## command`](#command) | Scaffold an unpaired single-file slash command at `commands/<name>.md`. |
| `skill` | [`## skill`](#skill) | Scaffold the canonical paired artifact — `skills/<name>/SKILL.md` + `commands/<name>.md`. Optional sub-op list flips to a routed layout. |

If the first arg is missing or not one of `command` | `skill`, stop and ask which sub-op — never default. If the first arg is recognized but the remainder is malformed, refuse with the offending value named.

## Authoring rules — apply to every sub-op

1. **Positional arguments only.** No `--foo=bar`, no `--name value`. Positional slots separated by `::`.
2. **Argument values are globally unique across positions.** No slot's legal values overlap another's. This skill refuses to author a thing named `command` or `skill`, refuses sub-op tokens equal to `command` | `skill`, and refuses a sub-op token that equals the `<name>` slot.
3. **No defaults for any argument.** Missing or unrecognized → stop and ask.
4. **Use `|` for alternation.** Never `or` / `vs` / `/`.
5. **Propagate to both reference docs on every authoring run.** Update `<config-dir>/.claude/claude-code-guide.md` and `<config-dir>/.claude/commands-reference.md` in the same run.

## Naming standard the scaffold enforces

- **Bare kebab-case name — no prefix added.** The user supplies the final `<name>` verbatim; the skill writes files at exactly that path. The shared bundle uses no prefix (`workspace`, `mr`, `docs`, …); per-workspace prefixing (`hp-` / `sd-` / project-slug-based) is handled at install time by that workspace's own rename or symlink step — not by the scaffold.
- **Domain matches** `^[a-z][a-z0-9-]*$`. One word preferred (`workspace` / `mr` / `docs` / `implement` / `setup` / `author` / …); multi-segment allowed (`design-system-init`, `product-init`).
- **Command file and skill folder share the same name** (`commands/<name>.md` + `skills/<name>/SKILL.md`).
- **First positional of the new thing is its sub-op** (when routed); sub-ops live inside as `## <sub-op>` sections.
- **Entity-shaped args use `::` as separator.** The scaffolded `argument-hint:` mirrors the grammar exactly.

The shared bundle runs eight routed top-level commands; new behavior lands as a sub-op under one of them rather than as a new top-level. If the existing taxonomy already covers the new behavior (fits cleanly under `workspace` / `mr` / `docs` / `implement` / `setup` / `author` / `audit` / `uiux`), warn once and ask whether to extend an existing routed skill instead. Only add a new top-level when it genuinely cannot fit.

## command

Scaffold an unpaired single-file slash command at `<config-dir>/.claude/commands/<name>.md`. Use for one-off macros that don't need the skill's agent-routing surface.

### Argument

`/author command <name>`

| Slot | Required | Shape |
|---|---|---|
| `<name>` | yes | `^[a-z][a-z0-9-]*$` |

### Refusal conditions

- `<name>` missing → ask.
- `<name>` doesn't match `^[a-z][a-z0-9-]*$` → kebab-case required; ask.
- `<name>` equals `command` or `skill` → uniqueness rule; ask.
- `<config-dir>/.claude/commands/<name>.md` exists → refuse to overwrite.

### What it writes

- `<config-dir>/.claude/commands/<name>.md` — frontmatter (`description: <name> — <one-line summary>.` + `argument-hint: <TODO>`), body with Synopsis and an authoring-rules reminder.
- `<config-dir>/.claude/claude-code-guide.md` — add `<name>` to the commands paragraph.
- `<config-dir>/.claude/commands-reference.md` — new (or merged) section with a single-row table.

Writes files only. Ship with `/mr open current` afterwards.

## skill

Scaffold the canonical paired artifact — both `<config-dir>/.claude/skills/<name>/SKILL.md` and the command twin `<config-dir>/.claude/commands/<name>.md`. Bundle convention; every existing entry is paired.

### Argument

`/author skill <name>[::<sub-op-1>,<sub-op-2>,…]`

| Slot | Required | Shape |
|---|---|---|
| `<name>` | yes | `^[a-z][a-z0-9-]*$` |
| `<sub-op-list>` | no | comma-separated kebab tokens; present → routed, absent → single-purpose |

### Refusal conditions

- `<name>` missing / non-kebab / equals `command` | `skill` — same as `command` sub-op.
- `<config-dir>/.claude/skills/<name>/` exists → refuse.
- `<config-dir>/.claude/commands/<name>.md` exists → refuse (the twin would overwrite).
- Any sub-op token doesn't match `^[a-z][a-z0-9-]*$` → refuse with the offending token named.
- Two sub-op tokens equal → refuse.
- Any sub-op token equals `command`, `skill`, or `<name>` → refuse.

### What it writes

- `<config-dir>/.claude/skills/<name>/SKILL.md` — frontmatter (`name: <name>` + a routing `description: |` block that carries discovery load), Synopsis code block, per-sub-op `## <sub-op>` sections with when-to-use / argument table / refusal conditions / what-it-writes, closing reminder about not staging.
- `<config-dir>/.claude/commands/<name>.md` — twin sharing body and routing.
- `<config-dir>/.claude/claude-code-guide.md` — add `<name>` to the commands paragraph.
- `<config-dir>/.claude/commands-reference.md` — new top-level section with the per-sub-op table.

Writes files only. Ship with `/mr open current`.

## After authoring

1. Review the four touched files.
2. Run `/mr open current` — stages explicit paths, writes a conventional commit, pushes, opens the MR via `glab`.
3. After the MR merges, run `/setup link` on every machine that should pick up the new skill (idempotent).

Editing existing skills is not in this skill's scope — open the target file directly.
