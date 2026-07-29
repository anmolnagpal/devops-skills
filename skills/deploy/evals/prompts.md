# Trigger-phrase evals: deploy

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers deploy`.

## Should load

- "am I ready to ship this to prod?"
- "blue-green or canary for this service?"
- "write me a rollback plan"
- "is this safe for a first production release?"
- "what is missing before we go live?"

## Should not load

- "review my helm values" → `k8s`, the artifact rather than the gate
- "write a runbook" → `incident`
