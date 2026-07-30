# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Four rules the Terraform reviewer should have had from the start**, promoted out of the `_unemitted.planned` worklist: `SEC-PUB-001` (public bucket via ACL, policy `Principal: "*"`, or a missing/partial `aws_s3_bucket_public_access_block`), `TF-STATE-003` (a committed `.tfstate`), `SEC-LOG-001` (no CloudTrail, or a trail with logging disabled), and `SEC-LOG-002` (a VPC defined here with no flow log). Three fixtures, including a clean case that is the same configuration done correctly resource for resource, so the pair isolates what each rule keys on. Both absence rules carry an exclusion requiring the configuration to be visible before their absence may be claimed, matching how `SEC-K8S-004` and the `OBS-*` rules are scoped.
- **`.gitignore` negation for eval state fixtures.** `TF-STATE-003` detects a committed `.tfstate`, so proving it needs one, and `*.tfstate` on line 2 would have excluded the fixture. The case would have shipped without its input and failed for everyone but the author.

### Fixed

- **The eval harness now compares content, not just versions.** `claude plugin update` is a no-op when the version has not moved, so an edited skill body can sit in the tree while the installed copy serves the old text. That happened during the first `--triggers` run and a re-run would have measured the unfixed skills. The guard hashes every `skills/*/SKILL.md` in both places and names the reinstall that actually fixes it.
- **`check-prompts.sh` rejects a phrase present in both prompt sections.** It fails whichever way the model answers, so the suite can never go green and the failure reads as a skill defect. Cost a real debugging detour when a deletion missed by three words left `"review my infra"` in both of `tf`'s lists.

## [1.4.1] — 2026-07-29

### Added

- **`scripts/check-versions.sh`** (new CI gate) asserts `plugin.json`, `marketplace.json`, and `CHANGELOG.md` agree on the version. This drift really happened: `plugin.json` said 1.3.0 while no `v1.3.0` tag existed and `v1.2.0` was tagged but never released, so the release badge advertised a version two releases old. The marketplace plugin entry now carries an explicit `version` so the two files cannot silently diverge.
- **Trigger-phrase evals** (new CI gate). Fixture evals prove a skill's rules fire; nothing proved the skill gets *loaded*, and the `description` is the only text the model reads when deciding. Every skill now ships `evals/prompts.md` with at least four positive prompts in the words someone would type, plus negative prompts for skills whose scope overlaps another's (`tf` against `wrapper-tf`, `appsec` against `owasp`, `observability` against `incident`, and five more pairs). Each negative prompt names where it should go instead, so a failure says which skill over-triggered. `scripts/check-prompts.sh` enforces the shape; `run-behavioral-evals.sh --triggers` runs them against the model.
- **`scripts/validate.sh`** runs all six free checks in CI's order, so "did I break anything" has one command instead of five.
- **`templates/skill/`** is a copyable starting point: frontmatter with `safety`, the standard sections, the suppression and false-positive-exclusion scaffolding, and a delete-me PR checklist. Previously the format was documented in `CONTRIBUTING.md` but nothing was copyable.

- **Every registry rule ID must now be emitted by a skill or declared unemitted.** `check-rule-ids.sh` previously printed a silent `note: 22 registry ID(s) not referenced by any skill` and passed. Dead vocabulary reads as coverage, so the note is now a FAIL unless the ID is declared under `_unemitted` in `rules/rule-ids.yaml`: `reserved` for the five that need a live DNS query and belong to auditkit's external-surface auditor, `planned` for the seventeen that are implementable from files and now name the skill that should own them. The check also fails if an ID is both emitted and declared, or if a declaration names an ID that no longer exists.

- **First Tier-2 behavioral eval run, recorded in `_docs/EVAL-RESULTS.md`.** 60/63 cases passed, and all three failures were defects in the evals or the skills rather than model misbehavior: an expectation that was impossible to satisfy (an absence-finding from a single-file fixture, green in CI since PR #12 because Tier-1 never runs a skill), and two false positives where the model was right and the fixture encoded an assumption the skill never stated. Zero false positives across the 22 `clean-*` cases once corrected.
- **`run-behavioral-evals.sh` now asserts the installed plugin version matches `plugin.json`.** The first run started with 1.3.0 installed against a 1.4.0 tree, which would have silently skipped every skill added in 1.4.0 while appearing to pass. A green run against a stale install is worse than no run.

### Changed

- **The bash-guard hook now states its own limits.** It matches command text, so a variable holding a flag, an alias, or a here-doc fed to `sh` gets past it. It prevents accidents, not attacks, and the header and README now say so rather than implying a boundary it does not provide. Claude Code's `sandbox` setting is named as the real control.
- **README docs table is now a reader-role router** ("You are / Read") rather than a file list.
- Plugin and marketplace descriptions refreshed: they still advertised 13 skills and omitted GitOps, observability, incident response, and plan review.

## [1.4.0] — 2026-07-29

### Added

- **Four new skills**, taking the set from 13 to 17:
  - **`observability`** — centralized logging, log retention, metrics collection, alerting, tracing, dashboards, SLO/SLI and burn-rate alerts. Fills the seven `OBS-*` IDs that were registered but unused. Built around tracing `PrometheusRule` labels through the Alertmanager route tree to a real receiver, since rules that match only the default `null` receiver are the common way a team believes it has alerting and does not.
  - **`tf-plan`** — reviews `terraform show -json` output rather than `.tf` source: destroys and replacements of data-bearing resources, secrets readable in plan output, out-of-band drift, blast radius, and whether apply is bound to the reviewed plan artifact. Six new `TF-PLAN-*` IDs, deliberately separate from `TF-*` because the existing rules are properties of source while these are properties of a diff against live state. Read-only with no Bash: producing a plan needs live cloud credentials, and an advisory reviewer should not hold them.
  - **`gitops`** — Argo CD and Flux: mutable source refs, AppProject wildcard grants, unguarded auto-prune (`prune` plus `allowEmpty`, the configuration behind most "Argo deleted my namespace" incidents), sync waves, `selfHeal` drift enforcement, per-environment separation. Six new `CICD-GITOPS-*` IDs plus four reused.
  - **`incident`** — runbooks, incident readiness audit before a rotation starts, severity and escalation model, blameless postmortems. Registers no new rule IDs: incident readiness is the existing documentation, alerting, and recovery rules asked at a different moment.
- **Workload security checks in `k8s`** — `SEC-K8S-002`/`003`/`004`/`006`/`007`, six registered-but-unused IDs now emitted: host namespaces and `hostPath`, RBAC wildcards and `cluster-admin` bindings, namespace network segmentation, service exposure, and API-token or env-secret exposure. `SEC-K8S-005` is deliberately excluded and the reason recorded in the catalog, since it duplicates `COST-K8S-001` on the same line of YAML.
- **Enforced `safety` frontmatter on every skill** (`read-only` / `runs-commands` / `writes-files`). `check-skills.sh` derives the correct value from `allowed-tools` and fails on a mismatch, so a skill that quietly gains `Write` cannot keep claiming read-only.
- **`npx skills` install path documented** — `npx skills add anmolnagpal/devops-skills` already enumerates every skill against the existing layout, so this documents working behavior rather than adding an integration.
- **Persisted review reports** — `_docs/REVIEW-REPORT.md` defines a report format (machine-readable frontmatter, one table row per finding, a suppressions-honored section, and a mandatory "not assessed" section) plus the `docs/reviews/<skill>-<date>.md` path convention. Review skills stay `read-only`: they produce the content and name the path, and the session performs the write, so no skill gains `Write` and the enforced read-only guarantee is unaffected.
- **Reference docs for the new skills** — depth-on-demand material in `skills/<name>/references/`: force-replacement attribute tables and the `terraform show -json` field guide for `tf-plan`, PromQL patterns and SLO/burn-rate arithmetic for `observability`, failure-mode diagnosis and a secrets decision table for `gitops`, and postmortem language guidance for `incident`.
- **Eval rule coverage at 100%** — every one of the 145 catalog rules across 11 suites now has at least one fixture claiming it should fire, up from 56%. Nine new cases, five of them repo-shaped directories, since absence rules and cross-file rules (`CDTF-STATE-001`, `CICD-OPS-005`, the `OBS-*` absence set) cannot be tested from a single file.
- **`META-SUP-001` proven in every suite** — the rule was in eleven catalogs with no fixture behind it, and the semantics were undefined. Every inline-suppression skill now states that a suppression missing its reason doesn't suppress anything, matching the wording `finops` and `github` already used for waiver files, with a fixture per suite.

### Changed

- **README restructured** as a user-facing document: skills grouped by category instead of one flat 13-row list, a Mermaid diagram documenting how skills relate (`wrapper-tf` supersedes `tf`, `deploy` aggregates artifact skills, `github`/`finops` share a waiver file, `appsec` escalates to `owasp`), six install paths (plugin, one-liner, npx skills, clone, submodule pin, fork-and-customize), a table of contents, and new Versioning, Contributing, and License sections. The `templates/CLAUDE.md` project-context step moved up from the tail of the doc to its own section, since every skill reads it.
- **README cut to 120 lines** (from 497). Nine sections: install, what a skill is, the catalog, how to ask, what output looks like, three things worth knowing, what else ships, a docs index, license. Reference material moved out rather than trimmed: `_docs/ARCHITECTURE.md` (how skills relate, rule-ID contract, severity models, safety labels, project context, plugins, MCP, versioning), `_docs/INSTALL.md` (all six paths and what lands on your machine), and the repository layout into `CONTRIBUTING.md` where the rest of the maintainer content already lives.
- **README reading order** — the skill catalog and a new "Using them" section with real example prompts now sit above installation, the seven per-category tables collapse into one table with a category column and per-skill links, the four secondary install paths fold into a details block, and a short explainer of what a skill is was added for readers new to the concept.
- **Maintainer docs moved to `CONTRIBUTING.md`**: skill file format, rule-ID registration, eval cases, the six CI gates, the Tier-2 behavioral eval harness, and the add-a-plugin / add-an-MCP-server steps now live there instead of interleaved with user-facing README content.

### Fixed

- README rule-ID count was stale (141); the registry now holds 166 IDs across 10 domains and the README tracks it.
- **`tf-plan` assumed a top-level `backend` key in `terraform show -json` output, which does not exist.** The skill now derives the target environment from `variables`, the workspace, resource tags, or module addresses, and says so explicitly; the five plan fixtures were corrected to match real plan output.
- Eval fixtures used literals matching real provider secret formats (`sk_live_…`, `ghp_…`), which GitHub push protection correctly blocks. Replaced with inert values under the same revealing key names, so the fixtures still prove detection without tripping the scanner. `CONTRIBUTING.md` now states the rule.
- Removed a duplicate `/skill-creator` row from the skill table and a stale GitLab-403 authentication note (the repo is on GitHub).

## [1.3.0] — 2026-07-07

### Added

- **New `appsec` skill** — dependency audit (runs the real ecosystem audit tool: `npm audit`, `pip-audit`, `govulncheck`, `cargo audit`, etc. against the actual lockfile, not a memorized known-bad-version list), missing security headers, and CORS wildcard misconfiguration. Fills previously-registered but unused `SEC-APP-001/002`, `SEC-DEP-001`.
- **IAM checks in `tf` and `wrapper-tf`** — `SEC-IAM-001` (wildcard action/resource) and `SEC-IAM-003` (MFA not enforced, excluding service roles).
- **Repo hygiene checks in `github`** — `REPO-DOC-001` (no README), `REPO-DOC-002` (no CONTRIBUTING/runbook), `REPO-TEST-001` (no test coverage), as local Glob-based file checks alongside the existing gh-api AUDIT flow.

## [1.2.1] — 2026-07-07

### Fixed

- `hooks/hooks.json` was missing its required top-level `hooks` wrapper key, so the plugin's `SessionStart` banner and `PreToolUse` bash-guard silently failed to load (`claude plugin list` reported `failed to load`). Both hooks now register correctly.

## [1.2.0] — 2026-07-05

### Added

- **Tier-2 behavioral eval harness** (opt-in) for live skill validation against real fixtures, plus fixed unanchored regex matching and non-deterministic fixture selection.
- **Named false-positive exclusion lists** and a quote-line requirement added across all file-review skills (docker, k8s, github, wrapper-tf, owasp, finops).
- **Suppression mechanism parity** across review skills: inline suppression support for OWASP and deploy, waiver-file mechanism for GitHub audit and FinOps.
- **CDTF-MOD-007/008** — restored two wrapper-module checks (missing required files, unthreaded variables) lost in earlier cleanup, with full catalog/checklist/registry entries.
- **Deploy readiness-gate transparency** — the READINESS gate now reports which artifact skills actually ran and returns INCOMPLETE rather than silently claiming READY when artifacts are skipped.
- `SEC-DNS-001..003`, `SEC-EMAIL-001..002` (external-surface auditor), `SEC-K8S-002..007` (k8s workload security) rule IDs.

### Fixed

- Registry drift on `CDTF-MOD-001..006` between the canonical registry and the wrapper-tf skill.
- Docker FP-exclusion #4 severity contradiction, k8s exception clause too narrow in scope, GitHub FP-exclusion contradictory wording.
- Dead Bash grant on the deploy skill; its rule-reuse mechanism made concrete.

## [1.1.0] — 2026-06-10

### Added

- **Canonical rule-ID registry** (`rules/rule-ids.yaml`) — single source of truth for the 141-ID shared vocabulary the review skills emit, so this repo and the auditkit audit engine never drift on what a rule ID means. New `Rule IDs` CI job (`scripts/check-rule-ids.sh`) asserts every rule ID used in any skill's catalog exists in the registry (framework/control IDs like `SOC2-*`, `CIS-*` are allowed without entries).

## [1.0.1] — 2026-06-10

### Changed

- **Packaged as a Claude Code plugin.** Skills now ship as the `clouddrove` plugin, served from this repo acting as its own marketplace (`.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`). Skill sources moved from flat `skills/<name>.md` to `skills/<name>/SKILL.md` directories (evals/references co-located). Claude Code commands are now namespaced `/clouddrove:<skill>` with a native `(clouddrove)` label — replacing the per-skill symlink install.
- `install-claude.sh` now runs `claude plugin marketplace add <repo>` + `claude plugin install clouddrove@devops-skills` instead of symlinking each skill. `generate.sh` reads `skills/<name>/SKILL.md`. Install without cloning: `/plugin marketplace add anmolnagpal/devops-skills` then `/plugin install clouddrove@devops-skills`.
- **Hooks ship inside the plugin.** `session-banner` (SessionStart) and `bash-guard` (PreToolUse) are now registered via `hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}`, so they travel with the plugin. `install-claude.sh` migrates older installs: removes the standalone `~/.claude/hooks/devops-skills` symlinks and strips their stale `settings.json` entries so hooks don't double-fire. Template `settings.json` no longer wires hooks.
- **Skill frontmatter lint** (`scripts/check-skills.sh`, new CI job): asserts every `skills/<name>/SKILL.md` has a `name` matching its directory and a non-empty `description`. Fixed `owasp` whose `name` was `owasp-security`.
- Renamed the `clouddrove-tf` skill to **`wrapper-tf`** → `/clouddrove:wrapper-tf` (no more redundant `/clouddrove:clouddrove-tf`). `CDTF-*` rule IDs unchanged.

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
