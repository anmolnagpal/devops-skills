#!/usr/bin/env bash
# devops-skills installer — dispatches per-tool installers based on flags.
#
# Usage:
#   install.sh [--claude] [--cursor] [--codex] [--all]
#              [--global | --project <path>]
#              [--no-mcp] [--no-plugins]
#
# Default (no flags): interactive prompt.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

TOOLS=()
SCOPE="global"
TARGET=""
NO_MCP=0
NO_PLUGINS=0

usage() {
  cat <<EOF
devops-skills installer

Usage: install.sh [TOOLS] [SCOPE] [OPTIONS]

Tools (pick one or more):
  --claude        Install for Claude Code (skills + plugins + MCP)
  --cursor        Install Cursor rules (.cursor/rules/*.mdc)
  --codex         Install Codex AGENTS.md
  --all           All of the above

Scope (applies to --cursor and --codex):
  --global        Install into \$HOME (~/.cursor/rules, ~/.codex/AGENTS.md)  [default]
  --project PATH  Install into a project dir (PATH/.cursor/rules, PATH/AGENTS.md)

Options:
  --no-mcp        Skip MCP server prompts (Claude only)
  --no-plugins    Skip plugin/marketplace install (Claude only)
  -h, --help      Show this help

Examples:
  install.sh --all
  install.sh --claude --no-mcp
  install.sh --cursor --project ~/work/myrepo
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)  TOOLS+=("claude") ;;
    --cursor)  TOOLS+=("cursor") ;;
    --codex)   TOOLS+=("codex") ;;
    --all)     TOOLS=(claude cursor codex) ;;
    --global)  SCOPE="global" ;;
    --project) SCOPE="project"; TARGET="${2:-}"; shift ;;
    --no-mcp)     NO_MCP=1 ;;
    --no-plugins) NO_PLUGINS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# Interactive fallback
if [[ ${#TOOLS[@]} -eq 0 ]]; then
  echo "devops-skills installer"
  echo "Select tools (space-separated): claude cursor codex all"
  read -r -p "> " line
  if [[ "$line" == "all" ]]; then
    TOOLS=(claude cursor codex)
  else
    # shellcheck disable=SC2206
    TOOLS=($line)
  fi
fi

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  echo "no tools selected (pick one or more: --claude --cursor --codex --all)" >&2
  exit 1
fi

if [[ "$SCOPE" == "project" && -z "$TARGET" ]]; then
  echo "--project requires a path" >&2
  exit 1
fi

echo "devops-skills install"
echo "---------------------"
echo "tools : ${TOOLS[*]}"
echo "scope : $SCOPE ${TARGET:+($TARGET)}"
echo ""

for t in "${TOOLS[@]}"; do
  case "$t" in
    claude)
      args=()
      [[ $NO_MCP -eq 1 ]]     && args+=(--no-mcp)
      [[ $NO_PLUGINS -eq 1 ]] && args+=(--no-plugins)
      # ${args[@]+...} guard: on macOS bash 3.2, "${args[@]}" on an empty array
      # trips `set -u` with "unbound variable". This form expands to nothing.
      bash "$REPO/scripts/install-claude.sh" ${args[@]+"${args[@]}"}
      ;;
    cursor)
      bash "$REPO/scripts/install-cursor.sh" --scope "$SCOPE" ${TARGET:+--target "$TARGET"}
      ;;
    codex)
      bash "$REPO/scripts/install-codex.sh" --scope "$SCOPE" ${TARGET:+--target "$TARGET"}
      ;;
    *)
      echo "unknown tool: $t" >&2; exit 1 ;;
  esac
done

echo ""
echo "Done."
