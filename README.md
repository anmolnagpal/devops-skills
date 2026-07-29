# devops-skills

> DevOps review and scaffolding skills for **Claude Code**, **Cursor**, and **Codex**. Terraform, Kubernetes, Docker, CI/CD, GitOps, AWS cost, security, observability, incidents. One source, three tools, no prompt copy-pasting.

[![test](https://github.com/anmolnagpal/devops-skills/actions/workflows/test.yml/badge.svg)](https://github.com/anmolnagpal/devops-skills/actions/workflows/test.yml)
[![release](https://img.shields.io/github/v/release/anmolnagpal/devops-skills?label=release)](https://github.com/anmolnagpal/devops-skills/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-orange)
![Cursor](https://img.shields.io/badge/Cursor-rules-blue)
![Codex](https://img.shields.io/badge/Codex-AGENTS.md-green)

## Install

Claude Code, no clone:

```text
/plugin marketplace add anmolnagpal/devops-skills
/plugin install clouddrove@devops-skills
```

Everything (Cursor rules, Codex `AGENTS.md`, team plugins, MCP servers):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)" -- --all
```

Re-run the same command to update. [Four more install paths →](_docs/INSTALL.md) (npx skills, SSH clone, submodule pin, fork)

## What is a skill?

A markdown file that teaches your coding agent one job properly: what to check, in what order, and what to say about it. Installed once, the agent picks the right one itself when you open a matching file or ask a matching question.

## The 17 skills

| | Skill | What it does | Auto-triggers on |
|---|---|---|---|
| **IaC** | [`tf`](skills/tf/SKILL.md) | Terraform review, AWS resource scaffolding, provider upgrades | `**/*.tf`, `**/*.tfvars` |
|  | [`wrapper-tf`](skills/wrapper-tf/SKILL.md) | CloudDrove wrapper-module pattern, SOC2/GDPR control mapping. Supersedes `tf` on these repos | `_modules/**/*.tf`, `environments/**/*.tf` |
|  | [`tf-plan`](skills/tf-plan/SKILL.md) | Reviews the **plan**, not the source: what this apply destroys, replaces, or leaks | `**/tfplan*.json` |
| **Containers** | [`k8s`](skills/k8s/SKILL.md) | Helm values review and scaffolding, workload and RBAC security | `**/values*.yaml`, `**/Chart.yaml` |
|  | [`docker`](skills/docker/SKILL.md) | Dockerfile review, image size, Compose, registry workflows | `**/Dockerfile`, `**/docker-compose*.yml` |
| **CI/CD** | [`github-actions`](skills/github-actions/SKILL.md) | Workflow review and hardening (OIDC, SHA pinning, injection) | `**/.github/workflows/*.yml` |
|  | [`ci`](skills/ci/SKILL.md) | GitLab CI pipeline review and Terraform/Helm scaffolds | `**/.gitlab-ci.yml` |
|  | [`gitops`](skills/gitops/SKILL.md) | Argo CD and Flux: mutable refs, wildcard AppProjects, unguarded auto-prune, sync waves | `**/argocd/**`, `**/flux-system/**` |
| **Security** | [`owasp`](skills/owasp/SKILL.md) | OWASP Top 10:2025, ASVS 5.0, Agentic AI risks. Severity judged by exploitability | manual |
|  | [`appsec`](skills/appsec/SKILL.md) | Dependency audit via the real ecosystem tool, security headers, CORS | manual |
| **Observability** | [`observability`](skills/observability/SKILL.md) | Logging, retention, metrics, alerts that actually page a human, tracing, SLOs | `**/prometheus*.y*ml`, `**/alertmanager*.y*ml` |
| **Cost** | [`finops`](skills/finops/SKILL.md) | AWS waste detection, right-sizing, Savings Plans/RIs, EKS cost | manual |
| **Delivery** | [`deploy`](skills/deploy/SKILL.md) | Rollout strategy, production-readiness gate, rollback playbook | manual |
|  | [`incident`](skills/incident/SKILL.md) | Runbooks that work at 03:00, on-call readiness, blameless postmortems | `**/docs/runbooks/*.md` |
|  | [`github`](skills/github/SKILL.md) | Repo hygiene: branch protection, CODEOWNERS, releases, required docs | `**/CODEOWNERS`, `**/.github/dependabot.yml` |
|  | [`adr`](skills/adr/SKILL.md) | Capture architectural decisions as structured ADRs | `**/docs/adr/*.md` |
| **Meta** | [`skill-creator`](skills/skill-creator/SKILL.md) | Author, eval, and refine new skills in this repo | manual |

## Using them

Ask in your own words. Nothing to memorize.

```text
"review my terraform before I raise the MR"
"is this plan safe to apply to prod?"        → reads tfplan.json, tells you what it destroys
"why is it replacing my database?"
"review my helm values for prod"
"do my alerts actually reach anyone?"        → traces the route to a real receiver
"write a runbook for the checkout API"
"where is my AWS bill going?"
"review this before I put it on-call"
"/clouddrove:appsec"                          → explicit, when you want a specific skill
```

[More prompts per skill →](_docs/CHEATSHEET.md)

## What the output looks like

Every review answers in the same shape, each finding carrying a stable rule ID and a `file:line`:

```text
BLOCKING — Must fix before MR
[main.tf:14] TF-STATE-001 No remote backend — state would live on a laptop
  → add a `backend "s3"` block with DynamoDB state locking
[rds.tf:31] TF-VAR-001 Hardcoded DB password in `default` → move to a variable,
  mark `sensitive = true`, source from AWS Secrets Manager

ADVISORY — Should fix
[s3.tf:8] TF-RES-001 Bucket missing required tags (Environment, Team, ManagedBy)

Summary: 2 blocking issue(s), 1 advisory issue(s).
```

Those rule IDs are the point. All 166 live in [`rules/rule-ids.yaml`](rules/rule-ids.yaml), CI rejects any a skill invents, and the [auditkit](https://github.com/clouddrove-ci/auditkit) audit engine reads the same registry, so an inline finding and a deep-audit finding are the same finding.

Ask to save a review and you get a [diffable markdown report](_docs/REVIEW-REPORT.md) under `docs/reviews/`.

## Three things worth knowing

**Skills read your project context.** Copy `templates/CLAUDE.md` into a repo once and every skill knows your AWS accounts, Terraform backend, and conventions before it reviews anything.

**Every skill declares what it can touch.** `read-only`, `runs-commands`, or `writes-files` in frontmatter, and CI fails if the label disagrees with the skill's tool list. Nine of the seventeen cannot modify your repo at all. The bundled bash-guard hook blocks destructive commands too, though it stops accidents rather than attacks: it matches command text, so it is a speed bump, not a boundary.

**Findings are tested, not asserted.** 63 fixtures cover 100% of catalog rules, so a skill that stops detecting something turns a test red. Each skill also ships trigger-phrase evals, because a skill with a weak description never loads at all and no rule test would notice.

## Also in the box

Six team plugins (HashiCorp Terraform generation, claude-mem, superpowers, caveman, engineering-workflow-skills) and five MCP servers (live Kubernetes, EKS ops, AWS Cost Explorer, Jira/Confluence, Outline). Both installed by the `--all` one-liner. [Details →](_docs/ARCHITECTURE.md#plugins)

## Docs

| You are | Read |
|---|---|
| Trying it for the first time | [CHEATSHEET.md](_docs/CHEATSHEET.md) — a prompt per skill |
| Installing it for a team | [INSTALL.md](_docs/INSTALL.md) — six paths, and what lands on your machine |
| Wondering why a finding says what it says | [ARCHITECTURE.md](_docs/ARCHITECTURE.md) — rule IDs, severity models, safety labels |
| Saving reviews as files | [REVIEW-REPORT.md](_docs/REVIEW-REPORT.md) — the report format and path convention |
| Adding a skill or a rule | [CONTRIBUTING.md](CONTRIBUTING.md) — repo layout, evals, the CI gates |
| Upgrading | [CHANGELOG.md](CHANGELOG.md) — every release, semver |
| Reporting a vulnerability | [SECURITY.md](SECURITY.md) |

## License

MIT — see [LICENSE](LICENSE).
