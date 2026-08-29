# Trigger-phrase evals: logging

The `description` in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Tier-1 (`scripts/check-prompts.sh`) checks this file is shaped usefully. Tier-2
actually runs it: `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers logging`.

## Should load

- "is audit logging even on for this cluster?"
- "review my k8s audit policy"
- "are we capturing API-server access on GKE?"
- "check whether AKS is shipping kube-audit logs"
- "review our audit logging posture across the cloud"
- "is our CloudWatch audit log group encrypted with a CMK?"

## Should not load

- "check my log retention" → `observability`, that owns `OBS-LOG-002` (retention/centralization)
- "review my terraform" → `tf`, CloudTrail/flow-log/EKS-audit IaC is its `SEC-LOG-*`
- "review my helm values" → `k8s`, that owns pod/workload security, not audit logging
- "write a runbook for this alert" → `incident`, the response side
