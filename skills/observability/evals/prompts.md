# Trigger-phrase evals: observability

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers observability`.

## Should load

- "review my monitoring setup"
- "am I flying blind on this service?"
- "do my alerts actually reach anyone?"
- "define an SLO for payments-api"
- "check my log retention"

## Should not load

- "write a runbook for this alert" → `incident`, that is the response side
- "are we ready for on-call?" → `incident`
