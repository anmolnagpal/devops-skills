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
#   EVALS=1 bash scripts/run-behavioral-evals.sh --triggers    # trigger phrases instead
#   EVALS=1 bash scripts/run-behavioral-evals.sh --triggers tf
#
# --triggers grades evals/prompts.md rather than the fixtures: does the
# description get this skill selected for the prompts that should load it, and
# left unselected for the ones that should not. It asks the model to route a
# prompt and compares the answer, which is a proxy for real selection rather
# than an observation of it. Good enough to catch a description that stopped
# matching how people phrase things; not proof of what the harness did.
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

# The harness invokes `claude -p`, which loads the *installed* plugin, not this
# working tree. Those can differ, and a green run against a stale install is
# worse than no run: it reports the repo as verified while testing code that is
# not in it. The first real run of this harness hit exactly that, with 1.3.0
# installed against a 1.4.0 tree, which would have silently skipped every skill
# added in 1.4.0 while appearing to pass.
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
want="$(python3 -c "import json;print(json.load(open('$REPO_ROOT/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo '')"
have="$(claude plugin list 2>/dev/null | awk '/clouddrove@devops-skills/{f=1;next} f&&/Version:/{print $2;exit}')"
if [ -z "$have" ]; then
  echo "FAIL: the clouddrove plugin is not installed, so 'claude -p' cannot load any skill." >&2
  echo "      Install it:  claude plugin install clouddrove@devops-skills" >&2
  exit 1
fi
if [ -n "$want" ] && [ "$have" != "$want" ]; then
  echo "FAIL: installed plugin is $have but this tree is $want." >&2
  echo "      Testing a stale install would report results for code that is not here." >&2
  echo "      Update it:  claude plugin marketplace update devops-skills && claude plugin update clouddrove@devops-skills" >&2
  exit 1
fi
# A matching version is necessary but not sufficient. `claude plugin update` is a
# no-op when the version is unchanged, so an edited skill body can sit in the tree
# while the installed copy still serves the old text. That happened during the
# first --triggers run: five descriptions were fixed, the version stayed 1.4.1, the
# update did nothing, and a re-run would have measured the unfixed skills and
# reported the fixes as failures. A version field cannot see this; a content hash
# can.
tree_root="$REPO_ROOT"
inst_root="$(ls -d "$HOME"/.claude/plugins/cache/*/clouddrove/"$have" 2>/dev/null | head -1)"
if [ -z "$inst_root" ] || [ ! -d "$inst_root/skills" ]; then
  echo "harness: plugin $have matches the working tree by version; could not locate the" >&2
  echo "         installed copy on disk to compare content, so proceeding unverified." >&2
else
  hash_of() {
    python3 - "$1" <<'PYEOF'
import hashlib, glob, os, sys
root = sys.argv[1]
h = hashlib.sha256()
paths = sorted(glob.glob(os.path.join(root, 'skills', '*', 'SKILL.md'))
               + glob.glob(os.path.join(root, 'skills', '*', 'references', '*.md'))
               + glob.glob(os.path.join(root, 'skills', '*', '*.md')))
for p in paths:
    h.update(os.path.relpath(p, root).encode())
    h.update(open(p, 'rb').read())
print(h.hexdigest()[:12])
PYEOF
  }
  want_hash="$(hash_of "$tree_root")"
  have_hash="$(hash_of "$inst_root")"
  if [ "$want_hash" != "$have_hash" ]; then
    echo "FAIL: installed plugin is version $have, same as this tree, but its skill" >&2
    echo "      bodies differ (tree $want_hash, installed $have_hash)." >&2
    echo "      'claude plugin update' will not fix this: it compares versions, and they match." >&2
    echo "      Force it:  claude plugin uninstall clouddrove@devops-skills \\" >&2
    echo "                 && claude plugin install clouddrove@devops-skills" >&2
    exit 1
  fi
  echo "harness: plugin $have matches the working tree, content hash $want_hash, skills under test are this repo's."
fi

REPO="$(cd "$(dirname "$0")/.." && pwd)"
MODE=fixtures
REPEAT="${EVAL_REPEAT:-1}"
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --triggers) MODE=triggers ;;
    --fixtures) MODE=fixtures ;;
    --repeat)   REPEAT="${2:?--repeat needs a count}"; shift ;;
    -*) echo "unknown flag: $1" >&2; exit 1 ;;
    *) args+=("$1") ;;
  esac
  shift
done
set -- ${args+"${args[@]}"}

case "$REPEAT" in
  ''|*[!0-9]*) echo "FAIL: --repeat must be a positive integer, got '$REPEAT'" >&2; exit 1 ;;
esac
[ "$REPEAT" -lt 1 ] && { echo "FAIL: --repeat must be at least 1" >&2; exit 1; }

# Model output is non-deterministic, so one run cannot distinguish a flake from a
# regression. --repeat N runs the whole selection N times and reports pass@N per
# pass, which is the number worth tracking over time.
if [ "$REPEAT" -gt 1 ]; then
  echo "harness: running $REPEAT passes for pass@$REPEAT"
  pass_results=()
  overall=0
  for run in $(seq 1 "$REPEAT"); do
    echo
    echo "───────── pass $run of $REPEAT"
    if EVAL_REPEAT=1 bash "$0" ${MODE:+--$MODE} ${args+"${args[@]}"}; then
      pass_results+=("pass $run: all passed")
    else
      pass_results+=("pass $run: FAILURES")
      overall=1
    fi
  done
  echo
  echo "───────── pass@$REPEAT summary"
  printf '  %s
' "${pass_results[@]}"
  [ "$overall" -eq 0 ] && echo "pass@$REPEAT: every pass green." || echo "pass@$REPEAT: at least one pass had failures. A case failing in some passes and not others is a flake; one failing every pass is a regression."
  exit "$overall"
fi

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

if [ "$MODE" = "triggers" ]; then
  all="$(cd "$REPO" && ls -d skills/*/ | sed 's|skills/||; s|/||' | tr '\n' ' ')"
  for skill in "${SKILLS[@]}"; do
    prompts="$REPO/skills/$skill/evals/prompts.md"
    [ -f "$prompts" ] || { echo "skip [$skill]: no evals/prompts.md"; continue; }

    # Extract quoted prompts per section. Positive must route to this skill;
    # negative must route anywhere else (the file records where, for the human).
    while IFS=$'\t' read -r want phrase; do
      [ -z "$phrase" ] && continue
      total=$((total + 1))
      ask="You route requests to skills. Available: $all.
Answer with exactly one skill name from that list, or the single word none.
No explanation.

Request: $phrase"
      # Keep digits: 'k8s' is a real skill name and 'a-z-' silently made it 'ks',
      # which failed five correct answers on the first run of this mode.
      got="$(printf '%s' "$ask" | claude -p 2>/dev/null | tr -d '[:space:]' | tr -cd 'a-z0-9-' || true)"
      if [ "$want" = "yes" ]; then
        if [ "$got" = "$skill" ]; then
          passed=$((passed + 1)); printf '  PASS [%s] loads: %s\n' "$skill" "$phrase"
        else
          printf '  FAIL [%s] should load but routed to "%s": %s\n' "$skill" "$got" "$phrase"
        fi
      else
        if [ "$got" != "$skill" ]; then
          passed=$((passed + 1)); printf '  PASS [%s] declines (went to "%s"): %s\n' "$skill" "$got" "$phrase"
        else
          printf '  FAIL [%s] over-triggered: %s\n' "$skill" "$phrase"
        fi
      fi
    done < <(python3 - "$prompts" <<'PYEOF'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
def section(t):
    m = re.search(rf"^##\s+{t}\s*$(.*?)(?=^##\s|\Z)", text, re.M | re.S)
    return m.group(1) if m else ""
for want, title in (("yes", "Should load"), ("no", "Should not load")):
    for line in re.findall(r'^\s*[-*]\s+(.*)$', section(title), re.M):
        q = re.search(r'"([^"]+)"', line)
        if q:
            print(f"{want}\t{q.group(1)}")
PYEOF
)
  done

  echo
  echo "triggers: $passed/$total prompt(s) routed as declared."
  [ "$total" -gt 0 ] && [ "$passed" -eq "$total" ] && exit 0
  exit 1
fi

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
