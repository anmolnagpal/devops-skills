#!/usr/bin/env bash
set -euo pipefail
# MCP server installations — sourced by install.sh
# Each server prompts the user before installing.

CLAUDE_SETTINGS="$HOME/.claude/settings.json"

_mcp_installed() {
  local name="$1"
  python3 -c "
import json, sys
try:
  data = json.load(open('$CLAUDE_SETTINGS'))
  sys.exit(0 if '$name' in data.get('mcpServers', {}) else 1)
except Exception:
  sys.exit(1)
" 2>/dev/null
}

_ask() {
  # _ask "Question" → returns 0 for yes, 1 for no
  # Non-interactive environments (CI=true, no TTY) auto-skip.
  local prompt="$1" answer=""
  # `[ -e /dev/tty ]` lies on macOS: the node exists but opening it fails with
  # "Device not configured" in non-interactive shells (ssh without -t, and the
  # shells Claude Code spawns). Test by actually opening it, so those runs skip
  # cleanly instead of crashing on the read below.
  if [[ "${CI:-}" == "true" ]] || ! { : </dev/tty; } 2>/dev/null; then
    echo "  (non-interactive — skipping)"
    return 1
  fi
  printf "  %s [y/N] " "$prompt"
  read -r answer </dev/tty || answer=""
  [[ "$answer" =~ ^[Yy]$ ]]
}

echo ""
echo "MCP servers:"

# ── Kubernetes ────────────────────────────────────────────────────────────────
if _mcp_installed "kubernetes-mcp-server"; then
  echo "  kubernetes-mcp-server — already installed, skipping"
elif _ask "Install kubernetes-mcp-server? (live read access to EKS clusters)"; then
  printf "  Kubeconfig path [~/.kube/config]: "
  read -r kubeconfig </dev/tty
  kubeconfig="${kubeconfig:-$HOME/.kube/config}"
  # expand ~ if user typed it literally
  kubeconfig="${kubeconfig/#\~/$HOME}"

  claude mcp add-json kubernetes-mcp-server \
    "{\"command\":\"npx\",\"args\":[\"-y\",\"kubernetes-mcp-server@latest\",\"--read-only\"],\"env\":{\"KUBECONFIG\":\"$kubeconfig\"}}" \
    -s user

  echo "  kubernetes-mcp-server installed (read-only, kubeconfig: $kubeconfig)"
else
  echo "  kubernetes-mcp-server — skipped"
fi

# ── AWS EKS ───────────────────────────────────────────────────────────────────
if _mcp_installed "eks-mcp-server"; then
  echo "  eks-mcp-server — already installed, skipping"
elif _ask "Install eks-mcp-server? (AWS-native EKS ops, diagnostics, CloudWatch logs)"; then
  printf "  AWS region [eu-west-1]: "
  read -r aws_region </dev/tty
  aws_region="${aws_region:-eu-west-1}"

  printf "  AWS profile [default]: "
  read -r aws_profile </dev/tty
  aws_profile="${aws_profile:-default}"

  claude mcp add-json eks-mcp-server \
    "{\"command\":\"uvx\",\"args\":[\"awslabs.eks-mcp-server@latest\"],\"env\":{\"AWS_REGION\":\"$aws_region\",\"AWS_PROFILE\":\"$aws_profile\",\"FASTMCP_LOG_LEVEL\":\"ERROR\"}}" \
    -s user

  echo "  eks-mcp-server installed (read-only, region: $aws_region, profile: $aws_profile)"
  echo "  Tip: to enable write access, add --allow-write to the args in ~/.claude/settings.json"
else
  echo "  eks-mcp-server — skipped"
fi

# ── AWS Billing & Cost ────────────────────────────────────────────────────────
if _mcp_installed "billing-mcp-server"; then
  echo "  billing-mcp-server — already installed, skipping"
elif _ask "Install billing-mcp-server? (Cost Explorer, budgets, savings plan analysis)"; then
  printf "  AWS profile [default]: "
  read -r aws_profile </dev/tty
  aws_profile="${aws_profile:-default}"

  claude mcp add-json billing-mcp-server \
    "{\"command\":\"uvx\",\"args\":[\"awslabs.billing-cost-management-mcp-server@latest\"],\"env\":{\"AWS_PROFILE\":\"$aws_profile\",\"FASTMCP_LOG_LEVEL\":\"ERROR\"}}" \
    -s user

  echo "  billing-mcp-server installed (read-only, profile: $aws_profile)"
else
  echo "  billing-mcp-server — skipped"
fi

# ── Jira / Atlassian ──────────────────────────────────────────────────────────
if _mcp_installed "mcp-atlassian"; then
  echo "  mcp-atlassian — already installed, skipping"
elif _ask "Install mcp-atlassian? (Jira + Confluence — search, create, update issues)"; then
  printf "  Jira URL (e.g. https://yourcompany.atlassian.net): "
  read -r jira_url </dev/tty

  printf "  Cloud or Server/Data Center? [cloud/server, default: server]: "
  read -r jira_type </dev/tty
  jira_type="${jira_type:-server}"

  if [[ "$jira_type" == "server" ]]; then
    printf "  Personal access token: "
    read -r jira_token </dev/tty

    claude mcp add-json mcp-atlassian \
      "{\"command\":\"uvx\",\"args\":[\"mcp-atlassian\"],\"env\":{\"JIRA_URL\":\"$jira_url\",\"JIRA_PERSONAL_TOKEN\":\"$jira_token\"}}" \
      -s user
  else
    printf "  Atlassian email: "
    read -r jira_email </dev/tty

    printf "  API token (from id.atlassian.com/manage-profile/security/api-tokens): "
    read -r jira_token </dev/tty

    claude mcp add-json mcp-atlassian \
      "{\"command\":\"uvx\",\"args\":[\"mcp-atlassian\"],\"env\":{\"JIRA_URL\":\"$jira_url\",\"JIRA_USERNAME\":\"$jira_email\",\"JIRA_API_TOKEN\":\"$jira_token\"}}" \
      -s user
  fi

  echo "  mcp-atlassian installed ($jira_type, url: $jira_url)"
  echo "  Tip: Claude can now search JQL, create issues, add comments, and transition tickets"
else
  echo "  mcp-atlassian — skipped"
fi

# ── Outline (docs / wiki) ─────────────────────────────────────────────────────
if _mcp_installed "outline"; then
  echo "  outline — already installed, skipping"
elif _ask "Install outline? (Outline docs/wiki — search, read, create documents)"; then
  printf "  Outline MCP URL [https://clouddrove.getoutline.com/mcp]: "
  read -r outline_url </dev/tty
  outline_url="${outline_url:-https://clouddrove.getoutline.com/mcp}"

  # Remote HTTP transport; auth is handled via browser OAuth on first use.
  claude mcp add outline "$outline_url" --transport http -s user

  echo "  outline installed (HTTP, url: $outline_url)"
  echo "  Tip: first call opens a browser to authorize; then search/read/create docs"
else
  echo "  outline — skipped"
fi
