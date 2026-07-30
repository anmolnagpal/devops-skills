# Trigger-phrase evals: skill-creator

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers skill-creator`.

## Should load

- "help me build a new skill"
- "add a skill for reviewing Ansible"
- "run the evals for the tf skill"
- "my skill is not triggering, fix the description"
- "improve this skill's rule catalog"
- "add a rule ID"

## Should not load

- "review my terraform" → `tf`, this builds skills rather than using them
- "review my helm values" → `k8s`, same boundary
