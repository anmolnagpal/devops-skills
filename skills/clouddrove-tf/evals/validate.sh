#!/usr/bin/env bash
# Static eval validation for a review skill — CI-runnable, no model needed.
# Generic: derives the skill from its own path, so this file is identical across
# skills/<name>/evals/. Copy it verbatim when adding evals to a new skill.
#
# Asserts:
#   1. Every rule ID in any expected.txt exists in the skill's Rule Catalog
#      (skills/<name>.md). Catches typos and catalog drift.
#   2. Every `clean-*` case has an empty expected.txt.
#   3. Every case directory has an expected.txt.
#
# Exit non-zero on any failure. Wire into CI.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill="$(basename "$(dirname "$here")")"        # skills/<skill>/evals → <skill>
skill_md="$here/../../$skill.md"
cases_dir="$here/cases"
id_re='[A-Z][A-Z0-9]{1,4}-[A-Z0-9]+-[0-9]+'     # SEC-SEC-001, CICD-DOCK-004, COST-K8S-003

[ -f "$skill_md" ] || { echo "FAIL: cannot find skill at $skill_md"; exit 1; }
[ -d "$cases_dir" ] || { echo "FAIL: no cases dir at $cases_dir"; exit 1; }

# Extract known rule IDs from the catalog.
known="$(grep -oE "$id_re" "$skill_md" | sort -u)"
[ -n "$known" ] || { echo "FAIL: no rule IDs found in $skill_md"; exit 1; }

fail=0
note() { echo "FAIL: $1"; fail=1; }
is_known() { grep -qxF "$1" <<<"$known"; }

for case_dir in "$cases_dir"/*/; do
  name="$(basename "$case_dir")"
  exp="$case_dir/expected.txt"

  if [ ! -f "$exp" ]; then
    note "$name: missing expected.txt"
    continue
  fi
  if [[ "$name" == clean-* ]] && [ -s "$exp" ]; then
    note "$name: clean case must have an empty expected.txt"
  fi
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    is_known "$id" || note "$name: unknown rule ID '$id' (not in catalog)"
  done < "$exp"
done

if [ "$fail" -ne 0 ]; then
  echo "---"
  echo "Known $skill rule IDs:"
  echo "$known" | sed 's/^/  /'
  exit 1
fi

ncases="$(find "$cases_dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
nrules="$(echo "$known" | wc -l | tr -d ' ')"
echo "OK [$skill]: $ncases case(s) valid against $nrules catalog rule(s)."
