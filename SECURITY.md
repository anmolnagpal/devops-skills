# Security Policy

## Reporting a vulnerability

If you find a security issue in this repo (skills that could exfiltrate data, install scripts that elevate privilege incorrectly, or examples that demonstrate insecure patterns as recommended), please **do not open a public issue**.

Email **anmol@clouddrove.com** with:

- A short description of the issue
- Steps to reproduce
- The minimum context needed (file paths, lines)

I'll acknowledge within 7 days and aim to publish a fix within 30 days.

## Scope

In scope:
- Install scripts (`scripts/`)
- Skill content that could lead a user to insecure code
- Bundled MCP/plugin configuration

Out of scope:
- Vulnerabilities in upstream tools (Claude Code, Cursor, Codex, listed plugins, MCP servers) — please report to their maintainers
- Theoretical issues without a working reproduction

## Disclosure

I prefer coordinated disclosure. Public details will only be published after a fix lands.
