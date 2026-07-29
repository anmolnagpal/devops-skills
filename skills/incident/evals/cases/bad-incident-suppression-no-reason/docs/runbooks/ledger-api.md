# Runbook: ledger-api

**Owner:** payments · **Escalation:** PagerDuty schedule PAY-OC
**Dashboards:** https://grafana.acme.internal/d/ledger-api/ledger-api
**Logs:** CloudWatch Logs Insights, log group `/aws/ecs/prod/ledger-api`
**Deploy:** Argo CD, `ledger-api-prod` Application
**Rollback:** `argocd app rollback ledger-api-prod`

<!-- incident-skill:ignore ARCH-DR-002 -->

## Mitigate first

If the incident began within 30 minutes of a deploy, roll back:

    argocd app rollback ledger-api-prod

Expected recovery: 4 minutes.

## Symptoms → checks → actions

### LedgerApiWriteFailures

**What the user sees:** payments accepted at the edge but never settled.

1. Check the writer's connection pool:
   `aws logs start-query --log-group-name /aws/ecs/prod/ledger-api --query-string 'fields @message | filter @message like /pool exhausted/'`
   - If matches → scale the pool via the `LEDGER_POOL_SIZE` task variable and redeploy.
2. Check Aurora writer availability:
   `aws rds describe-db-clusters --db-cluster-identifier prod-ledger --query 'DBClusters[0].Status'`
   - If `failing-over` → writes retry automatically; wait 5 minutes.
3. Still failing → escalate to PAY-OC.

## Recovery objectives

Stated in the platform DR plan.

## What this runbook does not cover

Settlement reconciliation and Aurora capacity planning.
