# Runbook: orders-api

**Owner:** commerce · **Escalation:** PagerDuty schedule COM-OC
**Dashboards:** https://grafana.acme.internal/d/orders-api/orders-api
**Logs:** CloudWatch Logs Insights, log group `/aws/ecs/prod/orders-api`
**Deploy:** Argo CD, `orders-api-prod` Application
**Rollback:** `argocd app rollback orders-api-prod`

## Mitigate first

If the incident began within 30 minutes of a deploy, roll back:

    argocd app rollback orders-api-prod

Expected recovery: 3 minutes.

## Symptoms → checks → actions

### OrdersApiHighErrorRate

**What the user sees:** checkout returns an error after payment is authorised.

1. Check the writer database status:
   `aws rds describe-db-clusters --db-cluster-identifier prod-orders --query 'DBClusters[0].Status'`
   - Expected: `available`
   - If `failing-over` → writes retry; wait 5 minutes.
2. Check for a poison message in the order queue:
   `aws sqs get-queue-attributes --queue-url $ORDERS_DLQ --attribute-names ApproximateNumberOfMessages`
   - If above 0 → inspect one message, then redrive.
3. Still failing → escalate to COM-OC.

## Recovery objectives

- **RTO:** 30 minutes
- **RPO:** 15 minutes
- **Restore procedure:** restore the Aurora cluster from its most recent automated
  snapshot, then replay the order queue from the DLQ.
- **Last tested:** 2026-05-12 (full restore drill into the staging account, 22 minutes
  end to end)

## What this runbook does not cover

Payment provider outages and inventory reconciliation.
