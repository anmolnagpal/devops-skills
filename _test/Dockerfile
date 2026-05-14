FROM node:20-slim

RUN apt-get update && apt-get install -y python3 git bash && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY . .

# Stub the claude CLI — logs every call so we can assert on them.
RUN printf '#!/bin/bash\necho "  [stub claude] $@"\necho "$@" >> /tmp/claude-calls.log\nexit 0\n' \
      > /usr/local/bin/claude && chmod +x /usr/local/bin/claude

# Pre-create plugin state files (normally created by claude CLI on first run).
RUN mkdir -p /root/.claude/plugins && \
    echo '{}' > /root/.claude/plugins/known_marketplaces.json && \
    echo '{"plugins":{}}' > /root/.claude/plugins/installed_plugins.json && \
    echo '{"mcpServers":{}}' > /root/.claude/settings.json

# Run the installer — CI=true skips all interactive MCP prompts.
RUN CI=true bash scripts/install.sh

# ── Verify skills ──────────────────────────────────────────────────────────────
RUN echo "" && echo "── Skills ──" && \
    for skill in tf k8s ci owasp skill-creator; do \
      [ -L "/root/.claude/skills/$skill.md" ] \
        && echo "  ✓ $skill.md" \
        || (echo "  ✗ $skill.md MISSING" && exit 1); \
    done

# ── Verify install.sh called claude with the right arguments ───────────────────
RUN echo "" && echo "── Claude CLI calls ──" && \
    for expected in \
      "plugin marketplace add mhattingpete/claude-skills-marketplace" \
      "plugin install terraform-code-generation@hashicorp" \
      "plugin install terraform-module-generation@hashicorp" \
      "plugin install claude-mem@thedotmack" \
      "plugin install engineering-workflow-skills@mhattingpete"; \
    do \
      grep -qF "$expected" /tmp/claude-calls.log \
        && echo "  ✓ claude $expected" \
        || (echo "  ✗ claude $expected — NOT called" && exit 1); \
    done

# ── Verify hub plugin ran (claudepluginhub calls claude, which we logged) ───────
RUN echo "" && echo "── Hub plugins ──" && \
    grep -qF "superpowers" /tmp/claude-calls.log \
      && echo "  ✓ claudepluginhub called claude for superpowers" \
      || (echo "  ✗ superpowers install NOT called" && exit 1)

RUN echo "" && echo "All checks passed."
