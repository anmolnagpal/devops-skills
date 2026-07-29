# Trigger-phrase evals: owasp

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers owasp`.

## Should load

- "is this authentication implementation secure?"
- "review this endpoint for injection"
- "check how we store secrets in this service"
- "review this agent code for prompt injection"
- "what ASVS level 2 requirements apply here?"

## Should not load

- "run a dependency audit" → `appsec`, that has a deterministic answer
- "are my security headers set?" → `appsec`
