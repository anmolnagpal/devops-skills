# Runbook: payments-api

**Owner:** payments · **Escalation:** PagerDuty schedule PAY-OC
**Dashboards:** https://grafana.acme.internal/d/payments-api/payments-api

## Rollback

    helm rollback payments --namespace prod

Expected recovery: 2 minutes. Previous release is retained
(`revisionHistoryLimit: 10`).

## Recovery objectives

- **RTO:** 15 minutes · **RPO:** 5 minutes
- **Last tested:** 2026-07-14, full restore drill into staging, 11 minutes end to end
- **Restore procedure:** docs/restore-payments-db.md
