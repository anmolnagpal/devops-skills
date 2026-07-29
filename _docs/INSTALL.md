# Installing

Six paths, depending on which tools your team uses and how you want the repo pinned.
The [README](../README.md) shows the two most common; this covers all of them.

Works with **Claude Code**, **Cursor**, and **Codex** (same skills, different injection per tool). Six paths. The first two cover almost everyone.

### 1. Claude Code plugin (no clone)

```text
/plugin marketplace add anmolnagpal/devops-skills
/plugin install clouddrove@devops-skills
```

Skills appear as `/clouddrove:tf`, `/clouddrove:deploy`, … Does not install Cursor rules, Codex `AGENTS.md`, team plugins, or MCP servers.

### 2. Installer one-liner (recommended, all tools)

```bash
# Claude Code only
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)" -- --claude

# All three tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)" -- --all

# Interactive (no flags): prompts for which tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)"
```

| Flag | What it installs |
|------|------------------|
| `--claude` | `clouddrove` skills plugin (from this repo's marketplace), team plugins from `config/plugins.txt`, MCP servers |
| `--cursor` | `.cursor/rules/*.mdc` into `~/.cursor/rules/` (or `--project <path>`) |
| `--codex`  | `AGENTS.md` into `~/.codex/AGENTS.md` (or `--project <path>`) |
| `--all`    | All three |

Narrower runs:

```bash
./scripts/install.sh --claude --no-mcp --no-plugins   # skills only
./scripts/install.sh --cursor --project ~/work/repo   # per-project install
./scripts/install.sh --codex  --project ~/work/repo
```

**Updating:** re-run the same one-liner. If the repo is already installed it pulls the latest and re-runs the installer.

### 3. `npx skills` (any of 70+ agents)

The [open Agent Skills CLI](https://github.com/vercel-labs/skills) reads this repo directly, so tools outside Claude/Cursor/Codex can consume the same skills:

```bash
npx skills add anmolnagpal/devops-skills --list          # show the 17 skills
npx skills add anmolnagpal/devops-skills -s tf,k8s       # install two
npx skills add anmolnagpal/devops-skills --all           # all skills, all detected agents
npx skills add anmolnagpal/devops-skills -g              # user-level instead of project-level
```

Installs the skill bodies only. Team plugins, MCP servers, and the settings template need path 2.

### 4. Clone (SSH, or a custom install dir)

```bash
git clone git@github.com:anmolnagpal/devops-skills.git ~/devops-skills
~/devops-skills/scripts/install.sh --all
```

### 5. Git submodule (pin a version per project repo)

Best when a project needs a reproducible skill set that moves only when you bump it:

```bash
git submodule add https://github.com/anmolnagpal/devops-skills .devops-skills
git -C .devops-skills checkout v1.2.0            # pin a release (see releases page)
./.devops-skills/scripts/install.sh --cursor --codex --project .
git add .gitmodules .devops-skills .cursor AGENTS.md
```

Teammates get it with `git submodule update --init`. Bump with `git -C .devops-skills fetch --tags && git -C .devops-skills checkout <tag>`, then re-run the installer.

### 6. Fork and customize (your own rule catalog)

For teams that need different severities, extra rule IDs, or company-specific skills:

1. Fork the repo.
2. Edit `rules/rule-ids.yaml` and `skills/<name>/SKILL.md`.
3. Run `bash scripts/generate.sh` (rebuilds Cursor + Codex adapters).
4. Point Claude Code at your fork: `/plugin marketplace add <your-org>/devops-skills`.

CI carries over with the fork, so your changes keep the same six gates. Merge upstream with `git remote add upstream https://github.com/anmolnagpal/devops-skills`.


### What the installer writes to your machine

`install.sh --claude` seeds `~/.claude/settings.json` from `templates/settings.json` on first run. On subsequent runs it **merges missing permission entries only**; it never clobbers existing keys (`enabledPlugins`, `mcpServers`, `hooks`, …).

The template ships a safe DevOps allow-list (read-only kubectl/terraform/aws/git) and a deny-list (`kubectl delete`, `terraform apply`, `terraform destroy`, `rm -rf`, `aws s3 rm`, `aws ec2 terminate-instances`). The plugin also registers two hooks: a `SessionStart` context banner and a `PreToolUse` bash-guard that blocks destructive commands.

`install.sh` is idempotent: already-installed plugins, MCP servers, and symlinks are reused.
