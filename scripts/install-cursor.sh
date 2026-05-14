#!/usr/bin/env bash
# Cursor adapter: install generated .cursor/rules/*.mdc into target location.
#
#   --scope global              → ~/.cursor/rules/   (default)
#   --scope project --target X  → X/.cursor/rules/
#
# Idempotent: re-running refreshes symlinks/files.

set -euo pipefail

SCOPE="global"
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)  SCOPE="$2"; shift ;;
    --target) TARGET="$2"; shift ;;
    *) echo "install-cursor.sh: unknown flag $1" >&2; exit 1 ;;
  esac
  shift
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/.cursor/rules"

if [[ ! -d "$SRC" || -z "$(ls -A "$SRC" 2>/dev/null)" ]]; then
  echo "[cursor] no rules in $SRC — run scripts/generate.sh first"
  exit 1
fi

case "$SCOPE" in
  global)  DEST="$HOME/.cursor/rules" ;;
  project)
    [[ -z "$TARGET" ]] && { echo "--scope project requires --target"; exit 1; }
    DEST="$TARGET/.cursor/rules" ;;
  *) echo "invalid --scope: $SCOPE" >&2; exit 1 ;;
esac

mkdir -p "$DEST"
echo "[cursor] $SRC → $DEST"

count=0
for f in "$SRC"/*.mdc; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$DEST/$(basename "$f")"
  echo "  rule: $(basename "$f")"
  count=$((count + 1))
done
echo "  $count rule(s) linked"
