---
description: author — command|skill. Scaffolds new bare-name slash commands and skills under <config-dir>/.claude/. Writes files only (no stage/commit/MR). Refuses on precondition violations per sub-op.
argument-hint: <command|skill> <name>[::<sub-op-1>,<sub-op-2>,…]
---

Routed authoring skill for the shared bundle's command/skill family. The first argument selects the sub-operation; the remainder is parsed per the matching contract.

`<config-dir>` is the workspace's docs container — the child of the workspace root that carries a `.claude/` folder matching this bundle's shape. Discover it at call time by scanning workspace-root children (usually `docs/`; sometimes `agent-config/`). Never hard-code.

## Synopsis

```
/author command <name>
/author skill   <name>[::<sub-op-1>,<sub-op-2>,…]
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `command` | [`## command`](#command) | Scaffold an unpaired single-file slash command at `commands/<name>.md`, plus reference-doc entries. |
| `skill` | [`## skill`](#skill) | Scaffold the canonical paired artifact — `skills/<name>/SKILL.md` + `commands/<name>.md` — plus reference-doc entries. Optional sub-op list flips the body to a routed layout. |

If the first arg is missing or not one of `command` | `skill`, stop and ask which sub-op — never default.

If the first arg is recognized but the remaining args are missing or malformed, refuse with the offending value named — never auto-fill `<name>`, never invent sub-op tokens, never silently re-use an existing file.

Every sub-op writes files only — none stages, commits, pushes, or opens an MR. Once happy, ship with `/mr open current` (or `touched` for the workspace fan-out).

---

## Authoring rules — these apply to every sub-op

The five workspace-wide rules for bundled authoring. Every file this skill writes must comply, and every refusal condition below traces back to one of these.

1. **Positional arguments only.** No `--foo=bar`, no `--name value`, no `-x` shorthand. The `<name>` and sub-op-list slots are positional, separated by `::`. If a sub-op needs many inputs, encode them as `<a>::<b>::<c>` — not flags.

2. **All argument values must be globally unique across every position.** Every positional slot's legal value set must be disjoint from every other slot's. Any token's position must be inferable from its value alone. This skill therefore refuses to author a thing named `command` or `skill`, refuses sub-op tokens equal to `command` | `skill`, and refuses a sub-op token that equals the `<name>` slot.

3. **No defaults for any argument.** If a required argument is missing or unrecognized, stop and ask — never silently fall back. This includes the first-arg sub-op selector, the `<name>` slot, and (when the user asks for a routed skill) the sub-op list.

4. **Use `|` for alternation, not `or` / `vs` / `/`.** In every scaffolded file's argument shapes, prose, error messages, and legal-value lists: `<command|skill>`, `<touched|all>`, `kafka | verb | migration`. Never `command or skill`, `command vs skill`, `command/skill`.

5. **Propagate to both reference docs on every authoring run.** Every add must update both:
   - `<config-dir>/.claude/claude-code-guide.md` — listed alongside the existing bundled entries in the Commands reference paragraph and (for routed skills) under the naming standard.
   - `<config-dir>/.claude/commands-reference.md` — a new top-level section with the per-sub-op table mirroring the in-skill body.

   Skipping either update is incomplete authoring; refuse to call the scaffold "done" until both are touched.

## Naming standard the scaffold enforces

- **Bare kebab-case name — no prefix added.** The user supplies the final `<name>` verbatim; the skill writes files at exactly that path. The shared bundle uses no prefix (`workspace`, `mr`, `docs`, …); if a specific workspace later needs its own prefix (`hp-` / `sd-` / project-slug-based), that workspace's install step can rename or symlink under the prefix — it is not the scaffold's concern.
- **Domain matches** `^[a-z][a-z0-9-]*$`. One word preferred (`workspace` / `mr` / `docs` / `implement` / `scaffold` / `setup` / `author` / …); multi-segment allowed (`design-system-init`, `product-init`).
- **Command file and skill folder share the same name.** `commands/<name>.md` and `skills/<name>/SKILL.md`. The `command` sub-op writes only the former; the `skill` sub-op writes both.
- **First positional of the new thing is its sub-op** (when routed). Sub-ops live inside the new skill as `## <sub-op>` sections, not as separate files.
- **Entity-shaped args use `::` as separator.** The scaffolded `argument-hint:` mirrors the grammar exactly — what the user sees in the `/` picker.

The shared bundle runs eight routed top-level commands; new behavior lands as a sub-op under one of them rather than as a new top-level. If the bundle's existing taxonomy already covers the new behavior (the new thing would fit cleanly as a sub-op under `workspace` / `mr` / `docs` / `implement` / `setup` / `author` / `audit` / `uiux`), warn the user once and ask whether to extend an existing routed skill instead. Only add a new top-level when it genuinely cannot fit.

---

## command

Scaffold an **unpaired single-file slash command** at `<config-dir>/.claude/commands/<name>.md`. Use this for one-off macros that don't warrant the agent-routing surface of a skill — e.g. a fixed-recipe command the user explicitly types and never wants the agent to auto-discover.

Note: the bundle convention is to **pair** every entry. Reach for `skill` unless the user has explicitly said "command only, no skill twin".

### Argument

`/author command <name>`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `<name>` | yes | kebab-case, `^[a-z][a-z0-9-]*$` | Final bare name — used verbatim as the target filename. No prefix added. |

### Refusal conditions

Refuse, with the offending value named, if:

- `<name>` is missing → ask.
- `<name>` does not match `^[a-z][a-z0-9-]*$` → explain kebab-case requirement; ask.
- `<name>` equals `command` or `skill` → explain uniqueness rule; ask for a different domain.
- `<config-dir>/.claude/commands/<name>.md` already exists → refuse to overwrite; suggest editing the existing file directly or choosing a new `<name>`.

### What it writes

- **`<config-dir>/.claude/commands/<name>.md`** — slash-command file with:
  - Frontmatter: `description: <name> — <one-line user-facing summary>.` and `argument-hint: <args per the user's stated purpose>` (left as a `<TODO>` token for the user to fill in).
  - Body: short title, "Synopsis" code block with the `/<name> <args>` invocation, and an "Authoring rules" reminder for the future maintainer that defaults are forbidden.

- **`<config-dir>/.claude/claude-code-guide.md`** — add `<name>` to the per-command list paragraph alongside `workspace` / `mr` / `docs` / `implement` / `setup` / `author` / `audit` / `uiux` / existing entries.

- **`<config-dir>/.claude/commands-reference.md`** — append a new section `## <category — one-line>` (or merge into an existing category section if the new command belongs there) with a one-row table:

  ```markdown
  [`/<name>`](commands/<name>.md) — `<argument-hint>`

  | Sub-op | Argument | What it does |
  |---|---|---|
  | _(none)_ | `<argument-hint>` | <one-liner> |
  ```

Writes files only — does NOT stage, commit, push, or open an MR.

---

## skill

Scaffold the **canonical paired artifact** — both `<config-dir>/.claude/skills/<name>/SKILL.md` and its command twin `<config-dir>/.claude/commands/<name>.md`. This is the bundle's standard authoring path: every existing entry is paired and shares the same body and routing between the two files.

Decide up front whether the new skill is **routed** (multiple sub-ops, first-arg sub-op selector) or **single-purpose** (one entrypoint, no router). The user signals the choice via the presence or absence of the trailing sub-op list.

### Argument

`/author skill <name>[::<sub-op-1>,<sub-op-2>,…]`

| Slot | Required | Shape | Notes |
|---|---|---|---|
| `<name>` | yes | kebab-case, `^[a-z][a-z0-9-]*$` | Final bare name — used verbatim as the target filename. No prefix added. |
| `<sub-op-list>` | no | comma-separated kebab-case tokens | When present → routed skill. When absent → single-purpose skill. |

### Refusal conditions

Refuse, with the offending value named, if:

- `<name>` is missing → ask.
- `<name>` does not match `^[a-z][a-z0-9-]*$` → explain kebab-case requirement; ask.
- `<name>` equals `command` or `skill` → explain uniqueness rule (rule 2); ask for a different domain.
- `<config-dir>/.claude/skills/<name>/` already exists → refuse; suggest editing the existing skill directly.
- `<config-dir>/.claude/commands/<name>.md` already exists → refuse; the twin would overwrite an existing command.
- Any sub-op token does not match `^[a-z][a-z0-9-]*$` → refuse with the offending token named.
- Two sub-op tokens in the list are equal → refuse with the duplicate named (rule 2 prevents same-list collision).
- Any sub-op token equals `command`, `skill`, or `<name>` → refuse with the offending token named (rule 2 — global uniqueness across the argument grammar).

### What it writes

- **`<config-dir>/.claude/skills/<name>/SKILL.md`** — skill body with:
  - Frontmatter `name: <name>` and a routing `description: |` block that opens with the sub-op list (when routed) or a single-purpose summary (when not), and enumerates "Use when the user asks to …" phrasing for each. The description carries discovery load — written for the model, not for humans.
  - Synopsis code block mirroring the `argument-hint:` exactly.
  - Per-sub-op `## <sub-op>` sections, each with: when-to-use, argument table, refusal conditions, "what it writes" list.
  - Closing reminder: writes files only — never stages, commits, pushes, or opens an MR; ship with `/mr open current`.

- **`<config-dir>/.claude/commands/<name>.md`** — command twin sharing the same body and routing, with:
  - Frontmatter `description: <name> — <sub-op1>|<sub-op2>… <one-line user-facing summary>.` and `argument-hint:` mirroring the synopsis.
  - Body: same synopsis block, an at-a-glance table linking each sub-op to its anchor (`#<sub-op>`), and the same per-sub-op sections as the skill.

- **`<config-dir>/.claude/claude-code-guide.md`** — add `<name>` to the per-command list paragraph in the Commands reference section.

- **`<config-dir>/.claude/commands-reference.md`** — append a new top-level section `## <category — one-line>` with the per-sub-op table:

  ```markdown
  [`/<name>`](commands/<name>.md) — `<sub-op-list-or-single> <args per sub-op>`

  | Sub-op | Argument | What it does |
  |---|---|---|
  | `<sub-op-1>` | `<argument-hint>` | <one-liner> |
  | `<sub-op-2>` | `<argument-hint>` | <one-liner> |
  ```

  For single-purpose skills the table has one `_(none)_` row.

Writes files only — does NOT stage, commit, push, or open an MR.

---

## After authoring

The skill writes files only. To ship them:

1. From inside the worktree the user is editing in (typically `tmp/worktrees/<short-name>` off the docs container's default branch), review the four touched files (`SKILL.md`, command twin, `claude-code-guide.md`, `commands-reference.md`).
2. Run `/mr open current` — stages explicit paths, writes a conventional commit, pushes, opens the MR via `glab`.
3. After the MR merges, run `/setup link` once on every machine that should pick up the new skill (idempotent — already-correct links are skipped).

Editing existing skills is **not** in this skill's scope. Open the target file directly; reach for this skill only when scaffolding a brand-new `<name>`.

Cross-references: `/mr` for the staging/commit/push/MR flow, `/setup` for re-linking after the merge.
