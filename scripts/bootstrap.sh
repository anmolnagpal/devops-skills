#!/usr/bin/env bash
#
# devops-skills bootstrap
#
# Interactive (TTY) — prompts for install dir, defaults to ~/devops-skills:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)"
#
# Non-interactive (CI, ssh without -t) — uses default install dir:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/anmolnagpal/devops-skills/main/scripts/bootstrap.sh)" -- --claude
#
# Override install dir explicitly (works in any mode):
#   ... bootstrap.sh)" -- --install-dir ~/custom --claude
#
# Any remaining flags are forwarded to scripts/install.sh.

set -euo pipefail

REPO_URL="https://github.com/anmolnagpal/devops-skills.git"
INSTALL_DIR="$HOME/devops-skills"

# Pull out --install-dir before forwarding remaining flags to install.sh.
INSTALL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      INSTALL_DIR="${2:-}"
      INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
      shift 2 ;;
    *)
      INSTALL_ARGS+=("$1")
      shift ;;
  esac
done

echo ""
echo "devops-skills bootstrap"
echo "-----------------------"

# ── Clone or update ───────────────────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "Already installed at $INSTALL_DIR — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  # Prompt for install dir only when a controlling TTY is actually usable.
  # `[ -r /dev/tty ]` lies on macOS: it passes in non-interactive SSH sessions
  # where opening /dev/tty then fails with "Device not configured". Test by
  # actually opening it.
  if [ -t 0 ]; then
    printf "Install to [%s]: " "$INSTALL_DIR"
    read -r custom_dir || custom_dir=""
    [ -n "$custom_dir" ] && INSTALL_DIR="${custom_dir/#\~/$HOME}"
  elif { : </dev/tty; } 2>/dev/null; then
    printf "Install to [%s]: " "$INSTALL_DIR"
    read -r custom_dir </dev/tty || custom_dir=""
    [ -n "$custom_dir" ] && INSTALL_DIR="${custom_dir/#\~/$HOME}"
  else
    echo "No TTY detected — using default install dir: $INSTALL_DIR"
    echo "(Pass --install-dir <path> before --claude/--cursor/--codex to override.)"
  fi

  echo "Cloning into $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── Run install ───────────────────────────────────────────────────────────────
echo ""
# ${INSTALL_ARGS[@]+...} guard: on macOS bash 3.2, "${INSTALL_ARGS[@]}" on an
# empty array trips `set -u` with "unbound variable". This form expands to nothing.
bash "$INSTALL_DIR/scripts/install.sh" ${INSTALL_ARGS[@]+"${INSTALL_ARGS[@]}"}
