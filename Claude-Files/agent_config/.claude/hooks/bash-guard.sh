#!/usr/bin/env bash
# Generic workspace PreToolUse guard for Bash tool calls.
# Enforces workspace-wide hard rules that prose alone cannot guarantee:
#   1. no --no-verify / --no-gpg-sign (hooks and signing must not be bypassed)
#   2. no Co-Authored-By: footers in commit messages
#   3. no bulk staging (git add -A / --all / . / *) — stage explicit paths
#   4. no direct git push to protected branches (main / staging / develop)
#
# Project-specific guards (domain rules, per-service invariants, feature-catalog
# gates) belong in a per-project sibling hook, not here. This file is copied
# verbatim into every workspace via `/setup link`.
#
# Exit codes:
#   0  allow the tool call
#   2  block the tool call; stderr is shown to Claude as the reason

set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

[ -z "$cmd" ] && exit 0

block() {
  printf '%s\n' "$1" >&2
  exit 2
}

# 1. Bypass flags for git hooks / signing.
if printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_-])(--no-verify|--no-gpg-sign)([^[:alnum:]_-]|$)'; then
  block "BLOCKED by bash-guard: --no-verify / --no-gpg-sign is forbidden. Fix the underlying hook or signing failure instead of bypassing it."
fi

# 2. Co-Authored-By: footer in a git commit message.
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit\b' \
  && printf '%s' "$cmd" | grep -qiE 'Co-Authored-By'; then
  block "BLOCKED by bash-guard: Co-Authored-By: footers are forbidden. Strip the footer and try again."
fi

# 3. Bulk staging — stage explicit paths only.
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+add[[:space:]]+(-A\b|--all\b|\.([[:space:]]|$)|\*([[:space:]]|$))'; then
  block "BLOCKED by bash-guard: bulk staging (git add -A / --all / . / *) is forbidden. Stage explicit paths to avoid sweeping in secrets or unrelated diffs."
fi

# 4. Direct push to a protected branch. Every workspace's shipping mainline is
#    `main`; engineering repos also promote `develop -> staging -> main`, so
#    `develop` and `staging` are protected too. Matches the protected name as
#    a standalone refspec token: preceded by space or ':' (so `HEAD:main` and
#    `:main` are caught) and followed by space/EOL (so `feature/main` and
#    `main-page` are NOT caught).
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push\b.*([[:space:]]|:)(main|staging|develop)([[:space:]]|$)'; then
  block "BLOCKED by bash-guard: direct push to a protected branch (main / staging / develop) is forbidden. Open an MR back to the branch instead."
fi

exit 0
