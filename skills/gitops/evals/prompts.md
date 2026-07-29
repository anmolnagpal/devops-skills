# Trigger-phrase evals: gitops

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers gitops`.

## Should load

- "review my Argo CD Applications"
- "why did Argo delete my namespace?"
- "check this AppProject for over-granted access"
- "review my Flux Kustomizations"
- "is my targetRevision safe for prod?"

## Should not load

- "review my helm values" → `k8s`, the chart rather than the controller
- "review my deploy workflow" → `github-actions` or `ci`
