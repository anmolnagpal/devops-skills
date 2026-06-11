# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git workflow (MUST follow)

These rules apply to every push originating from this repo. They override default agent behavior.

1. **Never push directly to `main`.** Always create a branch (`feat/<name>`, `fix/<name>`, `chore/<name>`) and open a pull request.
2. **No `Co-Authored-By` trailers.** No "🤖 Generated with Claude Code" footers. No AI attribution of any kind in commit messages or PR bodies. Commits read as authored solely by the user.
3. **Use the repo's `git config user.name` / `user.email`.** Do not set or override identity per-commit. If unset, ask the user before configuring.
4. **One logical change per branch / PR.** Don't bundle unrelated edits.
5. **Commit message format** — imperative subject (≤72 chars), blank line, body explaining the *why*. Example:
   ```
   Pin Bun install to the oven-sh tap

   Bare `brew install bun` resolves to wrong formula on some Homebrew
   versions. Use the official tap explicitly so installs are deterministic.
   ```
6. **Confirm before pushing.** If the agent (Claude / Cursor / Codex) is about to push, list the commit summary + diff stat and ask "OK to push?" first.
7. **Never `--force` push to a shared branch.** Force-push only to your own short-lived feature branches, and only after confirming with the user.
8. **PR before merge.** Even for your own commits — open a PR, let CI run, then merge.

## Purpose

This repo distributes reusable Claude Code **skills**, **plugins**, and **MCP servers** to the team. Skills are markdown files that encode DevOps best practices; they ship as the **`clouddrove` plugin** (this repo is also its own marketplace), installed via `claude plugin install clouddrove@devops-skills`, alongside the team plugins and MCP servers wired by the install scripts.

## Validation commands

Run these locally before pushing — they are the same checks CI runs:

```bash
pip3 install --break-system-packages pyyaml   # one-time dep; --break-system-packages required on macOS Homebrew Python

bash scripts/check-skills.sh             # lint: name/description frontmatter
bash scripts/check-rule-ids.sh           # every rule ID in skills/ exists in rules/rule-ids.yaml
bash scripts/check-evals.sh              # eval fixtures reference only known rule IDs
bash scripts/generate.sh --check         # .cursor/rules/ + AGENTS.md are up to date
```

CI also runs ShellCheck on `scripts/` and a full Docker-based install harness (`_test/test.sh`).

## Installing / Updating

```bash
# Fresh install or update — pick tool(s) via flags
/bin/bash -c "$(curl -fsSL .../bootstrap.sh)" -- --all       # claude + cursor + codex
/bin/bash -c "$(curl -fsSL .../bootstrap.sh)" -- --claude    # Claude only (legacy)

# Manual after clone
./scripts/install.sh --all
./scripts/install.sh --claude --no-mcp --no-plugins          # skills only
./scripts/install.sh --cursor --project ~/work/repo          # per-project Cursor

# Switch AWS profile for MCP servers (eks-mcp-server, billing-mcp-server)
./scripts/set-aws-profile.sh [profile-name]
```

`install.sh` is idempotent — already-installed plugins, MCP servers, and symlinks are reused.
Edit `skills/<name>/SKILL.md` → run `bash scripts/generate.sh` → commit `.cursor/rules/` + `AGENTS.md`.

## Repository Structure

```
.claude-plugin/  ← plugin.json (clouddrove plugin) + marketplace.json (this repo = its own marketplace)
skills/          ← Canonical skill sources, one dir per skill (edit here)
  <name>/SKILL.md   ← the skill body
  <name>/evals/     ← static eval fixtures + validate.sh (review skills)
  owasp/*.md        ← reference docs loaded on-demand by the owasp skill
  docker/, finops/  ← references + scripts, co-located with the skill
  specs/         ← Backlog spec drafts (not active; no SKILL.md, not generated)
.cursor/rules/   ← Generated Cursor .mdc rules (do not hand-edit)
AGENTS.md        ← Generated Codex skill doc (do not hand-edit)
agents/          ← Reserved for Claude agents (currently empty)
scripts/         ← bootstrap, install (dispatcher), install-{claude,cursor,codex}, generate, mcp, set-aws-profile
config/          ← plugins.txt, marketplaces.txt (external team plugins, not clouddrove)
templates/       ← CLAUDE.md template to copy into project repos
_docs/           ← CHEATSHEET.md with example prompts
_test/           ← Dockerfile + test.sh for Docker-based install testing
```

Skills install as the **`clouddrove` plugin** served from this repo's own marketplace (`.claude-plugin/marketplace.json`). `install-claude.sh` runs `claude plugin marketplace add <repo>` + `claude plugin install clouddrove@devops-skills`, so skills are namespaced `/clouddrove:<skill>` natively — no per-skill symlinks.

## Skill Architecture

### File Format

Every skill is a markdown file with YAML frontmatter:

```yaml
---
name: skill-name          # Invocation: /skill-name
description: "..."        # When/why to trigger (shown to Claude for selection)
metadata:
  version: X.Y.Z
  author: Name
  category: devops
  updated: YYYY-MM-DD
paths:                    # Optional: auto-trigger on these file patterns
  - "**/*.tf"
allowed-tools:            # Optional: restrict available tools
  - Glob
  - Read
---
# Skill content...
```

### Three-Tier Loading

1. **Metadata** (name + description) — Always in context; used for skill selection
2. **Skill body** — Loaded when skill triggers; target <500 lines
3. **Reference files** (e.g., `skills/owasp/`) — Loaded on-demand by the skill itself

### Current Skills

| Skill (Claude slash) | Source | Auto-triggers on |
|-------|------|-----------------|
| `/clouddrove:tf` | `skills/tf/SKILL.md` | `**/*.tf`, `**/*.tfvars` |
| `/clouddrove:k8s` | `skills/k8s/SKILL.md` | `**/values*.yaml`, `**/Chart.yaml`, Helm templates |
| `/clouddrove:ci` | `skills/ci/SKILL.md` | `**/.gitlab-ci.yml` |
| `/clouddrove:github-actions` | `skills/github-actions/SKILL.md` | `**/.github/workflows/*.yml` |
| `/clouddrove:github` | `skills/github/SKILL.md` | `**/CODEOWNERS`, `**/.github/dependabot.yml` |
| `/clouddrove:owasp` | `skills/owasp/SKILL.md` | Manual only |
| `/clouddrove:docker` | `skills/docker/SKILL.md` | `**/Dockerfile`, `**/docker-compose*.yml` |
| `/clouddrove:finops` | `skills/finops/SKILL.md` | Manual only |
| `/clouddrove:deploy` | `skills/deploy/SKILL.md` | Manual only |
| `/clouddrove:adr` | `skills/adr/SKILL.md` | `**/docs/adr/*.md` |
| `/clouddrove:wrapper-tf` | `skills/wrapper-tf/SKILL.md` | `_modules/**/*.tf`, `environments/**/*.tf` |
| `/clouddrove:skill-creator` | `skills/skill-creator/SKILL.md` | Manual only |

Backlog spec drafts (not active): `skills/specs/` — aws-cost, aws-security, azure-cost, azure-security, gcp-cost, gcp-security, kubernetes-cost, kubernetes-security.

### Rule ID registry

`rules/rule-ids.yaml` is the canonical vocabulary for every finding ID a skill can emit. Format: `DOMAIN-CATEGORY-NNN`. **Any new rule ID used in a `skills/<name>/SKILL.md` Rule Catalog must be registered here first** — `check-rule-ids.sh` (and CI) will reject unknown IDs. Framework/compliance IDs (`SOC2-*`, `CIS-*`, `NIST-*`, etc.) are exempt and pass without a registry entry.

### Eval cases

Review skills can ship a `skills/<name>/evals/` folder to prove correctness without a model:

```
evals/
  cases/
    <case-name>/
      <fixture file>    ← input (e.g. .tf, Dockerfile)
      expected.txt      ← one rule ID per line the skill MUST report; empty = clean pass
  validate.sh           ← static consistency check (copy verbatim from any existing skill)
```

`validate.sh` asserts every ID in `expected.txt` exists in the skill's Rule Catalog, and that `clean-*` cases have an empty `expected.txt`. Run it with `bash skills/<name>/evals/validate.sh`.

### Multi-tool adapters

Sources in `skills/<name>/SKILL.md` generate per-tool artifacts via `scripts/generate.sh`:

- `.cursor/rules/<name>.mdc` — Cursor (`globs:` derived from `paths:`, auto-attach)
- `AGENTS.md` — Codex (one file, all skills concatenated)

Install per tool: `./scripts/install.sh --claude|--cursor|--codex|--all`. See `README.md` Quick Start.

### Standard Review Output Format

All review skills produce output in this format:

```
BLOCKING — Must fix before [MR/deploy/merge]
[file:line] Issue → recommendation

ADVISORY — Should fix
[file:line] Issue → recommendation

Summary: X blocking issue(s), Y advisory issue(s).
```

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` following the frontmatter format above (one directory per skill; co-locate `evals/`, references, scripts)
2. Register any new rule IDs in `rules/rule-ids.yaml` under the appropriate domain before using them in the skill
3. Use `/clouddrove:skill-creator` to iteratively develop and eval the skill
4. Add eval cases under `skills/<name>/evals/cases/` — copy `validate.sh` verbatim from an existing skill (e.g. `skills/tf/evals/validate.sh`)
5. Run `bash scripts/generate.sh` to refresh `.cursor/rules/<name>.mdc` + `AGENTS.md`
6. Add an entry to the skill table in `README.md` (the plugin auto-discovers any `skills/<name>/SKILL.md`)
7. Commit `skills/`, `rules/rule-ids.yaml`, `.cursor/rules/`, `AGENTS.md` — teammates pull and re-run `./scripts/install.sh --all`

## Adding a New MCP Server

Add an interactive block to `scripts/mcp.sh` using the `_ask` and `_mcp_installed` helpers already defined there. The block should call `claude mcp add-json` to register the server.

## Plugins

All plugins are in `config/plugins.txt`, installed by `install.sh`. Two line formats:

- `name@marketplace` — installed via `claude plugin install`
- `hub:github-org/repo` — installed via `npx claudepluginhub` (for plugins not on the official marketplace)

Non-default marketplaces go in `config/marketplaces.txt`.

## Key Conventions

- Skills restrict tools via `allowed-tools` — review skills use only `Glob` and `Read` (no writes)
- `mcp.sh` is **sourced** (not executed directly) by `install.sh` — it must not use `#!/bin/bash` exit semantics that break the parent shell
- `scripts/set-aws-profile.sh` uses inline Python to patch `~/.claude/settings.json`; it updates `AWS_PROFILE` for `eks-mcp-server` and `billing-mcp-server`
- The `templates/CLAUDE.md` is a template to copy into project repos for always-on team context — it is not this repo's own CLAUDE.md
- The plugin ships two hooks via `hooks/hooks.json` (referenced from `plugin.json`): a `SessionStart` banner and a `PreToolUse` bash-guard that blocks destructive patterns (force-push, `git reset --hard`, `DROP TABLE`, `aws rds delete-db-*`, etc.). When adding new dangerous patterns to block, extend `hooks/bash-guard.sh`.
