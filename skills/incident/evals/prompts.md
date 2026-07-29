# Trigger-phrase evals: incident

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers incident`.

## Should load

- "write a runbook for the checkout API"
- "are we ready to put this service on-call?"
- "which alerts are missing runbooks?"
- "write a postmortem from this timeline"
- "define severity levels for our team"

## Should not load

- "do my alerts reach anyone?" → `observability`, that is the detection side
- "review my monitoring config" → `observability`
