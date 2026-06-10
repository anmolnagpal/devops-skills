#!/usr/bin/env bash
# Run static eval validation for every skill that ships an evals/ folder.
# Each skill's validate.sh checks its eval fixtures against its Rule Catalog.
# CI-runnable, no model invocation. Exit non-zero if any skill fails.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

mapfile -t validators < <(find "$REPO/skills" -path '*/evals/validate.sh' | sort)

if [ "${#validators[@]}" -eq 0 ]; then
  echo "check-evals: no skill evals found."
  exit 0
fi

fail=0
for v in "${validators[@]}"; do
  bash "$v" || fail=1
done

if [ "$fail" -ne 0 ]; then
  echo "check-evals: FAILED"
  exit 1
fi
echo "check-evals: all ${#validators[@]} skill eval suite(s) passed."
