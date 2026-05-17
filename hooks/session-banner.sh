#!/usr/bin/env bash
# SessionStart hook: print DevOps context banner.
# Inputs: hook event JSON on stdin (ignored).
# Output: additionalContext lines shown to Claude at session start.
set -eu

branch=""
repo=""
if git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$PWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  repo="$(basename "$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")"
fi

aws_profile="${AWS_PROFILE:-default}"
kube_ctx=""
if command -v kubectl >/dev/null 2>&1; then
  kube_ctx="$(kubectl config current-context 2>/dev/null || true)"
fi

printf 'DevOps context: repo=%s branch=%s aws_profile=%s%s\n' \
  "${repo:-<none>}" "${branch:-<none>}" "$aws_profile" \
  "${kube_ctx:+ kube_ctx=$kube_ctx}"
