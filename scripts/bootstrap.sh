#!/usr/bin/env bash
#
# devops-skills bootstrap
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)"
#
set -euo pipefail

REPO_URL="https://github.com/anmolnagpal/devops-skills.git"
INSTALL_DIR="$HOME/devops-skills"

echo ""
echo "devops-skills bootstrap"
echo "-----------------------"

# ── Clone or update ───────────────────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "Already installed at $INSTALL_DIR — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  # Allow custom install directory
  printf "Install to [$INSTALL_DIR]: "
  read -r custom_dir </dev/tty
  if [ -n "$custom_dir" ]; then
    INSTALL_DIR="${custom_dir/#\~/$HOME}"
  fi

  echo "Cloning into $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── Run install ───────────────────────────────────────────────────────────────
echo ""
# Forward any flags passed via `bash -s -- --claude --cursor ...`
bash "$INSTALL_DIR/scripts/install.sh" "$@"
