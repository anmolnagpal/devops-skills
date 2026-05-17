#!/usr/bin/env bash
# Claude Code adapter: links skills, registers marketplaces, installs plugins, sets up MCP.
set -euo pipefail

NO_MCP=0
NO_PLUGINS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-mcp)     NO_MCP=1 ;;
    --no-plugins) NO_PLUGINS=1 ;;
    *) echo "install-claude.sh: unknown flag $1" >&2; exit 1 ;;
  esac
  shift
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
MARKETPLACES_FILE="$REPO/config/marketplaces.txt"
PLUGINS_FILE="$REPO/config/plugins.txt"
KNOWN_MARKETPLACES="$HOME/.claude/plugins/known_marketplaces.json"
INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"

echo "[claude]"

# ── Hook scripts ──────────────────────────────────────────────────────────────
HOOKS_DEST="$HOME/.claude/hooks/devops-skills"
mkdir -p "$HOOKS_DEST"
if [ -d "$REPO/hooks" ]; then
  for f in "$REPO/hooks/"*.sh; do
    [ -f "$f" ] || continue
    ln -sf "$f" "$HOOKS_DEST/$(basename "$f")"
  done
  echo "  hooks: linked → $HOOKS_DEST"
fi

# ── Global settings.json ──────────────────────────────────────────────────────
SETTINGS_FILE="$HOME/.claude/settings.json"
TEMPLATE_SETTINGS="$REPO/templates/settings.json"
mkdir -p "$HOME/.claude"
if [ -f "$TEMPLATE_SETTINGS" ]; then
  if [ ! -f "$SETTINGS_FILE" ]; then
    cp "$TEMPLATE_SETTINGS" "$SETTINGS_FILE"
    echo "  settings: seeded $SETTINGS_FILE from template"
  else
    python3 - "$SETTINGS_FILE" "$TEMPLATE_SETTINGS" <<'PY'
import json, sys
target, template = sys.argv[1], sys.argv[2]
with open(target) as f: cur = json.load(f)
with open(template) as f: tpl = json.load(f)
changed = False

# Merge enabledPlugins + extraKnownMarketplaces (additive, don't overwrite user values).
for top_key in ("enabledPlugins", "extraKnownMarketplaces"):
    tpl_block = tpl.get(top_key) or {}
    if not tpl_block: continue
    cur_block = cur.setdefault(top_key, {})
    for k, v in tpl_block.items():
        if k not in cur_block:
            cur_block[k] = v
            changed = True

# Merge permission allow/deny (additive, dedup).
perms = cur.setdefault("permissions", {})
tpl_perms = tpl.get("permissions", {})
for key in ("allow", "deny"):
    existing = perms.setdefault(key, [])
    seen = set(existing)
    for item in tpl_perms.get(key, []):
        if item not in seen:
            existing.append(item)
            seen.add(item)
            changed = True

# Merge hooks: append our hook commands without clobbering existing user hooks.
# A hook command is identified by its `command` string; skip if already present.
def hook_commands(group_list):
    cmds = set()
    for group in group_list or []:
        for h in group.get("hooks", []) or []:
            c = h.get("command")
            if c: cmds.add(c)
    return cmds

cur_hooks = cur.setdefault("hooks", {})
for event, tpl_groups in (tpl.get("hooks") or {}).items():
    cur_groups = cur_hooks.setdefault(event, [])
    existing_cmds = hook_commands(cur_groups)
    for tpl_group in tpl_groups:
        new_hooks = [h for h in tpl_group.get("hooks", []) if h.get("command") not in existing_cmds]
        if new_hooks:
            merged_group = {k: v for k, v in tpl_group.items() if k != "hooks"}
            merged_group["hooks"] = new_hooks
            cur_groups.append(merged_group)
            changed = True

if changed:
    with open(target, "w") as f:
        json.dump(cur, f, indent=2)
    print("  settings: merged template entries into", target)
else:
    print("  settings: already up-to-date")
PY
  fi
fi

# ── Skills ────────────────────────────────────────────────────────────────────
mkdir -p "$SKILLS_DIR"
count=0
for f in "$REPO/skills/"*.md; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$SKILLS_DIR/$(basename "$f")"
  echo "  skill: /$(basename "$f" .md)"
  count=$((count + 1))
done
echo "  $count skill(s) linked → $SKILLS_DIR"

# ── Agents ────────────────────────────────────────────────────────────────────
mkdir -p "$AGENTS_DIR"
count=0
for f in "$REPO/agents/"*.md; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$AGENTS_DIR/$(basename "$f")"
  echo "  agent: $(basename "$f" .md)"
  count=$((count + 1))
done
[ "$count" -gt 0 ] && echo "  $count agent(s) linked → $AGENTS_DIR"

if [[ $NO_PLUGINS -eq 0 ]]; then
  # ── Runtime deps ────────────────────────────────────────────────────────────
  # claude-mem plugin needs Bun. Install if missing.
  echo ""
  echo "Plugin runtime dependencies:"
  if command -v bun >/dev/null 2>&1; then
    echo "  bun — already installed ($(bun --version))"
  else
    case "$(uname -s)" in
      Darwin)
        if command -v brew >/dev/null 2>&1; then
          echo "  installing bun via brew ..."
          brew install oven-sh/bun/bun
        else
          echo "  installing bun via curl ..."
          curl -fsSL https://bun.sh/install | bash
          export PATH="$HOME/.bun/bin:$PATH"
        fi ;;
      Linux)
        echo "  installing bun via curl ..."
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH" ;;
      *)
        echo "  WARN: unknown OS — install bun manually: https://bun.sh" ;;
    esac
  fi

  # ── Marketplaces ────────────────────────────────────────────────────────────
  echo ""
  echo "Plugin marketplaces:"
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    marketplace="$line"
    marketplace_key="${marketplace%%/*}"

    if [ -f "$KNOWN_MARKETPLACES" ] && python3 -c "
import json, sys
data = json.load(open('$KNOWN_MARKETPLACES'))
sys.exit(0 if '$marketplace_key' in data else 1)
" 2>/dev/null; then
      echo "  $marketplace — already added, skipping"
    else
      echo "  adding marketplace $marketplace ..."
      claude plugin marketplace add "$marketplace"
    fi
  done < "$MARKETPLACES_FILE"

  # ── Plugins ─────────────────────────────────────────────────────────────────
  echo ""
  echo "Plugins:"
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    if [[ "$line" == hub:* ]]; then
      repo="${line#hub:}"
      plugin="${repo##*/}"
      if [ -f "$INSTALLED_PLUGINS" ] && python3 -c "
import json, sys
data = json.load(open('$INSTALLED_PLUGINS'))
sys.exit(0 if any('$plugin' in k for k in data.get('plugins', {})) else 1)
" 2>/dev/null; then
        echo "  $plugin — already installed, skipping"
      else
        echo "  installing $plugin (hub: $repo) ..."
        npx claudepluginhub "$repo" --plugin "$plugin"
      fi
    else
      plugin="$line"
      if [ -f "$INSTALLED_PLUGINS" ] && python3 -c "
import json, sys
data = json.load(open('$INSTALLED_PLUGINS'))
sys.exit(0 if '$plugin' in data.get('plugins', {}) else 1)
" 2>/dev/null; then
        echo "  $plugin — already installed, skipping"
      else
        echo "  installing $plugin ..."
        claude plugin install "$plugin"
      fi
    fi
  done < "$PLUGINS_FILE"
else
  echo "  --no-plugins: skipping marketplaces + plugins"
fi

# ── MCP servers ───────────────────────────────────────────────────────────────
if [[ $NO_MCP -eq 0 ]]; then
  source "$REPO/scripts/mcp.sh"
else
  echo "  --no-mcp: skipping MCP server setup"
fi
