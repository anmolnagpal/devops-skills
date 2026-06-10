# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Packaged as a Claude Code plugin.** Skills now ship as the `clouddrove` plugin, served from this repo acting as its own marketplace (`.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`). Skill sources moved from flat `skills/<name>.md` to `skills/<name>/SKILL.md` directories (evals/references co-located). Claude Code commands are now namespaced `/clouddrove:<skill>` with a native `(clouddrove)` label — replacing the per-skill symlink install.
- `install-claude.sh` now runs `claude plugin marketplace add <repo>` + `claude plugin install clouddrove@devops-skills` instead of symlinking each skill. `generate.sh` reads `skills/<name>/SKILL.md`. Install without cloning: `/plugin marketplace add anmolnagpal/devops-skills` then `/plugin install clouddrove@devops-skills`.

## [0.0.1] — 2026-05-14

First public release.

### Added

- **Multi-tool architecture.** One canonical source per skill in `skills/*.md`; `scripts/generate.sh` emits Cursor `.cursor/rules/*.mdc` and Codex `AGENTS.md`. All three tools (Claude Code, Cursor, Codex) stay in sync from a single edit.
- **Flag-driven installer.** `scripts/install.sh` accepts `--claude`, `--cursor`, `--codex`, `--all`, plus `--global`/`--project <path>` for scope and `--no-mcp`/`--no-plugins` to gate Claude-only side effects. Per-tool adapters in `scripts/install-{claude,cursor,codex}.sh`.
- **9 skills:**
  - `/tf` — Terraform review, scaffolding, version upgrades
  - `/k8s` — Kubernetes / Helm review and scaffolds for EKS
  - `/ci` — GitLab CI/CD pipeline review and scaffolds
  - `/github-actions` — GitHub Actions workflow review, security hardening, scaffolds (OIDC, action pinning)
  - `/github` — GitHub repo hygiene: settings audit, CODEOWNERS, branch protection, releases
  - `/docker` — Dockerfile review, image optimization, Compose, registry
  - `/finops` — AWS cost optimization, waste detection, Savings Plans / RIs, EKS cost
  - `/owasp-security` — OWASP Top 10:2025, ASVS 5.0, Agentic AI risks
  - `/skill-creator` — Build, test, and iterate new skills
- **Reference content and helper scripts** for `docker` and `finops` skills (`skills/docker/`, `skills/finops/`).
- **Backlog spec drafts** in `skills/specs/` (aws/azure/gcp × cost/security and kubernetes cost/security) — promote into runnable skills as needed.
- **Curated Claude plugin set** via `config/plugins.txt`: `terraform-code-generation@hashicorp`, `terraform-module-generation@hashicorp`, `claude-mem@thedotmack`, `engineering-workflow-skills@mhattingpete-claude-skills`, `superpowers@claude-plugins-official`, `caveman@caveman`.
- **Bun runtime auto-install** (macOS via the `oven-sh/bun/bun` brew tap; Linux via the official curl installer) so `claude-mem` works without a manual setup step.
- **MCP server installer** (`scripts/mcp.sh`) for Kubernetes, EKS, AWS Billing, Atlassian, gated by `--no-mcp`.
- **AWS profile switcher** (`scripts/set-aws-profile.sh`) for AWS-aware MCP servers.
- **Docker-based install harness** in `_test/` plus a GitHub Actions workflow (`.github/workflows/test.yml`) running it on every push and PR, with extra jobs for adapter-sync drift and ShellCheck.
- **GitHub repo polish:** Dependabot config, PR/issue templates, branch protection ruleset on `main`, `CONTRIBUTING.md`, `SECURITY.md`, MIT `LICENSE`.
- **Project-level CLAUDE.md template** in `templates/` with a Git workflow policy section (no direct push to `main`, no AI co-author trailers, PR-first).

### Notes

- Bootstrap one-liner falls back to default install dir when no TTY is available, so `curl … | bash` and SSH (without `-t`) both work.
- Generated adapters (`.cursor/rules/*.mdc`, `AGENTS.md`) are committed and CI enforces they stay in sync with the canonical `skills/*.md` sources.

[Unreleased]: https://github.com/anmolnagpal/devops-skills/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/anmolnagpal/devops-skills/releases/tag/v0.0.1
