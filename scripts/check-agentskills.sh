#!/usr/bin/env bash
# Assert every skill conforms to the agentskills.io open Agent Skills standard,
# so the repo can be listed on https://agentskills.io without surprises.
#
# The standard requires only `name` and `description`; scripts/agentskills-skill.schema.json
# carries the full schema. This script enforces it plus the two constraints JSON
# Schema can't express:
#   name  : 1-64 chars, lowercase-kebab (^[a-z0-9]+(-[a-z0-9]+)*$), == parent dir,
#           and free of reserved vendor words (anthropic, claude).
#   description : present, 1-1024 chars (agentskills.io caps listings at 1024).
#   no angle brackets ('<' or '>') in any frontmatter string value (injection risk).
#
# Extra top-level keys (this repo's safety/paths/frameworks) are PERMITTED by the
# standard and are not failures. CI-runnable, no model needed. Exit non-zero on any
# violation.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$REPO" <<'PY'
import sys, os, re, glob, yaml

repo = sys.argv[1]
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
RESERVED = ("anthropic", "claude")
MAX_DESC = 1024
MAX_NAME = 64

def frontmatter(path):
    text = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    return yaml.safe_load(m.group(1)) or {}

def has_angle(v):
    if isinstance(v, str):
        return "<" in v or ">" in v
    if isinstance(v, dict):
        return any(has_angle(x) for x in v.values())
    if isinstance(v, list):
        return any(has_angle(x) for x in v)
    return False

skills = sorted(glob.glob(f"{repo}/skills/*/SKILL.md"))
if not skills:
    print("FAIL: no skills found under skills/*/SKILL.md")
    sys.exit(1)

fail = 0
for path in skills:
    d = os.path.basename(os.path.dirname(path))
    fm = frontmatter(path)
    if fm is None:
        print(f"FAIL [{d}]: missing YAML frontmatter")
        fail = 1
        continue

    name = str(fm.get("name", "") or "")
    if not name:
        print(f"FAIL [{d}]: missing required key 'name'")
        fail = 1
    else:
        if not NAME_RE.match(name):
            print(f"FAIL [{d}]: name '{name}' is not lowercase-kebab-case")
            fail = 1
        if len(name) > MAX_NAME:
            print(f"FAIL [{d}]: name '{name}' is {len(name)} chars (>{MAX_NAME})")
            fail = 1
        if name != d:
            print(f"FAIL [{d}]: name '{name}' does not match directory '{d}'")
            fail = 1
        for word in RESERVED:
            if word in name.lower():
                print(f"FAIL [{d}]: name '{name}' contains reserved vendor word '{word}'")
                fail = 1

    desc = " ".join(str(fm.get("description", "") or "").split())
    if not desc:
        print(f"FAIL [{d}]: missing or empty required key 'description'")
        fail = 1
    elif len(desc) > MAX_DESC:
        print(f"FAIL [{d}]: description is {len(desc)} chars (>{MAX_DESC})")
        fail = 1

    for key, value in fm.items():
        if has_angle(value):
            print(f"FAIL [{d}]: frontmatter value for '{key}' contains angle brackets "
                  "(injection risk, not allowed by the standard)")
            fail = 1
            break

if fail:
    print("check-agentskills: FAILED")
    sys.exit(1)
print(f"check-agentskills: all {len(skills)} skill(s) conform to the agentskills.io standard.")
PY
