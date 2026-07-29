# Trigger-phrase evals: appsec

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers appsec`.

## Should load

- "run a dependency audit"
- "check for vulnerable packages"
- "are my security headers set?"
- "review my CORS config"
- "is this lockfile carrying any CVEs?"

## Should not load

- "is this auth logic secure?" → `owasp`, that needs judgment not a tool
- "review this crypto implementation" → `owasp`
