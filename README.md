# devops-skills

> **One source of DevOps expertise, three AI coding tools.** Reusable skills for **Claude Code**, **Cursor**, and **Codex** that review and scaffold Terraform, Kubernetes/Helm, Docker, CI/CD (GitHub Actions + GitLab), AWS FinOps, GitHub repo hygiene, and OWASP security — without you copy-pasting the same prompt into every project.

[![test](https://github.com/anmolnagpal/devops-skills/actions/workflows/test.yml/badge.svg)](https://github.com/anmolnagpal/devops-skills/actions/workflows/test.yml)
[![release](https://img.shields.io/github/v/release/anmolnagpal/devops-skills?label=release)](https://github.com/anmolnagpal/devops-skills/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-orange)
![Cursor](https://img.shields.io/badge/Cursor-rules-blue)
![Codex](https://img.shields.io/badge/Codex-AGENTS.md-green)

### Install in Claude Code (10 seconds, no clone)

```text
/plugin marketplace add anmolnagpal/devops-skills
/plugin install clouddrove@devops-skills
```

Skills land as `/clouddrove:tf`, `/clouddrove:finops`, … with a native `(clouddrove)` label. For Cursor/Codex/MCP, use the [installer](#quick-start).

## What you get

- **12 skills** that auto-trigger on file globs and answer with structured, rule-ID-tagged review output
  (`/clouddrove:tf`, `/clouddrove:k8s`, `/clouddrove:ci`, `/clouddrove:github-actions`, `/clouddrove:github`, `/clouddrove:docker`, `/clouddrove:finops`, `/clouddrove:owasp`, `/clouddrove:wrapper-tf`, `/clouddrove:deploy`, `/clouddrove:adr`, `/clouddrove:skill-creator`)
- **Packaged as the `clouddrove` plugin** — installed from this repo's own marketplace, so skills are namespaced `(clouddrove)` in Claude Code natively
- **Single source** in `skills/<name>/SKILL.md` — a generator emits Cursor `.mdc` rules and Codex `AGENTS.md` so every tool stays in sync
- **One installer** with flags — `--claude` / `--cursor` / `--codex` / `--all`, global or per-project scope
- **Curated Claude plugin set** — Terraform code/module generation (HashiCorp), claude-mem, superpowers, caveman, engineering-workflow-skills
- **MCP servers** wired in: Kubernetes live access, EKS ops, AWS Cost Explorer, Atlassian (Jira + Confluence), Outline docs/wiki

> **New here?** Skip to **[CHEATSHEET.md](_docs/CHEATSHEET.md)** for one-line prompts per skill.

## See it in action

Every review answers in the same shape — **BLOCKING** (must fix) and **ADVISORY** (should fix), each finding tagged with a stable rule ID and a `file:line`, then a one-line summary.

**`/clouddrove:tf review`** — pre-MR Terraform check:

```text
BLOCKING — Must fix before MR
[main.tf:14] TF-STATE-001 No remote backend — state would live on a laptop
  → add a `backend "s3"` block with DynamoDB state locking
[rds.tf:31] TF-VAR-001 Hardcoded DB password in `default` → move to a variable,
  mark `sensitive = true`, source from AWS Secrets Manager
[versions.tf:1] TF-PROV-001 Provider not version-pinned → pin `aws ~> 5.0`

ADVISORY — Should fix
[s3.tf:8] TF-RES-001 Bucket missing required tags (Environment, Team, ManagedBy)
[variables.tf:5] TF-VAR-003 `instance_type` has no description/type

Summary: 3 blocking issue(s), 2 advisory issue(s).
```

**`/clouddrove:finops`** — AWS cost review:

```text
BLOCKING — none

ADVISORY — Should fix
[ebs] COST-STOR-003 12 gp2 volumes not migrated to gp3 → ~20% cheaper + faster,
  online conversion, no downtime. Run scripts/ebs-gp2-to-gp3-audit.sh — est. $340/mo
[vpc] COST-NET-001 Per-AZ NAT gateways in 3 AZs for a non-prod account
  → consolidate to 1 or use VPC endpoints — est. $190/mo

Summary: 0 blocking, 2 advisory. Estimated saving: ~$530/month.
```

**`/clouddrove:deploy`** — production-readiness gate before first prod release:

```text
PRODUCTION READINESS — payments-api → prod

BLOCKING — Must fix before deploy
[helm/values-prod.yaml:22] ARCH-SPOF-002 replicaCount: 1 — single pod, no HA
[helm/values-prod.yaml] ARCH-HA-003 No readiness/liveness probes
[.github/workflows/deploy.yml:40] CICD-FLOW-002 No manual prod approval gate

ADVISORY — Should fix
[helm/values-prod.yaml] OBS-MON-002 No alerting configured

Gate: FAILED — 3 blocking. Recommended strategy: blue-green (stateful, first prod release).
```

> Outputs above are representative. Findings, rule IDs, and `file:line` are real to your repo when you run the skill.

## Quick Start

Multi-tool: works with **Claude Code**, **Cursor**, and **Codex** (same skills, different injection per tool).

**Claude Code — install as a plugin** (no clone needed):

```text
/plugin marketplace add anmolnagpal/devops-skills
/plugin install clouddrove@devops-skills
```

Skills then appear as `/clouddrove:tf`, `/clouddrove:deploy`, … with a native `(clouddrove)` label. The install script below does the same automatically (plus Cursor/Codex and MCP).

```bash
# Claude Code only
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)" -- --claude

# All three tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)" -- --all

# Interactive (no flags) — prompts for which tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)"
```

What each flag does:

| Flag | What it installs |
|------|------------------|
| `--claude` | `clouddrove` skills plugin (from this repo's marketplace), team plugins from `config/plugins.txt`, MCP servers |
| `--cursor` | `.cursor/rules/*.mdc` into `~/.cursor/rules/` (or `--project <path>`) |
| `--codex`  | `AGENTS.md` into `~/.codex/AGENTS.md` (or `--project <path>`) |
| `--all`    | All three |

Per-tool flags:

```bash
./scripts/install.sh --claude --no-mcp --no-plugins   # skills only
./scripts/install.sh --cursor --project ~/work/repo   # per-project install
./scripts/install.sh --codex  --project ~/work/repo
```

> **GitLab authentication:** If you get a 403, make sure you have access to the repo. You may need to use SSH clone instead — see [Manual install](#manual-install) below.

## Updating

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)"
```

Same command. If the repo is already installed it pulls the latest and re-runs the installer.

## Manual install

If you prefer SSH or need to use a different install directory:

```bash
git clone git@github.com:anmolnagpal/devops-skills.git ~/devops-skills
~/devops-skills/scripts/install.sh
```

---

## Skills

Single source: `skills/<name>/SKILL.md`. The `clouddrove` plugin bundles them all; the generator emits per-tool adapters via `scripts/generate.sh`:

| Source | Claude slash | Cursor rule | Auto-trigger |
|--------|--------------|-------------|--------------|
| `skills/tf/SKILL.md` | `/clouddrove:tf` | `tf.mdc` | `**/*.tf`, `**/*.tfvars` |
| `skills/k8s/SKILL.md` | `/clouddrove:k8s` | `k8s.mdc` | `**/values*.yaml`, `**/Chart.yaml`, `**/templates/*.yaml` |
| `skills/ci/SKILL.md` | `/clouddrove:ci` | `ci.mdc` | `**/.gitlab-ci.yml` |
| `skills/github-actions/SKILL.md` | `/clouddrove:github-actions` | `github-actions.mdc` | `**/.github/workflows/*.yml` |
| `skills/github/SKILL.md` | `/clouddrove:github` | `github.mdc` | `**/CODEOWNERS`, `**/.github/dependabot.yml`, PR/issue templates |
| `skills/docker/SKILL.md` | `/clouddrove:docker` | `docker.mdc` | `**/Dockerfile`, `**/docker-compose*.yml` |
| `skills/finops/SKILL.md` | `/clouddrove:finops` | `finops.mdc` | manual |
| `skills/owasp/SKILL.md` | `/clouddrove:owasp` | `owasp.mdc` | manual |
| `skills/wrapper-tf/SKILL.md` | `/clouddrove:wrapper-tf` | `wrapper-tf.mdc` | `_modules/**/*.tf`, `environments/**/*.tf`, `.github/workflows/terraform.yml` |
| `skills/deploy/SKILL.md` | `/clouddrove:deploy` | `deploy.mdc` | manual |
| `skills/adr/SKILL.md` | `/clouddrove:adr` | `adr.mdc` | `**/docs/adr/*.md` |
| `skills/skill-creator/SKILL.md` | `/clouddrove:skill-creator` | `skill-creator.mdc` | manual |

All 12 are also injected into `AGENTS.md` for Codex.

### Shared rule-ID vocabulary

Findings are tagged with stable rule IDs (`TF-STATE-001`, `SEC-NET-001`, `CICD-DOCK-002`, …). The canonical set lives in **[`rules/rule-ids.yaml`](rules/rule-ids.yaml)** (141 IDs) — the single source of truth. CI (`scripts/check-rule-ids.sh`) fails if a skill emits an ID not in the registry. The [auditkit](https://github.com/clouddrove-ci/auditkit) audit engine consumes the same registry and checks against it, so an inline plugin finding and a deep-audit finding share the same ID — and the two can't drift.

Backlog specs (drafts, not active): `skills/specs/` — aws-cost, aws-security, azure-cost, azure-security, gcp-cost, gcp-security, kubernetes-cost, kubernetes-security. Promote to active by adding frontmatter under `skills/<name>/SKILL.md`.

Edit `skills/<name>/SKILL.md`, run `bash scripts/generate.sh`, commit. Re-run `./scripts/install.sh --all` to push to local installs.

In Claude Code: invoke with `/clouddrove:<skill>` (namespaced by the plugin). In Cursor: rules auto-attach via `globs:`. In Codex: `AGENTS.md` loaded by default.

### What each skill does

| Skill | Purpose |
|-------|---------|
| `/clouddrove:tf` | Terraform (generic / `terraform-aws-modules` ecosystem): pre-MR review, AWS resource scaffolding, provider upgrade guidance |
| `/clouddrove:k8s` | Kubernetes/Helm: pre-deploy review, production-ready values scaffolding |
| `/clouddrove:ci` | GitLab CI/CD: pipeline review, Terraform/Helm pipeline scaffolds |
| `/clouddrove:github-actions` | GitHub Actions: workflow review, security hardening (OIDC, pinning), scaffolds |
| `/clouddrove:github` | GitHub repo hygiene: settings audit, CODEOWNERS, branch protection, releases |
| `/clouddrove:docker` | Dockerfile review, image optimization, Compose, registry workflows |
| `/clouddrove:finops` | AWS cost: waste detection, right-sizing, Savings Plans/RIs, EKS cost |
| `/clouddrove:owasp` | Security review against OWASP Top 10:2025, ASVS 5.0, Agentic AI risks |
| `/clouddrove:wrapper-tf` | Team standard for AWS Terraform repos on the CloudDrove wrapper pattern: scaffold `_modules/<name>/`, generate Terraform GitHub Actions CI, review against the wrapper pattern, map to SOC2/GDPR controls. Supersedes `/clouddrove:tf` on these repos. |
| `/clouddrove:deploy` | Deployment strategy (rolling/blue-green/canary), production-readiness gate (reuses existing rule IDs), and rollback playbook for AWS/EKS |
| `/clouddrove:adr` | Capture architectural decisions as structured ADRs under `docs/adr/` |
| `/clouddrove:skill-creator` | Author, eval, and refine new skills in this repo |
| `/skill-creator` | Build, test, and iterate new skills |

---

## Plugins

Declared in `plugins.txt` and installed automatically by `install.sh`. Skips any already installed.

All plugins live in `config/plugins.txt` and are installed automatically by `install.sh`.

| Plugin | Source | What it adds |
|--------|--------|--------------|
| `terraform-code-generation` | hashicorp | Terraform style guide, registry search, import, tests |
| `terraform-module-generation` | hashicorp | Module refactoring and Terraform Stacks |
| `claude-mem` | thedotmack | Persistent cross-session memory — Claude remembers past decisions and context |
| `engineering-workflow-skills` | mhattingpete | Git operations, code review, feature planning workflows |
| `superpowers` | obra/superpowers | TDD, systematic debugging, brainstorming/planning, and subagent dev workflows |
| `caveman` | JuliusBrussee/caveman | Ultra-compressed communication mode — cuts ~75% tokens while preserving technical accuracy |

### Adding a plugin

Add a line to `config/plugins.txt`:
- `name@marketplace` — for official Claude plugin marketplace installs
- `hub:github-org/repo` — for plugins installed via `npx claudepluginhub`

If it's from a new marketplace, also add it to `config/marketplaces.txt`. Then commit and push — teammates pick it up on next `./scripts/install.sh`.

---

## MCP Servers

Configured interactively during `install.sh`. Each server prompts you to install or skip. Already-installed servers are skipped automatically.

| Server | What it gives Claude |
|--------|---------------------|
| `kubernetes-mcp-server` | Live read access to EKS clusters — pods, logs, events, Helm releases |
| `eks-mcp-server` | AWS-native EKS ops — cluster diagnostics, CloudWatch, IAM/OIDC, resource management |
| `billing-mcp-server` | Cost Explorer, budget tracking, savings plan analysis, Compute Optimizer |
| `mcp-atlassian` | Jira + Confluence — JQL search, create/update issues, add comments, transition tickets |
| `outline` | Outline docs/wiki — search, read, create/update documents (remote HTTP, browser OAuth) |

### Switching AWS profile

If you need to switch the AWS profile used by the AWS MCP servers:

```bash
# Interactive
~/devops-skills/scripts/set-aws-profile.sh

# Or directly
~/devops-skills/scripts/set-aws-profile.sh prod
```

Restart Claude Code after switching.

---

## Repository Structure

```
devops-skills/
  .claude-plugin/            ← plugin.json (clouddrove) + marketplace.json (repo = its own marketplace)
  skills/                    ← Canonical skill sources, one dir per skill (edit here)
    <name>/SKILL.md          ← the skill body (tf, k8s, ci, owasp, docker, finops, deploy, adr, wrapper-tf, …)
    <name>/evals/            ← static eval fixtures + validate.sh (file-input skills)
    owasp/*.md               ← reference docs loaded on-demand; docker/ finops/ add scripts too
    specs/                   ← Backlog spec docs (not active skills)
  rules/rule-ids.yaml        ← Canonical shared rule-ID registry (single source of truth)
  .cursor/rules/             ← Generated Cursor rules (.mdc) — from scripts/generate.sh
  AGENTS.md                  ← Generated Codex skill doc — from scripts/generate.sh
  agents/                    ← Reserved for Claude Code agents
  hooks/                     ← Shipped with the plugin (registered via hooks.json)
    hooks.json               ← Plugin hook config (uses ${CLAUDE_PLUGIN_ROOT})
    session-banner.sh        ← SessionStart: prints repo/branch/AWS/kube context
    bash-guard.sh            ← PreToolUse(Bash): blocks destructive patterns
  templates/
    CLAUDE.md                ← Copy into project repos for always-on team context
    settings.json            ← Global ~/.claude/settings.json defaults (perm allow/deny)
  scripts/
    bootstrap.sh             ← One-liner installer
    install.sh               ← Flag dispatcher (--claude / --cursor / --codex / --all)
    install-claude.sh        ← Claude adapter: skills, plugins, MCP
    install-cursor.sh        ← Cursor adapter: links .cursor/rules
    install-codex.sh         ← Codex adapter: links AGENTS.md
    generate.sh              ← Build Cursor + Codex adapters from skills/<name>/SKILL.md
    mcp.sh                   ← Interactive MCP server install (Claude only)
    set-aws-profile.sh       ← Switch AWS profile for AWS MCP servers
  config/
    plugins.txt              ← Claude plugins to install
    marketplaces.txt         ← Claude plugin marketplaces
  _docs/
    CHEATSHEET.md            ← Example prompts per skill and MCP server
  README.md
```

---

## Global settings.json

`install.sh --claude` seeds `~/.claude/settings.json` from `templates/settings.json` on first run. On subsequent runs it **merges missing permission entries only** — never clobbers existing keys (`enabledPlugins`, `mcpServers`, `hooks`, etc.).

Template ships with a safe DevOps allow-list (read-only kubectl/terraform/aws/git) and deny-list (`kubectl delete`, `terraform apply`, `terraform destroy`, `rm -rf`, `aws s3 rm`, `aws ec2 terminate-instances`). Edit `templates/settings.json` to change team defaults, commit, teammates re-run `./scripts/install.sh --claude`.

---

## Project CLAUDE.md Template

Copy `templates/CLAUDE.md` into the root of any project repo and fill in the placeholders. Claude Code auto-loads it every session, giving Claude permanent context about your AWS setup, Terraform backend, EKS clusters, and team conventions — without needing to invoke a skill.

```bash
cp ~/devops-skills/templates/CLAUDE.md /path/to/your/repo/CLAUDE.md
cp -r ~/devops-skills/templates/.claude /path/to/your/repo/.claude
# Fill in the CLAUDE.md placeholders, then commit both
```

---

## Adding a New Team Skill

Skills follow a standard format. Use the `/skill-creator` skill to build and test new ones.

### Skill file format

```markdown
---
name: skill-name
description: "Concise description — include when to use and key trigger keywords"
metadata:
  version: 1.0.0
  author: Anmol Nagpal
  category: devops
  updated: YYYY-MM-DD
---

# Skill Title

One-line summary.

## Keywords
keyword1, keyword2, keyword3

## Output Artifacts

| Request | Output |
|---------|--------|
| "do X" | Produces Y |

---

## SECTION — ...
```

### Steps to add

1. Create `skills/<name>/SKILL.md` following the format above (co-locate `evals/`, references, scripts in the same dir)
2. Run `bash scripts/generate.sh` to refresh Cursor (`.cursor/rules/<name>.mdc`) + Codex (`AGENTS.md`) adapters
3. Commit `skills/<name>/SKILL.md`, the new `.cursor/rules/<name>.mdc`, and updated `AGENTS.md`
4. Teammates run `git pull && ./scripts/install.sh --all` to pick it up (the plugin auto-discovers any `skills/<name>/SKILL.md`)

---

## Testing

CI runs on every push to `main` and every pull request via GitHub Actions (`.github/workflows/test.yml`), with six gates: Docker install harness, adapter-sync (`.cursor/rules/`, `AGENTS.md` regenerated from `skills/<name>/SKILL.md`), skill-frontmatter lint, rule-ID registry check, eval fixtures, and ShellCheck.

To run the test locally (requires Docker):

```bash
bash _test/test.sh
```

The test builds `_test/Dockerfile`, which runs `install.sh` in a clean container with a stubbed `claude` CLI and `CI=true` to skip interactive MCP prompts. It verifies all skills are symlinked and all plugins install without error.

---

## Adding a New MCP Server

1. Add a new block to `scripts/mcp.sh` following the existing pattern (check if installed → prompt → register the server):
   - **Local/stdio** servers — `claude mcp add-json <name> '{"command":...,"args":...}' -s user`
   - **Remote/HTTP** servers (e.g. `outline`) — `claude mcp add <name> <url> --transport http -s user` (auth via browser OAuth on first use)
2. If the server uses AWS credentials, add it to the `AWS_MCP_SERVERS` list in `scripts/set-aws-profile.sh`
3. Commit and push — teammates pick it up on next `./scripts/install.sh`
