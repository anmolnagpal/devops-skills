#!/usr/bin/env bash
# Codex adapter: install generated AGENTS.md into target location.
#
#   --scope global              → ~/.codex/AGENTS.md  (default)
#   --scope project --target X  → X/AGENTS.md
#
# Symlinked so updates flow through after `git pull && scripts/generate.sh`.

set -euo pipefail

SCOPE="global"
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)  SCOPE="$2"; shift ;;
    --target) TARGET="$2"; shift ;;
    *) echo "install-codex.sh: unknown flag $1" >&2; exit 1 ;;
  esac
  shift
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/AGENTS.md"

if [[ ! -f "$SRC" ]]; then
  echo "[codex] $SRC missing — run scripts/generate.sh first" >&2
  exit 1
fi

case "$SCOPE" in
  global)
    mkdir -p "$HOME/.codex"
    DEST="$HOME/.codex/AGENTS.md" ;;
  project)
    [[ -z "$TARGET" ]] && { echo "--scope project requires --target"; exit 1; }
    mkdir -p "$TARGET"
    DEST="$TARGET/AGENTS.md" ;;
  *) echo "invalid --scope: $SCOPE" >&2; exit 1 ;;
esac

# Back up an existing non-symlink AGENTS.md so we don't clobber user content
if [[ -f "$DEST" && ! -L "$DEST" ]]; then
  cp "$DEST" "$DEST.bak.$(date +%s)"
  echo "[codex] existing $DEST backed up"
fi

ln -sf "$SRC" "$DEST"
echo "[codex] $SRC → $DEST"
