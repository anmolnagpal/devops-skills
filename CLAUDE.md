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

This repo distributes reusable Claude Code **skills**, **plugins**, and **MCP servers** to the team. Skills are markdown files that encode DevOps best practices; the install scripts symlink them into `~/.claude/skills/` and set up plugins/MCP servers.

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
Edit `skills/*.md` → run `bash scripts/generate.sh` → commit `.cursor/rules/` + `AGENTS.md`.

## Repository Structure

```
skills/          ← Canonical skill sources (edit here)
  owasp/         ← Reference docs loaded on-demand by /owasp-security
  docker/        ← References + scripts for /docker
  finops/        ← References + scripts for /finops
  specs/         ← Backlog spec drafts (not active)
.cursor/rules/   ← Generated Cursor .mdc rules (do not hand-edit)
AGENTS.md        ← Generated Codex skill doc (do not hand-edit)
agents/          ← Reserved for Claude agents (currently empty)
scripts/         ← bootstrap, install (dispatcher), install-{claude,cursor,codex}, generate, mcp, set-aws-profile
config/          ← plugins.txt, marketplaces.txt
templates/       ← CLAUDE.md template to copy into project repos
_docs/           ← CHEATSHEET.md with example prompts
_test/           ← Dockerfile + test.sh for Docker-based install testing
```

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

| Skill | File | Auto-triggers on |
|-------|------|-----------------|
| `/tf` | `skills/tf.md` | `**/*.tf`, `**/*.tfvars` |
| `/k8s` | `skills/k8s.md` | `**/values*.yaml`, `**/Chart.yaml`, Helm templates |
| `/ci` | `skills/ci.md` | `**/.gitlab-ci.yml` |
| `/github-actions` | `skills/github-actions.md` | `**/.github/workflows/*.yml` |
| `/github` | `skills/github.md` | `**/CODEOWNERS`, `**/.github/dependabot.yml` |
| `/owasp-security` | `skills/owasp.md` | Manual only |
| `/docker` | `skills/docker.md` | `**/Dockerfile`, `**/docker-compose*.yml` |
| `/finops` | `skills/finops.md` | Manual only |
| `/skill-creator` | `skills/skill-creator.md` | Manual only |

Backlog spec drafts (not active): `skills/specs/` — aws-cost, aws-security, azure-cost, azure-security, gcp-cost, gcp-security, kubernetes-cost, kubernetes-security.

### Multi-tool adapters

Sources in `skills/*.md` generate per-tool artifacts via `scripts/generate.sh`:

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

1. Create `skills/<name>.md` following the frontmatter format above
2. Use `/skill-creator` to iteratively develop and eval the skill
3. Run `bash scripts/generate.sh` to refresh `.cursor/rules/<name>.mdc` + `AGENTS.md`
4. Add an entry to the skill table in `README.md`
5. Commit `skills/`, `.cursor/rules/`, `AGENTS.md` — teammates pull and re-run `./scripts/install.sh --all`

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
