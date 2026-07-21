#!/usr/bin/env bash
# Generic workspace PreToolUse guard for Write and Edit tool calls.
# Enforces workspace-wide hard rules that prose alone cannot guarantee:
#   1. Documents under */docs/ must not refer to the workspace's derived-artifact
#      markdown files (CLAUDE.md, README.md) — inline the content instead.
#
# Project-specific write guards (schema invariants like "no body_html in a
# content service", locale rules like "no Persian digits in machine feeds",
# scope gates like "no money columns in v1") belong in a per-project sibling
# hook that layers on top of this one. This file is copied verbatim into every
# workspace via `/setup link`.
#
# Exit codes:
#   0  allow the tool call
#   2  block the tool call; stderr is shown to Claude as the reason

set -euo pipefail

input=$(cat)
tool=$(printf '%s' "$input"  | jq -r '.tool_name // empty')
path=$(printf '%s' "$input"  | jq -r '.tool_input.file_path // empty')
new_text=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

[ -z "$path" ] && exit 0

block() {
  printf '%s\n' "$1" >&2
  exit 2
}

base=${path##*/}

# Predicate — "this is a document markdown file".
is_document_md() {
  case "$path" in
    *.md) ;;
    *) return 1 ;;
  esac
  case "$path" in
    */.claude/*) return 1 ;;       # agent config, not a document
  esac
  case "$base" in
    CLAUDE.md|README.md) return 1 ;;  # derived artifacts may reference themselves
  esac
  case "$path" in
    */docs/*) return 0 ;;          # any repo's docs/ tree
  esac
  return 1
}

# Rule 1 — derived-artifact citation guard.
if is_document_md \
   && printf '%s' "$new_text" | grep -qE '(^|[^[:alnum:]_/])(CLAUDE|README)\.md([^[:alnum:]_]|$)'; then
  block "BLOCKED by write-edit-guard: documents must not refer to the workspace's derived-artifact markdown files (CLAUDE.md, README.md). Inline the relevant content instead."
fi

exit 0
