#!/usr/bin/env bash
# Switch the AWS_PROFILE for all AWS MCP servers in ~/.claude/settings.json
# Usage: ./scripts/set-aws-profile.sh [profile-name]

set -euo pipefail

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
AWS_MCP_SERVERS=("eks-mcp-server" "billing-mcp-server")

if [ ! -f "$CLAUDE_SETTINGS" ]; then
  echo "Error: $CLAUDE_SETTINGS not found"
  exit 1
fi

# Get profile from arg or prompt
if [ $# -ge 1 ]; then
  profile="$1"
else
  printf "AWS profile to use: "
  read -r profile
fi

if [ -z "$profile" ]; then
  echo "Error: profile name cannot be empty"
  exit 1
fi

echo "Switching AWS MCP servers to profile: $profile"

python3 - "$profile" <<'EOF'
import json, sys

settings_path = __import__('os').path.expanduser("~/.claude/settings.json")
profile = sys.argv[1]
servers = ["eks-mcp-server", "billing-mcp-server"]

with open(settings_path) as f:
    data = json.load(f)

mcp = data.get("mcpServers", {})
updated = []

for name in servers:
    if name in mcp:
        mcp[name].setdefault("env", {})["AWS_PROFILE"] = profile
        updated.append(name)

data["mcpServers"] = mcp

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)

if updated:
    for name in updated:
        print(f"  {name} → {profile}")
else:
    print("  No AWS MCP servers found in settings.json (have you run install.sh?)")
EOF

echo ""
echo "Done. Restart Claude Code for the change to take effect."
