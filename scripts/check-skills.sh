#!/usr/bin/env bash
# Lint every skill source. Catches a broken skill before it ships in the plugin.
#
# Asserts, for each skills/<name>/SKILL.md:
#   1. Has valid YAML frontmatter (--- ... ---).
#   2. frontmatter `name` is present and equals the directory name
#      (the plugin and generators key skills by directory).
#   3. frontmatter `description` is present and non-empty (it's the trigger text).
#
# CI-runnable, no model needed. Exit non-zero on any failure.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$REPO" <<'PY'
import sys, os, re, glob, yaml

repo = sys.argv[1]
skills = sorted(glob.glob(f"{repo}/skills/*/SKILL.md"))
if not skills:
    print("FAIL: no skills found under skills/*/SKILL.md")
    sys.exit(1)

fail = 0
for path in skills:
    d = os.path.basename(os.path.dirname(path))
    text = open(path).read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        print(f"FAIL [{d}]: missing YAML frontmatter")
        fail = 1
        continue
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError as e:
        print(f"FAIL [{d}]: invalid frontmatter YAML: {e}")
        fail = 1
        continue

    name = fm.get("name")
    if not name:
        print(f"FAIL [{d}]: frontmatter missing 'name'")
        fail = 1
    elif name != d:
        print(f"FAIL [{d}]: name '{name}' does not match directory '{d}'")
        fail = 1

    if not (fm.get("description") or "").strip():
        print(f"FAIL [{d}]: frontmatter missing non-empty 'description'")
        fail = 1

if fail:
    print("check-skills: FAILED")
    sys.exit(1)
print(f"check-skills: all {len(skills)} skill(s) valid.")
PY
