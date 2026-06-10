#!/usr/bin/env bash
# Generate per-tool adapter artifacts from canonical skills/*.md sources.
#
#   skills/<name>.md  →
#     .cursor/rules/<name>.mdc     (Cursor)
#     AGENTS.md                    (Codex — single concatenated file)
#
# Re-run after editing any skill. Outputs are committed and consumed by
# install-cursor.sh / install-codex.sh.

set -euo pipefail

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO/skills"
CURSOR_DIR="$REPO/.cursor/rules"
mkdir -p "$CURSOR_DIR"

echo "generate: cursor + codex artifacts from $SRC_DIR"

export REPO
python3 - <<'PY'
import os, re, sys, glob, yaml, pathlib

REPO   = os.environ.get("REPO") or pathlib.Path(__file__).resolve().parent.parent.as_posix()
SRC    = f"{REPO}/skills"
CURSOR = f"{REPO}/.cursor/rules"
AGENTS = f"{REPO}/AGENTS.md"

def parse(path):
    text = open(path).read()
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return None, text
    fm = yaml.safe_load(m.group(1)) or {}
    body = m.group(2).lstrip()
    return fm, body

def cursor_mdc(name, fm, body):
    desc  = (fm.get("description") or "").strip().strip('"')
    paths = fm.get("paths") or []
    globs = ", ".join(paths) if paths else ""
    always = "false" if paths else "true"
    head = ["---", f"description: {desc}"]
    if globs:
        head.append(f"globs: {globs}")
    head += [f"alwaysApply: {always}", "---", ""]
    return "\n".join(head) + body

def agents_section(name, fm, body):
    desc  = (fm.get("description") or "").strip().strip('"')
    paths = fm.get("paths") or []
    glob_line = f"  - **Auto-load for**: `{'`, `'.join(paths)}`\n" if paths else ""
    return (
        f"## /{name}\n\n"
        f"  - **Use when**: {desc}\n"
        f"{glob_line}\n"
        f"{body}\n"
    )

agents_parts = [
    "# AGENTS.md\n",
    "Generated from skills/*.md by scripts/generate.sh. Edit sources, not this file.\n",
    "Codex (and other AGENTS-aware tools) read this file for skill guidance.\n",
]

count = 0
for path in sorted(glob.glob(f"{SRC}/*.md")):
    name = os.path.splitext(os.path.basename(path))[0]
    fm, body = parse(path)
    if fm is None:
        print(f"  skip: {name} (no frontmatter)")
        continue
    mdc = f"{CURSOR}/{name}.mdc"
    open(mdc, "w").write(cursor_mdc(name, fm, body))
    print(f"  cursor: {mdc}")
    agents_parts.append(agents_section(name, fm, body))
    count += 1

open(AGENTS, "w").write("\n".join(agents_parts))
print(f"  codex:  {AGENTS}")
print(f"  total:  {count} skill(s)")
PY

if [ "$CHECK" -eq 1 ]; then
  # Fail if committed adapters are stale relative to skills/*.md sources.
  if ! git -C "$REPO" diff --quiet -- .cursor/rules AGENTS.md; then
    echo "ERROR: generated adapters are out of date. Run scripts/generate.sh and commit:" >&2
    git -C "$REPO" --no-pager diff --stat -- .cursor/rules AGENTS.md >&2
    exit 1
  fi
  echo "check: adapters up to date."
fi

echo "done."
