# Trigger-phrase evals: case-study

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers case-study`.

## Should load

- "write a case study for Wellnest"
- "turn this project into a case study"
- "review this case study before we publish it"
- "is this case study ready to ship"
- "draft a customer story from these weekly reports"
- "check the numbers in this client story"

## Should not load

- "write a postmortem for last night's outage" → `incident`, that is an internal
  incident write-up, not a marketing study
- "record why we chose EKS over ECS" → `adr`
- "write a runbook for this service" → `incident`
