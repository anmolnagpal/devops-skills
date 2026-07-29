# Runbook: report-gen

**Owner:** data-platform · **Escalation:** PagerDuty schedule DATA-OC
**Dashboards:** https://grafana.acme.internal/d/report-gen/report-gen
**Logs:** CloudWatch Logs Insights, log group `/aws/ecs/prod/report-gen`, saved
query `report-gen-errors`
**Deploy:** Argo CD, `report-gen-prod` Application
**Rollback:** `argocd app rollback report-gen-prod` (previous revision)

<!-- incident-skill:ignore ARCH-DR-002 -- stateless batch worker; state lives in
     the source warehouse and S3, both of which have their own recovery objectives
     documented in docs/runbooks/warehouse.md -->

## Mitigate first

If the incident began within 30 minutes of a deploy, roll back:

    argocd app rollback report-gen-prod

Expected recovery: 3 minutes. In-flight batches are retried automatically. If
rolling back does not help, continue below.

## Symptoms → checks → actions

### ReportGenJobFailing

**What the user sees:** scheduled reports do not arrive; the UI shows the last
successful run timestamp going stale.

1. Check whether the warehouse is reachable:
   `aws rds describe-db-clusters --db-cluster-identifier prod-warehouse --query 'DBClusters[0].Status'`
   - Expected: `available`
   - If `failing-over` or `maintenance` → the batch retries on its own; wait 10
     minutes before acting further.
2. Check the dead-letter queue depth:
   `aws sqs get-queue-attributes --queue-url $DLQ_URL --attribute-names ApproximateNumberOfMessages`
   - If above 0 → inspect one message for the failure class, then redrive:
     `aws sqs start-message-move-task --source-arn $DLQ_ARN`
3. Check for a schema change in the source warehouse: compare the last migration
   in `acme/warehouse` against the report-gen query in `internal/reports/sql/`.
   - If a column was renamed or dropped → this needs a code fix, not a retry.
     Page the warehouse on-call via DATA-OC and note the migration in the incident
     channel.
4. Still failing → escalate.

## Dependencies

| Dependency | Failure looks like | What to do |
|---|---|---|
| prod-warehouse (Aurora) | every batch fails at connect | wait through failover; escalate after 15m |
| S3 report bucket | batches succeed, delivery fails | check bucket policy drift, then redeliver |
| SES | reports generated, emails absent | check the SES suppression list |

## Escalation

1. Primary on-call: PagerDuty DATA-OC, ack within 10 minutes.
2. Unacked after 15 minutes: the escalation policy pages the data-platform manager.
3. Customer-visible for more than 60 minutes: notify the account team and update
   the status page.

## Recovery objectives

Stateless worker; see the suppression note at the top of this file.

## What this runbook does not cover

Warehouse outages (see `docs/runbooks/warehouse.md`), report content correctness,
and SES reputation problems.
