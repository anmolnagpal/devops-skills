#!/usr/bin/env bash
# Assert every skill ships trigger-phrase evals, and that they are shaped to be
# useful rather than decorative.
#
# The fixture evals (check-evals.sh) prove a skill's *rules* fire correctly on a
# file. Nothing proved the skill gets *loaded* in the first place. A skill's
# description is the only text the model reads when deciding, so a weak
# description means a perfect rule catalog that never runs, and no other gate in
# this repo notices.
#
# Each skill declares that contract in skills/<name>/evals/prompts.md:
#   ## Should load        prompts that MUST select this skill
#   ## Should not load    prompts that must select something else, or nothing
#
# The second list is what stops overlapping skills fighting: tf against
# wrapper-tf, appsec against owasp, observability against incident.
#
# This is the Tier-1 static half (free, always-on): the file exists, has enough
# prompts, and the negative prompts name where they should go instead. Actually
# running them is Tier-2, see scripts/run-behavioral-evals.sh.
#
# CI-runnable, no model needed. Exit non-zero on any failure.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$REPO" <<'PY'
import glob, os, re, sys

repo = sys.argv[1]
MIN_POSITIVE = 4
MIN_NEGATIVE = 1

# Skills whose scope deliberately overlaps another's. These must carry negative
# prompts, because "which of these two fires" is a real decision the model makes
# and getting it wrong sends the user a confidently wrong review.
OVERLAPPING = {
    "tf": "wrapper-tf",
    "wrapper-tf": "tf",
    "tf-plan": "tf",
    "appsec": "owasp",
    "owasp": "appsec",
    "observability": "incident",
    "incident": "observability",
    "ci": "github-actions",
    "github-actions": "ci",
    "gitops": "k8s",
    "deploy": "k8s",
}

fail = 0
def bad(msg):
    global fail
    print(f"FAIL: {msg}")
    fail = 1

skills = sorted(glob.glob(f"{repo}/skills/*/SKILL.md"))
checked = 0

for path in skills:
    name = os.path.basename(os.path.dirname(path))
    p = f"{repo}/skills/{name}/evals/prompts.md"

    if not os.path.exists(p):
        bad(f"[{name}] missing evals/prompts.md "
            f"(copy templates/skill/evals/prompts.md)")
        continue

    text = open(p, encoding="utf-8").read()
    checked += 1

    def section(title):
        m = re.search(rf"^##\s+{title}\s*$(.*?)(?=^##\s|\Z)", text, re.M | re.S)
        return m.group(1) if m else None

    pos = section("Should load")
    neg = section("Should not load")

    if pos is None:
        bad(f"[{name}] prompts.md has no '## Should load' section")
        continue
    if neg is None:
        bad(f"[{name}] prompts.md has no '## Should not load' section")
        continue

    # Prompts are list items carrying a quoted phrase.
    def prompts(block):
        return [l for l in re.findall(r'^\s*[-*]\s+(.*)$', block, re.M)
                if '"' in l or "'" in l or '`' in l]

    npos, nneg = len(prompts(pos)), len(prompts(neg))

    if npos < MIN_POSITIVE:
        bad(f"[{name}] only {npos} 'Should load' prompt(s), need {MIN_POSITIVE}. "
            f"Each must be a quoted phrase someone would actually type.")

    need_neg = MIN_NEGATIVE if name in OVERLAPPING else 0
    if nneg < need_neg:
        bad(f"[{name}] {nneg} 'Should not load' prompt(s), need {need_neg}: "
            f"its scope overlaps {OVERLAPPING[name]}, so the boundary needs pinning")

    # A phrase cannot be in both lists. It fails one way or the other no matter
    # what the model does, so the suite can never go green and the failure looks
    # like a skill defect. This happened during the first --triggers run: a
    # deletion missed by three words and left "review my infra" in both of tf's
    # sections, costing a real debugging detour.
    def quoted(block):
        return {q for line in prompts(block)
                for q in re.findall(r'"([^"]+)"', line)}
    both = quoted(pos) & quoted(neg)
    for phrase in sorted(both):
        bad(f"[{name}] \"{phrase}\" is in both 'Should load' and 'Should not load'. "
            f"It fails whichever way the model answers; pick one.")

    # A negative prompt has to say where it should go instead, otherwise a
    # failure tells you nothing about what went wrong.
    for line in prompts(neg):
        if '→' not in line and '->' not in line:
            bad(f"[{name}] negative prompt lacks a '→ <where it should go>': {line[:60]}")

if not skills:
    bad("no skills found under skills/*/SKILL.md")

if fail:
    print("check-prompts: FAILED")
    sys.exit(1)
print(f"check-prompts: all {checked} skill(s) have usable trigger-phrase evals.")
PY
