FROM node:26-slim

RUN apt-get update && apt-get install -y python3 python3-yaml git bash curl ca-certificates unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY . .

# Stub the claude CLI — logs every call so we can assert on them.
RUN printf '#!/bin/bash\necho "  [stub claude] $@"\necho "$@" >> /tmp/claude-calls.log\nexit 0\n' \
      > /usr/local/bin/claude && chmod +x /usr/local/bin/claude

# Stub brew so install-claude.sh's Bun install branch is a no-op (Linux path
# uses curl; this just makes the bun command available before plugins run).
RUN printf '#!/bin/bash\necho "  [stub bun] $@"\nexit 0\n' \
      > /usr/local/bin/bun && chmod +x /usr/local/bin/bun

# Pre-create plugin state files (normally created by claude CLI on first run).
RUN mkdir -p /root/.claude/plugins && \
    echo '{}' > /root/.claude/plugins/known_marketplaces.json && \
    echo '{"plugins":{}}' > /root/.claude/plugins/installed_plugins.json && \
    echo '{"mcpServers":{}}' > /root/.claude/settings.json

# Run the installer for Claude only — CI=true skips interactive MCP prompts.
RUN CI=true bash scripts/install.sh --claude

# ── Verify skills ──────────────────────────────────────────────────────────────
RUN echo "" && echo "── Skills ──" && \
    for skill in tf k8s ci owasp skill-creator docker finops github github-actions; do \
      [ -L "/root/.claude/skills/$skill/SKILL.md" ] \
        && echo "  ✓ $skill/SKILL.md" \
        || (echo "  ✗ $skill/SKILL.md MISSING" && exit 1); \
    done

# ── Verify install.sh called claude with the right arguments ───────────────────
RUN echo "" && echo "── Claude CLI calls ──" && \
    for expected in \
      "plugin marketplace add hashicorp/agent-skills" \
      "plugin marketplace add thedotmack/claude-mem" \
      "plugin marketplace add mhattingpete/claude-skills-marketplace" \
      "plugin marketplace add JuliusBrussee/caveman" \
      "plugin install terraform-code-generation@hashicorp" \
      "plugin install terraform-module-generation@hashicorp" \
      "plugin install claude-mem@thedotmack" \
      "plugin install engineering-workflow-skills@mhattingpete-claude-skills" \
      "plugin install superpowers@claude-plugins-official" \
      "plugin install caveman@caveman"; \
    do \
      grep -qF "$expected" /tmp/claude-calls.log \
        && echo "  ✓ claude $expected" \
        || (echo "  ✗ claude $expected — NOT called" && exit 1); \
    done

# ── Verify generator + adapters in sync ────────────────────────────────────────
RUN pip3 install --break-system-packages pyyaml 2>/dev/null || apt-get update && apt-get install -y python3-yaml
RUN bash scripts/generate.sh && \
    git config --global --add safe.directory /repo && \
    if [ -d .git ]; then \
      if ! git diff --quiet .cursor/rules AGENTS.md 2>/dev/null; then \
        echo "  ✗ adapters drift" && git --no-pager diff .cursor/rules AGENTS.md && exit 1; \
      fi; \
    fi && \
    echo "  ✓ adapters in sync"

RUN echo "" && echo "All checks passed."
