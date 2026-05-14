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
