# Trigger-phrase evals: tf-plan

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers tf-plan`.

## Should load

- "is this plan safe to apply to prod?"
- "what will this apply destroy?"
- "why is it replacing aws_db_instance.main?"
- "review tfplan.json"
- "does my pipeline apply the plan it reviewed?"

## Should not load

- "review my terraform files" → `tf`, that is source not a plan
- "scaffold a new module" → `tf` or `wrapper-tf`, this skill only reads plans
