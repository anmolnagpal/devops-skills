# Contributing

Thanks for your interest. This repo is a community-friendly collection of DevOps skills for AI coding tools — issues and PRs are welcome.

**Contents:** [Add or improve a skill](#add-or-improve-a-skill) · [Skill file format](#skill-file-format) · [Add a rule ID](#add-a-rule-id) · [Eval cases](#eval-cases) · [Testing](#testing) · [Add a plugin](#add-a-plugin) · [Add an MCP server](#add-an-mcp-server) · [Promote a backlog spec](#promote-a-backlog-spec) · [Open a pull request](#open-a-pull-request)

## Setup

One-time dependency for the generator and checks:

```bash
pip3 install --break-system-packages pyyaml   # macOS Homebrew Python
pip install pyyaml                            # other environments
```

## Add or improve a skill

1. Skills live in `skills/<name>/SKILL.md` (single canonical source; one directory per skill, with `evals/` and references co-located). They ship as the `clouddrove` plugin.
2. Frontmatter must include `name`, `description`, `metadata`, and `paths` (when the skill should auto-trigger on file globs).
3. Body follows the [skill file format](#skill-file-format) below: a short purpose paragraph, a Keywords section, an Output Artifacts table, then one section per mode (REVIEW / NEW / …).
4. Register any new rule IDs in `rules/rule-ids.yaml` **before** using them in the skill's Rule Catalog. See [Add a rule ID](#add-a-rule-id).
5. Add [eval cases](#eval-cases) under `skills/<name>/evals/cases/`.
6. Use `/clouddrove:skill-creator` (this repo) to iterate on the skill and run evals.
7. Run `bash scripts/generate.sh` — this rebuilds `.cursor/rules/<name>.mdc` and `AGENTS.md` from your source.
8. Commit `skills/<name>/SKILL.md`, any registry change, the new `.cursor/rules/<name>.mdc`, and the updated `AGENTS.md`.
9. Add the skill to the right category table in `README.md`, and to the relationship diagram if it consumes or is consumed by another skill.
10. Add a `CHANGELOG.md` entry under `## [Unreleased]`.

### Skill file format

```markdown
---
name: skill-name
description: "Concise description — include when to use and key trigger keywords"
metadata:
  version: 1.0.0
  author: Your Name
  category: devops
  updated: YYYY-MM-DD
paths:                    # optional: auto-trigger on these globs
  - "**/*.tf"
allowed-tools:            # optional: review skills use Glob + Read only (no writes)
  - Glob
  - Read
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

Review skills produce the standard output shape:

```
BLOCKING — Must fix before [MR/deploy/merge]
[file:line] RULE-ID Issue → recommendation

ADVISORY — Should fix
[file:line] RULE-ID Issue → recommendation

Summary: X blocking issue(s), Y advisory issue(s).
```

Three severity models exist (catalog-fixed, judged-per-finding, and dollar-impact). Pick the one that matches your skill and say which in the skill body; see the table in `README.md`.

## Add a rule ID

`rules/rule-ids.yaml` is the canonical vocabulary for every finding ID a skill can emit, shared with the [auditkit](https://github.com/clouddrove-ci/auditkit) audit engine.

1. Format is `DOMAIN-CATEGORY-NNN` (e.g. `TF-STATE-001`, `SEC-IAM-003`, `COST-NET-001`).
2. Add the ID to `rules/rule-ids.yaml` under the matching domain, with its severity and a one-line meaning.
3. Only then reference it in a skill's Rule Catalog. `scripts/check-rule-ids.sh` (and CI) reject unknown IDs.
4. Framework and compliance IDs (`SOC2-*`, `CIS-*`, `NIST-*`, …) are exempt and pass without a registry entry.

An ID's meaning is a public contract. Do not repurpose an existing ID for a different check; add a new one and note any removal in `CHANGELOG.md`.

## Eval cases

Review skills ship a `skills/<name>/evals/` folder that proves correctness without running a model:

```
evals/
  cases/
    <case-name>/
      <fixture file>    ← input (e.g. .tf, Dockerfile)
      expected.txt      ← one rule ID per line the skill MUST report; empty = clean pass
  validate.sh           ← copy verbatim from any existing skill (e.g. skills/tf/evals/validate.sh)
```

`validate.sh` asserts every ID in `expected.txt` exists in the skill's Rule Catalog, and that `clean-*` cases have an empty `expected.txt`. Run it with `bash skills/<name>/evals/validate.sh`.

Include at least one `clean-*` case (a fixture that must produce zero findings) alongside the violation cases; that is what catches false positives.

## Testing

Run the same checks CI runs, before you push:

```bash
bash scripts/check-skills.sh             # lint: name/description frontmatter
bash scripts/check-rule-ids.sh           # every rule ID in skills/ exists in the registry
bash scripts/check-evals.sh              # eval fixtures reference only known rule IDs
bash scripts/generate.sh --check         # .cursor/rules/ + AGENTS.md are up to date
```

CI runs on every push to `main` and every pull request (`.github/workflows/test.yml`), with six gates:

1. Docker install harness
2. Adapter sync (`.cursor/rules/`, `AGENTS.md` regenerated from `skills/<name>/SKILL.md`)
3. Skill frontmatter lint
4. Rule-ID registry check
5. Eval fixtures (Tier-1)
6. ShellCheck on `scripts/`

The install harness locally (requires Docker):

```bash
bash _test/test.sh
```

It builds `_test/Dockerfile`, which runs `install.sh` in a clean container with a stubbed `claude` CLI and `CI=true` to skip interactive MCP prompts. It verifies all skills install and all plugins resolve without error.

### Behavioral evals (Tier-2, opt-in)

The `eval fixtures` gate above (Tier-1) only checks that eval docs are internally consistent: rule IDs in `expected.txt` exist in the catalog, and `clean-*` cases expect nothing. It never runs a skill against its fixture, so a skill could regress silently (stop detecting a real violation) and Tier-1 would still pass.

`scripts/run-behavioral-evals.sh` is the Tier-2 gate: it invokes each skill via `claude -p` against its fixtures and diffs the live findings against `expected.txt`. It is opt-in because it spends API tokens, so it is not wired into the free six-gate CI. Run it manually or on a nightly schedule:

```bash
EVALS=1 bash scripts/run-behavioral-evals.sh          # every skill with evals/
EVALS=1 bash scripts/run-behavioral-evals.sh tf k8s   # just these skills
```

Run Tier-2 for any skill whose detection logic you changed.

## Add a plugin

Add a line to `config/plugins.txt`:

- `name@marketplace` — for official Claude plugin marketplace installs
- `hub:github-org/repo` — for plugins installed via `npx claudepluginhub`

If it comes from a new marketplace, also add that to `config/marketplaces.txt`. Add a row to the Plugins table in `README.md`, then commit. Teammates pick it up on their next `./scripts/install.sh`.

## Add an MCP server

1. Add an interactive block to `scripts/mcp.sh` following the existing pattern (check if installed → prompt via `_ask` → register). `mcp.sh` is *sourced* by `install.sh`, so it must not use exit semantics that kill the parent shell.
   - **Local/stdio** servers: `claude mcp add-json <name> '{"command":...,"args":...}' -s user`
   - **Remote/HTTP** servers (e.g. `outline`): `claude mcp add <name> <url> --transport http -s user` (auth via browser OAuth on first use)
2. If the server uses AWS credentials, add it to the `AWS_MCP_SERVERS` list in `scripts/set-aws-profile.sh`.
3. Add a row to the MCP Servers table in `README.md` and an example prompt to `_docs/CHEATSHEET.md`.
4. Commit and push. Teammates pick it up on their next `./scripts/install.sh`.

## Promote a backlog spec

`skills/specs/` contains spec drafts that have not been authored as runnable skills yet. To promote one:

1. Pick a spec (e.g. `skills/specs/aws-cost.md`).
2. Create `skills/aws-cost/SKILL.md` with proper frontmatter.
3. Distill the spec into actionable instructions following the [skill file format](#skill-file-format).
4. Register its rule IDs, add eval cases, run `scripts/generate.sh`.
5. Delete the spec file once superseded.

## Open a pull request

- One skill (or one focused fix) per PR. Do not bundle unrelated edits.
- Branch naming: `feat/<name>`, `fix/<name>`, `chore/<name>`, `docs/<name>`. Never push to `main`.
- Commit subject: imperative, ≤72 chars, then a blank line and a body explaining the *why*.
- Include a brief example of the output the skill should produce.
- The `test` workflow fails if generated adapters are out of sync. Fix locally with `scripts/generate.sh`.

## Writing style

- No em dashes or literal double hyphens in skill content, docs, or commit messages. Use commas, periods, or parentheses.
- No filler words (delve, leverage, robust, seamless, utilize, elevate, unlock, …). Plain direct words.
- Check the latest stable version on GitHub releases or the official registry before pinning any dependency, tool, action, or base image. Do not guess from memory.

## Code of conduct

Be kind. Critique ideas, not people. No spam, no off-topic, no sales.

## License

By contributing you agree your work is licensed under the MIT License (see `LICENSE`).
