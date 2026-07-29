#!/usr/bin/env bash
# PreToolUse hook for Bash: warn on destructive patterns not covered by deny list.
# Inputs: JSON on stdin with .tool_input.command
# Exit 0: allow. Exit 2: block + stderr shown to Claude.
#
# BE CLEAR ABOUT WHAT THIS IS. It prevents accidents, not attacks. The patterns
# below match command text, and anyone determined enough can phrase a command to
# slip past one: a variable holding the flag, a shell alias, base64, a here-doc
# fed to sh. That is acceptable, because the risk this addresses is a colleague
# (or an agent) running something nobody read, not an adversary with shell
# access. If you need a real boundary rather than a speed bump, use Claude
# Code's `sandbox` setting, which isolates the filesystem and network properly,
# or a deny list in settings.json, which the model cannot argue with.
#
# Adding a pattern is cheap; treating this file as a security control is not.
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
