#!/usr/bin/env python3
"""Generate the machine-readable skill catalog (index.json) and the framework
coverage doc (FRAMEWORKS.md) from skills/<name>/SKILL.md sources.

index.json is the discovery surface: one JSON object listing every skill with
its trigger description, safety label, paths, and framework mappings. Tools,
dashboards, and the marketplace can read it without parsing 17 markdown files.

FRAMEWORKS.md is the human view of the same data: which skills cover each
MITRE ATT&CK technique, NIST CSF 2.0 subcategory, and D3FEND technique.

Usage:
    python3 scripts/generate-index.py            # write index.json + FRAMEWORKS.md
    python3 scripts/generate-index.py --check     # verify both are current (CI)

Frontmatter is read with PyYAML, the same loader check-skills.sh uses. A
regex frontmatter parser silently truncates multi-line descriptions to their
first line, so do not reintroduce one here.
"""
from __future__ import annotations

import json
import os
import re
import sys
from collections import defaultdict

import yaml

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS_DIR = os.path.join(REPO, "skills")
INDEX_PATH = os.path.join(REPO, "index.json")
COVERAGE_PATH = os.path.join(REPO, "FRAMEWORKS.md")

# Frontmatter is the block between the opening '---' and the next '---' alone
# on its line. Tolerates CRLF and a leading UTF-8 BOM.
_FRONTMATTER_RE = re.compile(r"\A﻿?---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", re.DOTALL)

FRAMEWORK_KEYS = ("mitre_attack", "nist_csf", "d3fend")


def load_frontmatter(path: str) -> dict:
    text = open(path, encoding="utf-8").read()
    m = _FRONTMATTER_RE.match(text)
    if not m:
        raise ValueError(f"{path}: no YAML frontmatter block")
    data = yaml.safe_load(m.group(1))
    if not isinstance(data, dict):
        raise ValueError(f"{path}: frontmatter is not a mapping")
    return data


def iter_skills():
    for slug in sorted(os.listdir(SKILLS_DIR)):
        skill_md = os.path.join(SKILLS_DIR, slug, "SKILL.md")
        if os.path.isfile(skill_md):
            yield slug, skill_md


def build_index() -> dict:
    skills = []
    for slug, path in iter_skills():
        fm = load_frontmatter(path)
        meta = fm.get("metadata") or {}
        frameworks = fm.get("frameworks") or {}
        # Normalize: only keep the known framework keys, drop empty lists.
        norm_frameworks = {
            k: list(frameworks[k])
            for k in FRAMEWORK_KEYS
            if frameworks.get(k)
        }
        skills.append({
            "name": fm.get("name", slug),
            "description": " ".join(str(fm.get("description", "")).split()),
            "safety": fm.get("safety"),
            "category": meta.get("category"),
            "version": str(meta.get("version")) if meta.get("version") is not None else None,
            "updated": str(meta.get("updated")) if meta.get("updated") is not None else None,
            "paths": fm.get("paths") or [],
            "allowed_tools": fm.get("allowed-tools"),
            "frameworks": norm_frameworks,
        })
    return {
        "schema": "clouddrove-skills-index/v1",
        "count": len(skills),
        "skills": skills,
    }


def render_coverage(index: dict) -> str:
    # framework -> id -> [skill names]
    tables = {k: defaultdict(list) for k in FRAMEWORK_KEYS}
    for skill in index["skills"]:
        for key, ids in skill["frameworks"].items():
            for _id in ids:
                tables[key][_id].append(skill["name"])

    titles = {
        "mitre_attack": "MITRE ATT&CK (Enterprise)",
        "nist_csf": "NIST CSF 2.0",
        "d3fend": "MITRE D3FEND",
    }
    ref = {
        "mitre_attack": "https://attack.mitre.org/techniques/",
        "nist_csf": "https://csrc.nist.gov/pubs/cswp/29/the-nist-cybersecurity-framework-20/final",
        "d3fend": "https://d3fend.mitre.org/",
    }

    mapped = sum(1 for s in index["skills"] if s["frameworks"])
    lines = [
        "# Framework Coverage",
        "",
        "Generated from `skills/<name>/SKILL.md` frontmatter by "
        "`scripts/generate-index.py`. Do not hand-edit.",
        "",
        f"{mapped} of {index['count']} skills carry framework mappings. "
        "Skills without a security-relevant mapping (finops, skill-creator, adr) "
        "are intentionally omitted.",
        "",
    ]
    for key in FRAMEWORK_KEYS:
        table = tables[key]
        lines.append(f"## {titles[key]}")
        lines.append("")
        if not table:
            lines.append("_No skills mapped._")
            lines.append("")
            continue
        lines.append(f"Reference: {ref[key]}")
        lines.append("")
        lines.append("| ID / Technique | Skills |")
        lines.append("|---|---|")
        for _id in sorted(table):
            names = ", ".join(f"`{n}`" for n in sorted(table[_id]))
            lines.append(f"| {_id} | {names} |")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    check = "--check" in sys.argv[1:]
    index = build_index()
    index_json = json.dumps(index, indent=2, ensure_ascii=False) + "\n"
    coverage_md = render_coverage(index)

    if check:
        stale = []
        if not os.path.exists(INDEX_PATH) or open(INDEX_PATH, encoding="utf-8").read() != index_json:
            stale.append("index.json")
        if not os.path.exists(COVERAGE_PATH) or open(COVERAGE_PATH, encoding="utf-8").read() != coverage_md:
            stale.append("FRAMEWORKS.md")
        if stale:
            print(f"ERROR: {', '.join(stale)} out of date. Run scripts/generate-index.py and commit.", file=sys.stderr)
            return 1
        print(f"check: index.json + FRAMEWORKS.md current ({index['count']} skills).")
        return 0

    open(INDEX_PATH, "w", encoding="utf-8").write(index_json)
    open(COVERAGE_PATH, "w", encoding="utf-8").write(coverage_md)
    mapped = sum(1 for s in index["skills"] if s["frameworks"])
    print(f"index: {INDEX_PATH} ({index['count']} skills, {mapped} mapped)")
    print(f"coverage: {COVERAGE_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
