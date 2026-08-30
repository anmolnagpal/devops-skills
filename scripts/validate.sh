#!/usr/bin/env bash
# Run every free check, in the order CI runs them. One command instead of five,
# so "did I break anything" has a single answer.
#
#   bash scripts/validate.sh
#
# FAIL blocks. WARN is advice. Do not work around a failing check: fix the
# content, or change the check in its own pull request.
#
# Not included: the Docker install harness (_test/test.sh, needs Docker) and the
# Tier-2 behavioral evals (scripts/run-behavioral-evals.sh, spends API tokens).
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1

CHECKS=(
  "check-skills.sh:skill frontmatter, name/description/safety"
  "check-versions.sh:plugin.json, marketplace.json, and CHANGELOG agree"
  "check-rule-ids.sh:every rule ID exists in the canonical registry"
  "check-evals.sh:fixture evals match each skill's Rule Catalog"
  "check-prompts.sh:trigger-phrase evals exist and pin the boundaries"
  "check-agentskills.sh:every skill conforms to the agentskills.io standard"
)

failed=()
for entry in "${CHECKS[@]}"; do
  script="${entry%%:*}"
  desc="${entry#*:}"
  printf '\n\033[1m── %s\033[0m  (%s)\n' "$script" "$desc"
  if bash "scripts/$script"; then
    :
  else
    failed+=("$script")
  fi
done

printf '\n\033[1m── generate.sh --check\033[0m  (Cursor + Codex adapters up to date)\n'
if ! bash scripts/generate.sh --check; then
  failed+=("generate.sh --check")
fi

echo
if [ ${#failed[@]} -eq 0 ]; then
  echo "validate: all checks passed."
  exit 0
fi
echo "validate: FAILED — ${#failed[@]} check(s): ${failed[*]}"
exit 1
