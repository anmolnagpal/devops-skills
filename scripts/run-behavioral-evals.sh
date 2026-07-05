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
# (recall). A clean-* case fails if the live output reports ANY of the skill's
# own rule IDs at all (false positive). Extra defensible findings beyond
# expected.txt do not fail a case — see skills/<name>/evals/README.md
# "Two layers of checking".
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

# Same shape used by each skill's evals/validate.sh, but matching is further
# constrained below to IDs the skill's own Rule Catalog actually declares —
# this shape alone also matches unrelated ID-looking tokens (CVE-2024-12345,
# semver-like strings) that could appear in a model's live commentary.
id_re='[A-Z][A-Z0-9]{1,4}-[A-Z0-9]+-[0-9]+'

total=0
passed=0

for skill in "${SKILLS[@]}"; do
  cases_dir="$REPO/skills/$skill/evals/cases"
  [ -d "$cases_dir" ] || { echo "skip [$skill]: no evals/cases/"; continue; }

  skill_md="$REPO/skills/$skill/SKILL.md"
  known="$(grep -oE "$id_re" "$skill_md" | sort -u)"

  for case_dir in "$cases_dir"/*/; do
    name="$(basename "$case_dir")"
    exp="$case_dir/expected.txt"
    [ -f "$exp" ] || continue

    fixtures=()
    while IFS= read -r -d '' f; do fixtures+=("$(basename "$f")"); done \
      < <(find "$case_dir" -maxdepth 1 -type f ! -name 'expected.txt' -print0 | sort -z)
    if [ "${#fixtures[@]}" -eq 0 ]; then
      echo "FAIL [$skill/$name]: no fixture file found"
      total=$((total + 1))
      continue
    fi

    total=$((total + 1))
    echo "=== $skill/$name (${fixtures[*]}) ==="

    # Review every fixture file in the case directory together, the same way
    # a real REVIEW pass reads every relevant file in a directory — avoids
    # guessing which single file is "the" fixture when a case legitimately
    # ships more than one (e.g. Dockerfile + .dockerignore).
    output="$(cd "$case_dir" && claude -p "Use the /clouddrove:$skill skill in review mode on every file in this directory except expected.txt. Print every finding's rule ID, one per line, and nothing else. If there are no findings, print nothing." 2>&1 || true)"

    # Constrain to this skill's own known rule IDs, not any ID-shaped token —
    # a stray CVE-2024-12345 or similar in the model's commentary must not
    # count as a finding.
    found_ids="$(grep -oE "$id_re" <<<"$output" | sort -u | comm -12 - <(echo "$known") || true)"

    case_fail=0

    if [[ "$name" == clean-* ]] && [ -n "$found_ids" ]; then
      echo "FAIL [$skill/$name]: clean case but live output reported: $(tr '\n' ' ' <<<"$found_ids")"
      case_fail=1
    fi

    while IFS= read -r want; do
      [ -z "$want" ] && continue
      if ! grep -qxF "$want" <<<"$found_ids"; then
        echo "FAIL [$skill/$name]: expected '$want' not found in live output"
        case_fail=1
      fi
    done < "$exp"

    [ "$case_fail" -eq 0 ] && passed=$((passed + 1))
  done
done

echo "---"
echo "run-behavioral-evals: $passed/$total case(s) passed."
[ "$passed" -eq "$total" ]
