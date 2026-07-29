# Trigger-phrase evals: wrapper-tf

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers wrapper-tf`.

## Should load

- "review the modules under _modules/"
- "scaffold a new wrapper module for elasticache"
- "does this follow our wrapper pattern?"
- "generate the terraform CI workflow for this repo"
- "map these modules to SOC2 controls"

## Should not load

- "review my terraform" in a repo with no `_modules/` directory → `tf`
- "why is the plan replacing my database?" → `tf-plan`
