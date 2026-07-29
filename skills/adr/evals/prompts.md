# Trigger-phrase evals: adr

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers adr`.

## Should load

- "record why we chose EKS over ECS"
- "write an ADR for this decision"
- "document this architecture decision"
- "we decided to move to Aurora, capture it"

## Should not load

- "should we use EKS or ECS?" → this records decisions, it does not make them
- "write a postmortem" → `incident`
