#!/usr/bin/env bash
# Assert every rule ID used in a skill's Rule Catalog exists in the canonical
# registry (rules/rule-ids.yaml). Catches typos and drift between this repo's
# skills and the shared vocabulary. CI-runnable, no model needed.
#
# Framework/compliance IDs (SOC2-*, CIS-*, HIPAA-*, PCI-*, ISO-*, GDPR-*) are
# allowed without registry entries — they are external control IDs, used directly.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$REPO" <<'PY'
import sys, os, re, glob, yaml

repo = sys.argv[1]
reg_path = f"{repo}/rules/rule-ids.yaml"
with open(reg_path) as f:
    reg = yaml.safe_load(f)

# Flatten {domain: {id: desc}} into a set of canonical IDs.
canonical = set()
for k, v in reg.items():
    if isinstance(v, dict):
        canonical.update(v.keys())
if not canonical:
    print("FAIL: no IDs parsed from rules/rule-ids.yaml")
    sys.exit(1)

# Rule-ID shape: PREFIX(-SEG)+-NNN, e.g. TF-STATE-001, COST-LIVE-RESERVE-001.
id_re = re.compile(r'\b[A-Z][A-Z0-9]+(?:-[A-Z0-9]+)+-[0-9]+\b')
# External framework/control IDs — allowed without a registry entry.
framework_re = re.compile(r'^(SOC2|CIS|HIPAA|PCI|ISO|GDPR|NIST)\b', re.I)

fail = 0
used = set()
for path in sorted(glob.glob(f"{repo}/skills/*/SKILL.md")):
    skill = os.path.basename(os.path.dirname(path))
    text = open(path).read()
    for m in id_re.findall(text):
        used.add(m)
        if m in canonical:
            continue
        if framework_re.match(m):
            continue
        print(f"FAIL [{skill}]: rule ID '{m}' not in rules/rule-ids.yaml")
        fail = 1

# Informational: registry IDs no skill references (not a failure).
unused = sorted(canonical - used)
if unused:
    print(f"note: {len(unused)} registry ID(s) not referenced by any skill: {', '.join(unused)}")

if fail:
    print("check-rule-ids: FAILED")
    sys.exit(1)
print(f"check-rule-ids: all skill rule IDs present in registry ({len(canonical)} canonical, {len(used & canonical)} used).")
PY
