# Trigger-phrase evals: finops

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers finops`.

## Should load

- "where is my AWS bill going?"
- "why did costs jump last month?"
- "find idle resources I can delete"
- "should I buy savings plans or reserved instances?"
- "what is my EKS cluster actually costing?"

## Should not load

- "reduce my Docker image size" → `docker`, size is not spend
- "set resource limits on this pod" → `k8s`
