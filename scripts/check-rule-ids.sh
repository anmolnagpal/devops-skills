#!/usr/bin/env bash
# Assert every rule ID used in a skill's Rule Catalog exists in the canonical
# registry (rules/rule-ids.yaml). Catches typos and drift between this repo's
# skills and the shared vocabulary. CI-runnable, no model needed.
#
# Framework/compliance IDs (SOC2-*, CIS-*, HIPAA-*, PCI-*, ISO-*, GDPR-*) are
# allowed without registry entries — they are external control IDs, used directly.
#
# The reverse direction is also enforced: a registry ID that no skill emits must
# be declared under `_unemitted` in the registry, as either `reserved` (not
# implementable from files) or `planned` (implementable, names the owning skill).
# This used to be a silent note, which let dead vocabulary accumulate: a registry
# entry with no skill behind it reads as coverage and is not.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$REPO" <<'PY'
import sys, os, re, glob, yaml

repo = sys.argv[1]
reg_path = f"{repo}/rules/rule-ids.yaml"
with open(reg_path) as f:
    reg = yaml.safe_load(f)

# Flatten {domain: {id: desc}} into a set of canonical IDs. Keys starting with
# an underscore are metadata, not domains.
canonical = set()
for k, v in reg.items():
    if k.startswith("_"):
        continue
    if isinstance(v, dict):
        canonical.update(v.keys())

unemitted = reg.get("_unemitted") or {}
reserved = unemitted.get("reserved") or {}
planned = unemitted.get("planned") or {}
declared = {}
for bucket, entries in (("reserved", reserved), ("planned", planned)):
    for rid, reason in (entries or {}).items():
        declared[rid] = (bucket, reason)
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

# Every unused ID must be declared, with a reason.
unused = sorted(canonical - used)
for rid in unused:
    if rid not in declared:
        print(f"FAIL: registry ID '{rid}' is emitted by no skill and not declared "
              f"under _unemitted (add it to reserved or planned, with a reason)")
        fail = 1
    elif not str(declared[rid][1]).strip():
        print(f"FAIL: _unemitted entry '{rid}' has no reason")
        fail = 1

# An ID cannot be both emitted and declared unemitted.
for rid in sorted(set(declared) & used & canonical):
    print(f"FAIL: '{rid}' is emitted by a skill but still declared under "
          f"_unemitted.{declared[rid][0]} — remove the declaration")
    fail = 1

# A declaration for an ID that does not exist is stale.
for rid in sorted(set(declared) - canonical):
    print(f"FAIL: _unemitted declares '{rid}', which is not in the registry")
    fail = 1

if fail:
    print("check-rule-ids: FAILED")
    sys.exit(1)
nres = len([r for r in unused if declared.get(r, ("",))[0] == "reserved"])
nplan = len([r for r in unused if declared.get(r, ("",))[0] == "planned"])
print(f"check-rule-ids: {len(canonical)} canonical, {len(used & canonical)} emitted, "
      f"{nres} reserved (not implementable from files), {nplan} planned.")
PY
