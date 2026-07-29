# Trigger-phrase evals: tf

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers tf`.

## Should load

- "review my terraform before I raise the MR"
- "check my .tf files"
- "scaffold an RDS instance with encryption"
- "upgrade the aws provider, what breaks?"
- "is my backend configured properly?"

## Should not load

- "is this plan safe to apply?" → `tf-plan`, the plan is a different artifact
- "review the modules under _modules/" → `wrapper-tf`, that is the wrapper pattern
- "review my infra" → ask which artifact, load nothing
