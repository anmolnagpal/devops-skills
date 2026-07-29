#!/usr/bin/env bash
# Assert the places that carry a version agree with each other.
#
# This repo declares its version in three places and they drift silently:
#   .claude-plugin/plugin.json       what Claude Code installs and reports
#   .claude-plugin/marketplace.json  what the marketplace listing advertises
#   CHANGELOG.md                     what a human reads to know what changed
#
# The drift this exists to catch really happened: plugin.json said 1.3.0 while
# no v1.3.0 tag existed, and v1.2.0 was tagged but never released, so the
# release badge showed v1.1.0 for a version two releases old.
#
# FAIL blocks (in-repo files disagree). WARN is advice about tags and releases,
# which depend on fetch depth and on a release having been cut yet.
#
# CI-runnable, no model needed. Exit non-zero on any FAIL.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$REPO" <<'PY'
import json, os, re, subprocess, sys

repo = sys.argv[1]
fail = 0
warn = 0

def bad(msg):
    global fail
    print(f"FAIL: {msg}")
    fail = 1

def note(msg):
    global warn
    print(f"WARN: {msg}")
    warn += 1

SEMVER = re.compile(r"^\d+\.\d+\.\d+$")

# ── plugin.json is the source of truth ────────────────────────────────────────
pj_path = os.path.join(repo, ".claude-plugin", "plugin.json")
try:
    pj = json.load(open(pj_path))
except Exception as e:
    bad(f".claude-plugin/plugin.json unreadable: {e}")
    sys.exit(1)

version = (pj.get("version") or "").strip()
if not version:
    bad("plugin.json has no 'version'")
    sys.exit(1)
if not SEMVER.match(version):
    bad(f"plugin.json version '{version}' is not MAJOR.MINOR.PATCH")

plugin_name = pj.get("name") or ""

# ── marketplace.json must agree, where it says anything ───────────────────────
mp_path = os.path.join(repo, ".claude-plugin", "marketplace.json")
try:
    mp = json.load(open(mp_path))
except Exception as e:
    bad(f".claude-plugin/marketplace.json unreadable: {e}")
    mp = {}

entries = mp.get("plugins") or []
match = [p for p in entries if p.get("name") == plugin_name]
if not match:
    bad(f"marketplace.json lists no plugin named '{plugin_name}' "
        f"(found: {[p.get('name') for p in entries]})")
else:
    entry = match[0]
    mv = (entry.get("version") or "").strip()
    if not mv:
        bad(f"marketplace.json entry for '{plugin_name}' has no 'version'. "
            f"Add \"version\": \"{version}\" so the two files cannot drift.")
    elif mv != version:
        bad(f"version mismatch: plugin.json is {version}, "
            f"marketplace.json says {mv}")

# ── CHANGELOG must have a section for this version ───────────────────────────
cl_path = os.path.join(repo, "CHANGELOG.md")
if not os.path.exists(cl_path):
    bad("CHANGELOG.md missing")
else:
    cl = open(cl_path, encoding="utf-8").read()
    heads = re.findall(r"^##\s*\[([^\]]+)\]", cl, re.M)
    if version not in heads:
        bad(f"CHANGELOG.md has no '## [{version}]' section. "
            f"Sections found: {heads[:6]}")
    # An Unreleased section is expected to exist and to be the first one.
    if heads and heads[0] != "Unreleased":
        note(f"CHANGELOG.md's first section is '{heads[0]}', not 'Unreleased'. "
             f"Add an empty '## [Unreleased]' so the next change has a home.")

# ── tags and releases: advice only ───────────────────────────────────────────
def git(*args):
    return subprocess.run(["git", "-C", repo, *args],
                          capture_output=True, text=True).stdout.strip()

tags = [t for t in git("tag", "--list", "v[0-9]*").splitlines() if t]
if not tags:
    note("no version tags found (shallow clone?), skipping the tag check")
else:
    def key(t):
        return [int(x) for x in t.lstrip("v").split(".") if x.isdigit()]
    newest = sorted(tags, key=key)[-1]
    if newest != f"v{version}":
        note(f"newest tag is {newest} but plugin.json is {version}. "
             f"Either tag v{version} or bump plugin.json.")

if fail:
    print("check-versions: FAILED")
    sys.exit(1)
suffix = f", {warn} warning(s)" if warn else ""
print(f"check-versions: version {version} consistent across "
      f"plugin.json, marketplace.json, and CHANGELOG.md{suffix}.")
PY
