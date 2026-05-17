#!/usr/bin/env bash
# PreToolUse hook for Bash: warn on destructive patterns not covered by deny list.
# Inputs: JSON on stdin with .tool_input.command
# Exit 0: allow. Exit 2: block + stderr shown to Claude.
set -eu

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("command",""))')"

if [ -z "$cmd" ]; then
  exit 0
fi

# Patterns that warrant a block + confirmation prompt.
patterns=(
  'git +push +.*--force(-with-lease)?( |$)'
  'git +push +.*-f( |$)'
  'git +reset +--hard'
  'git +clean +-[a-z]*f'
  'git +branch +-D'
  'DROP +TABLE'
  'DROP +DATABASE'
  'TRUNCATE +TABLE'
  'aws +iam +delete-'
  'aws +rds +delete-db-'
  'aws +ec2 +terminate-instances'
)

for pat in "${patterns[@]}"; do
  if printf '%s' "$cmd" | grep -Eiq "$pat"; then
    printf 'devops-skills bash-guard: destructive pattern matched (%s) in command: %s\n' "$pat" "$cmd" >&2
    printf 'Confirm with the user before running. If approved, request the user re-issue without the guard.\n' >&2
    exit 2
  fi
done

exit 0
