#!/usr/bin/env bash
# Tier-2 behavioral eval: actually invokes each skill against its fixtures via
# `claude -p` and diffs the live output against expected.txt, instead of only
# checking that the eval docs are internally consistent (that's check-evals.sh /
# each skill's evals/validate.sh — Tier-1, free, always-on).
#
# This is opt-in and NOT wired into the six CI gates: it spends real API tokens
# (one `claude -p` call per eval case) and model output is non-deterministic, so
# it belongs in a manual/nightly run, not on every push.
#
# Usage:
#   EVALS=1 bash scripts/run-behavioral-evals.sh              # all skills with evals/
#   EVALS=1 bash scripts/run-behavioral-evals.sh tf k8s        # just these skills
#
# Gate: every rule ID in a case's expected.txt must appear in the live output
# (recall). A clean-* case fails if the live output reports ANY rule ID at all
# (false positive). Extra defensible findings beyond expected.txt do not fail
# a case — see skills/<name>/evals/README.md "Two layers of checking".
set -euo pipefail

if [ "${EVALS:-0}" != "1" ]; then
  echo "skip: set EVALS=1 to run behavioral evals (spends API tokens via 'claude -p')"
  exit 0
fi

command -v claude >/dev/null 2>&1 || { echo "FAIL: 'claude' CLI not found on PATH"; exit 1; }

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS=("$@")
if [ "${#SKILLS[@]}" -eq 0 ]; then
  SKILLS=()
  for d in "$REPO"/skills/*/evals; do
    [ -d "$d" ] || continue
    SKILLS+=("$(basename "$(dirname "$d")")")
  done
fi

id_re='[A-Z][A-Z0-9]{1,4}-[A-Z0-9]+-[0-9]+'
fail=0
total=0
passed=0

for skill in "${SKILLS[@]}"; do
  cases_dir="$REPO/skills/$skill/evals/cases"
  [ -d "$cases_dir" ] || { echo "skip [$skill]: no evals/cases/"; continue; }

  for case_dir in "$cases_dir"/*/; do
    name="$(basename "$case_dir")"
    exp="$case_dir/expected.txt"
    [ -f "$exp" ] || continue

    fixture="$(find "$case_dir" -maxdepth 1 -type f ! -name 'expected.txt' | head -1)"
    [ -n "$fixture" ] || { echo "FAIL [$skill/$name]: no fixture file found"; fail=1; continue; }

    total=$((total + 1))
    echo "=== $skill/$name ($(basename "$fixture")) ==="

    output="$(cd "$case_dir" && claude -p "Use the /clouddrove:$skill skill in review mode on $(basename "$fixture"). Print every finding's rule ID, one per line, and nothing else. If there are no findings, print nothing." 2>&1 || true)"
    found_ids="$(grep -oE "$id_re" <<<"$output" | sort -u || true)"

    case_fail=0

    if [[ "$name" == clean-* ]]; then
      if [ -n "$found_ids" ]; then
        echo "FAIL [$skill/$name]: clean case but live output reported: $(tr '\n' ' ' <<<"$found_ids")"
        case_fail=1
      fi
    fi

    while IFS= read -r want; do
      [ -z "$want" ] && continue
      if ! grep -qxF "$want" <<<"$found_ids"; then
        echo "FAIL [$skill/$name]: expected '$want' not found in live output"
        case_fail=1
      fi
    done < "$exp"

    if [ "$case_fail" -eq 0 ]; then
      passed=$((passed + 1))
    else
      fail=1
    fi
  done
done

echo "---"
echo "run-behavioral-evals: $passed/$total case(s) passed."
exit $fail
