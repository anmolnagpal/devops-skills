# Trigger-phrase evals: k8s

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers k8s`.

## Should load

- "review my helm values before I deploy"
- "check values-prod.yaml"
- "scaffold a new service chart"
- "is this pod running as root?"
- "does this deployment have enough replicas for prod?"

## Should not load

- "why did Argo delete my resources?" → `gitops`
- "am I ready to ship this to prod?" → `deploy`, that is the readiness gate
